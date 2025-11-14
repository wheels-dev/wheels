/**
 * Drop an existing database
 *
 * Supports MySQL, PostgreSQL, SQL Server, Oracle, H2, and SQLite databases.
 * For SQLite and H2, this will delete the database files from disk.
 * For server-based databases, this will drop the database from the server.
 *
 * {code:bash}
 * # Drop database using current environment's datasource
 * wheels db drop
 *
 * # Drop specific datasource
 * wheels db drop --datasource=myapp_dev
 *
 * # Drop with specific environment
 * wheels db drop --datasource=myapp_dev --environment=production
 *
 * # Skip confirmation prompt
 * wheels db drop --force
 * {code}
 */
component extends="../base" {

	/**
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @environment Optional environment (defaults to current environment)
	 * @force Skip confirmation prompt
	 * @help Drop an existing database
	 */
	public void function run(
		string datasource = "",
		string environment = "",
		string database = "",
		boolean force = false
	) {
		local.appPath = getCWD();
		requireWheelsApp(local.appPath);
		arguments = reconstructArgs(arguments);
		

		try {
			// Determine environment
			if (!Len(arguments.environment)) {
				arguments.environment = getEnvironment(local.appPath);
			}
			
			// Get datasource name if not provided
			if (!Len(arguments.datasource)) {
				arguments.datasource = getDataSourceName(local.appPath, arguments.environment);
			}
			
			if (!Len(arguments.datasource)) {
				error("No datasource configured. Use datasource= parameter or set dataSourceName in settings.");
				return;
			}
			
			printHeader("Database Drop Process");
			printWarning("WARNING: This will permanently drop the database!");
			systemOutput("", true, true);
			printInfo("Datasource", arguments.datasource);
			printInfo("Environment", arguments.environment);
			printDivider();
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource, arguments.environment);
			
			if (StructIsEmpty(local.dsInfo)) {
				error("Datasource '" & arguments.datasource & "' not found in server configuration");
				systemOutput("Please check your datasource configuration.", true, true);
				return;
			}
			
			// Extract database name with priority: argument > config > default
			local.dbName = arguments.database != '' ? arguments.database : local.dsInfo.database != '' ? local.dsInfo.database : "wheels_dev";
			local.dbType = local.dsInfo.driver;

			// Validate Oracle identifier (no hyphens or special characters allowed)
			if (local.dbType == "Oracle" && reFind("[^a-zA-Z0-9_$##]", local.dbName)) {
				error("Invalid Oracle identifier: '#local.dbName#' - Oracle usernames can only contain letters, numbers, and underscores. Use underscores instead of hyphens (e.g., 'wheels_dev' instead of 'wheels-dev')");
				return;
			}

			printInfo("Database Type", local.dbType);
			printInfo("Database Name", local.dbName);
			printDivider();
			
			// Confirm unless forced
			if (!arguments.force) {
				local.confirm = ask("Are you sure you want to drop the database '" & local.dbName & "'? Type 'yes' to confirm: ");
				if (local.confirm != "yes") {
					printWarning("Database drop cancelled.");
					return;
				}
			}
			
			// Drop database based on type
			switch (local.dbType) {
				case "MySQL":
				case "MySQL5":
					dropDatabase(local.dsInfo, local.dbName, "MySQL");
					break;
				case "PostgreSQL":
					dropDatabase(local.dsInfo, local.dbName, "PostgreSQL");
					break;
				case "MSSQLServer":
				case "MSSQL":
					dropDatabase(local.dsInfo, local.dbName, "SQLServer");
					break;
				case "Oracle":
					dropDatabase(local.dsInfo, local.dbName, "Oracle");
					break;
				case "H2":
					dropH2Database(local.dsInfo, local.dbName);
					break;
				case "SQLite":
					dropSQLiteDatabase(local.dsInfo, local.dbName);
					break;
				default:
					error("Database drop not supported for driver: " & local.dbType);
					systemOutput("Please drop the database manually using your database management tools.", true, true);
			}
			
		} catch (any e) {
			printError("Error dropping database: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				printError("Details: " & e.detail);
			}
		}
	}

	/**
	 * Unified database drop function
	 */
	private void function dropDatabase(required struct dsInfo, required string dbName, required string dbType) {
		try {
			printStep("Initializing " & arguments.dbType & " database drop...");
			
			// Get database-specific configuration
			local.dbConfig = getDatabaseConfig(arguments.dbType, arguments.dsInfo);
			
			// Build connection URL to system database (not the target database)
			local.url = buildSystemJDBCUrl(local.dbConfig.tempDS);
			local.username = local.dbConfig.tempDS.username ?: "";
			local.password = local.dbConfig.tempDS.password ?: "";
			
			printStep("Connecting to " & arguments.dbType & " server...");
			
			// Create driver instance
			local.driver = "";
			local.driverFound = false;
			
			for (local.driverClass in local.dbConfig.driverClasses) {
				try {
					local.driver = createObject("java", local.driverClass);
					printSuccess("Driver found: " & local.driverClass);
					local.driverFound = true;
					break;
				} catch (any driverError) {
					printWarning("Driver not available: " & local.driverClass);
				}
			}
			
			if (!local.driverFound) {
				throw(message="No " & arguments.dbType & " driver found. Ensure JDBC driver is in classpath.");
			}
			
			// Create properties for connection
			local.props = createObject("java", "java.util.Properties");
			local.props.setProperty("user", local.username);
			local.props.setProperty("password", local.password);
			
			// Test if driver accepts the URL
			if (!local.driver.acceptsURL(local.url)) {
				throw(message=arguments.dbType & " driver does not accept the URL format");
			}
			
			// Connect using driver directly
			local.conn = local.driver.connect(local.url, local.props);
			
			if (isNull(local.conn)) {
				printError("Driver returned null connection. Common causes:");
				printError("1. " & arguments.dbType & " server is not running");
				printError("2. Wrong server/port configuration");
				printError("3. Invalid credentials");
				printError("4. Network/firewall issues");
				if (arguments.dbType == "PostgreSQL") {
					printError("5. pg_hba.conf authentication issues");
				}
				throw(message="Connection failed");
			}
			
			printSuccess("Connected successfully to " & arguments.dbType & " server!");
			
			// Check if database exists before attempting to drop
			printStep("Checking if database exists...");
			local.exists = checkDatabaseExists(local.conn, arguments.dbName, arguments.dbType);
			
			if (!local.exists) {
				printWarning("Database '" & arguments.dbName & "' does not exist.");
				local.conn.close();
				return;
			}
			
			// Handle database-specific pre-drop operations
			if (arguments.dbType == "PostgreSQL") {
				printStep("Terminating active connections...");
				terminatePostgreSQLConnections(local.conn, arguments.dbName);
			} else if (arguments.dbType == "SQLServer") {
				printStep("Setting database to single-user mode...");
				setSQLServerSingleUserMode(local.conn, arguments.dbName);
			}
			
			// Drop the database
			printStep("Dropping " & arguments.dbType & " database '" & arguments.dbName & "'...");
			executeDropDatabase(local.conn, arguments.dbName, arguments.dbType);
			printSuccess("Database '" & arguments.dbName & "' dropped successfully!");
			
			// Clean up
			local.conn.close();
			
			printDivider();
			printSuccess(arguments.dbType & " database drop completed successfully!", true);
			
		} catch (any e) {
			handleDatabaseError(e, arguments.dbType, arguments.dbName);
		}
	}

	/**
	 * Drop H2 database (file-based)
	 */
	private void function dropH2Database(required struct dsInfo, required string dbName) {
		try {
			printStep("Dropping H2 database files...");

			// For H2, we need to delete the database files
			local.dbPath = arguments.dsInfo.database;

			// H2 database files typically have .mv.db extension
			local.dbFile = local.dbPath & ".mv.db";
			local.lockFile = local.dbPath & ".lock.db";
			local.traceFile = local.dbPath & ".trace.db";

			local.filesDeleted = false;

			if (FileExists(local.dbFile)) {
				FileDelete(local.dbFile);
				local.filesDeleted = true;
				printSuccess("Deleted database file: " & local.dbFile);
			}

			if (FileExists(local.lockFile)) {
				FileDelete(local.lockFile);
				printSuccess("Deleted lock file: " & local.lockFile);
			}

			if (FileExists(local.traceFile)) {
				FileDelete(local.traceFile);
				printSuccess("Deleted trace file: " & local.traceFile);
			}

			if (local.filesDeleted) {
				printDivider();
				printSuccess("H2 database dropped successfully!", true);
			} else {
				printWarning("No H2 database files found for: " & arguments.dbName);
			}

		} catch (any e) {
			printError("Error dropping H2 database: " & e.message);
			throw(message=e.message);
		}
	}

	/**
	 * Drop SQLite database (file-based)
	 */
	private void function dropSQLiteDatabase(required struct dsInfo, required string dbName) {
		try {
			// For SQLite, the database path is stored directly in dsInfo.database
			local.dbPath = arguments.dsInfo.database;
			local.filesDeleted = false;

			// SQLite may have additional files like -wal, -shm, -journal
			// Delete these first to release locks
			local.walFile = local.dbPath & "-wal";
			local.shmFile = local.dbPath & "-shm";
			local.journalFile = local.dbPath & "-journal";

			if (FileExists(local.walFile)) {
				try {
					FileDelete(local.walFile);
				} catch (any e) {
					// Ignore auxiliary file deletion errors
				}
			}

			if (FileExists(local.shmFile)) {
				try {
					FileDelete(local.shmFile);
				} catch (any e) {
					// Ignore auxiliary file deletion errors
				}
			}

			if (FileExists(local.journalFile)) {
				try {
					FileDelete(local.journalFile);
				} catch (any e) {
					// Ignore auxiliary file deletion errors
				}
			}

			// Try to delete the main database file
			if (FileExists(local.dbPath)) {
				try {
					FileDelete(local.dbPath);
					local.filesDeleted = true;
				} catch (any deleteError) {
					// File is locked - check if server is running and try to stop it
					local.serverWasRunning = false;
					try {
						local.serverStatus = command("server status")
							.inWorkingDirectory(getCWD())
							.run(returnOutput=true);

						if (findNoCase("running", local.serverStatus)) {
							local.serverWasRunning = true;
							printWarning("Server is running - stopping it to release database lock...");

							// Stop the server
							try {
								command("server stop")
									.inWorkingDirectory(getCWD())
									.run();

								// Wait and retry for file handles to be released
								local.maxRetries = 5;
								local.retryDelay = 1000; // 1 second
								local.deleted = false;

								for (local.retry = 1; local.retry <= local.maxRetries; local.retry++) {
									sleep(local.retryDelay);

									try {
										FileDelete(local.dbPath);
										local.filesDeleted = true;
										local.deleted = true;
										break;
									} catch (any retryError) {
										// Continue retrying
									}
								}

								if (local.deleted) {
									printSuccess("SQLite database dropped successfully!");
									return;
								} else {
									throw(message="File still locked after stopping server. Wait a moment and try again.", detail=deleteError.message);
								}
							} catch (any stopError) {
								throw(message="Failed to stop server: " & stopError.message, detail=deleteError.message);
							}
						}
					} catch (any e) {
						// Server status check failed
					}

					// If we get here, we couldn't delete the file
					local.errorMsg = "Database file is locked";
					if (local.serverWasRunning) {
						local.errorMsg &= " - server was stopped but file is still locked";
					} else {
						local.errorMsg &= " - stop the application server or close any database tools";
					}
					throw(message=local.errorMsg, detail=deleteError.message);
				}
			}

			if (local.filesDeleted) {
				printSuccess("SQLite database dropped successfully!");
			} else {
				printWarning("No SQLite database files found");
			}

		} catch (any e) {
			throw(message=e.message);
		}
	}

	/**
	 * Check if database exists
	 */
	private boolean function checkDatabaseExists(required any conn, required string dbName, required string dbType) {
		local.exists = false;

		switch (arguments.dbType) {
			case "MySQL":
				local.stmt = arguments.conn.createStatement();
				local.query = "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '" & arguments.dbName & "'";
				local.rs = local.stmt.executeQuery(local.query);
				local.exists = local.rs.next();
				local.rs.close();
				local.stmt.close();
				break;

			case "PostgreSQL":
				local.stmt = arguments.conn.prepareStatement("SELECT 1 FROM pg_database WHERE datname = ?");
				local.stmt.setString(1, arguments.dbName);
				local.rs = local.stmt.executeQuery();
				local.exists = local.rs.next();
				local.rs.close();
				local.stmt.close();
				break;

			case "SQLServer":
				local.stmt = arguments.conn.createStatement();
				local.query = "SELECT name FROM sys.databases WHERE name = '" & arguments.dbName & "'";
				local.rs = local.stmt.executeQuery(local.query);
				local.exists = local.rs.next();
				local.rs.close();
				local.stmt.close();
				break;

			case "Oracle":
				// Oracle checks for USER existence (schema)
				local.stmt = arguments.conn.createStatement();
				local.query = "SELECT username FROM dba_users WHERE username = UPPER('" & arguments.dbName & "')";
				local.rs = local.stmt.executeQuery(local.query);
				local.exists = local.rs.next();
				local.rs.close();
				local.stmt.close();
				break;
		}

		return local.exists;
	}

	/**
	 * Execute database drop
	 */
	private void function executeDropDatabase(required any conn, required string dbName, required string dbType) {
		local.stmt = arguments.conn.createStatement();

		switch (arguments.dbType) {
			case "MySQL":
				local.stmt.executeUpdate("DROP DATABASE IF EXISTS `" & arguments.dbName & "`");
				break;
			case "PostgreSQL":
				local.stmt.executeUpdate('DROP DATABASE IF EXISTS "' & arguments.dbName & '"');
				break;
			case "SQLServer":
				local.stmt.executeUpdate("DROP DATABASE IF EXISTS [" & arguments.dbName & "]");
				break;
			case "Oracle":
				// Oracle uses DROP USER CASCADE to remove user/schema and all objects
				// Oracle 12c+ CDB requires _ORACLE_SCRIPT for non-C## users
				try {
					local.alterSession = "ALTER SESSION SET ""_ORACLE_SCRIPT""=true";
					local.stmt.execute(local.alterSession);
				} catch (any e) {
					// Ignore if this fails
				}

				// Drop user with CASCADE to remove all objects
				local.dropSQL = "DROP USER " & UCASE(arguments.dbName) & " CASCADE";
				systemOutput("DEBUG - Executing DROP SQL: " & local.dropSQL, true);
				local.stmt.execute(local.dropSQL);
				break;
		}

		local.stmt.close();
	}

	/**
	 * Terminate PostgreSQL connections
	 */
	private void function terminatePostgreSQLConnections(required any conn, required string dbName) {
		local.stmt = arguments.conn.prepareStatement(
			"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = ? AND pid <> pg_backend_pid()"
		);
		local.stmt.setString(1, arguments.dbName);
		local.stmt.executeQuery();
		local.stmt.close();
	}

	/**
	 * Set SQL Server database to single-user mode
	 */
	private void function setSQLServerSingleUserMode(required any conn, required string dbName) {
		local.stmt = arguments.conn.createStatement();
		local.stmt.executeUpdate(
			"IF EXISTS (SELECT 1 FROM sys.databases WHERE name = '" & arguments.dbName & "') " &
			"ALTER DATABASE [" & arguments.dbName & "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
		);
		local.stmt.close();
	}

	/**
	 * Handle database-specific errors
	 */
	private void function handleDatabaseError(required any e, required string dbType, required string dbName) {
		local.errorHandled = false;

		switch (arguments.dbType) {
			case "MySQL":
				if (FindNoCase("Access denied", arguments.e.message)) {
					printError("Access denied - check MySQL credentials and DROP privileges");
					local.errorHandled = true;
				} else if (FindNoCase("Communications link failure", arguments.e.message)) {
					printError("Cannot connect to MySQL server - check if MySQL is running and accessible");
					local.errorHandled = true;
				}
				break;

			case "PostgreSQL":
				if (FindNoCase("does not exist", arguments.e.message)) {
					printError("Database does not exist: " & arguments.dbName);
					local.errorHandled = true;
				} else if (FindNoCase("authentication failed", arguments.e.message)) {
					printError("Authentication failed - check PostgreSQL credentials");
					local.errorHandled = true;
				} else if (FindNoCase("Connection refused", arguments.e.message)) {
					printError("Connection refused - check if PostgreSQL is running and accessible");
					local.errorHandled = true;
				} else if (FindNoCase("database is being accessed by other users", arguments.e.message)) {
					printError("Cannot drop database - other users are connected");
					local.errorHandled = true;
				}
				break;

			case "SQLServer":
				if (FindNoCase("Login failed", arguments.e.message)) {
					printError("Login failed - check SQL Server credentials");
					local.errorHandled = true;
				}
				break;

			case "Oracle":
				if (FindNoCase("ORA-01918", arguments.e.message) || FindNoCase("user does not exist", arguments.e.message)) {
					printError("User (schema) does not exist: " & arguments.dbName);
					local.errorHandled = true;
				} else if (FindNoCase("ORA-28014", arguments.e.message) || FindNoCase("cannot drop administrative user", arguments.e.message)) {
					printError("Cannot drop administrative/system user: " & arguments.dbName);
					printWarning("Oracle system users like SYS, SYSTEM, ADMIN, XDB cannot be dropped");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-01017", arguments.e.message) || FindNoCase("invalid username/password", arguments.e.message)) {
					printError("Invalid username/password - check Oracle credentials");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-12505", arguments.e.message) || FindNoCase("TNS:listener", arguments.e.message)) {
					printError("Cannot connect to Oracle server - check SID and connection settings");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-01031", arguments.e.message) || FindNoCase("insufficient privileges", arguments.e.message)) {
					printError("Insufficient privileges - user must have DROP USER privilege");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-65096", arguments.e.message) || FindNoCase("common user or role name", arguments.e.message)) {
					printError("Oracle CDB requires C## prefix or _ORACLE_SCRIPT session variable");
					printWarning("This may indicate insufficient privileges");
					local.errorHandled = true;
				}
				break;
		}

		if (!local.errorHandled) {
			printError(arguments.dbType & " Error: " & arguments.e.message);
			if (isDefined("arguments.e.detail")) {
				printError("Detail: " & arguments.e.detail);
			}
			throw(message=arguments.e.message, detail=(isDefined("arguments.e.detail") ? arguments.e.detail : ""));
		}
	}

}