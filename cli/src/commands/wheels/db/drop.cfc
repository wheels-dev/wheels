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

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

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
				detailOutput.error("No datasource configured. Use datasource= parameter or set dataSourceName in settings.");
				detailOutput.nextSteps([
					"Specify a datasource: wheels db drop --datasource=myapp_dev",
					"Or configure dataSourceName in your settings.cfm file"
				]);
				return;
			}
			
			detailOutput.header("Database Drop Process", 50);
			detailOutput.statusWarning("This will permanently drop the database!");
			systemOutput("", true, true);
			detailOutput.metric("Datasource", arguments.datasource);
			detailOutput.metric("Environment", arguments.environment);
			detailOutput.divider();
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource, arguments.environment);
			
			if (StructIsEmpty(local.dsInfo)) {
				detailOutput.statusFailed("Datasource '#arguments.datasource#' not found in server configuration");
				print.line("Please check your datasource configuration.").toConsole();
				return;
			}
			
			// Extract database name with priority: argument > config > default
			local.dbName = arguments.database != '' ? arguments.database : local.dsInfo.database != '' ? local.dsInfo.database : "wheels_dev";
			local.dbType = local.dsInfo.driver;

			// Validate Oracle identifier (no hyphens or special characters allowed)
			if (local.dbType == "Oracle" && reFind("[^a-zA-Z0-9_$##]", local.dbName)) {
				detailOutput.statusFailed("Invalid Oracle identifier: '#local.dbName#'");
				detailOutput.statusWarning("Oracle usernames can only contain letters, numbers, and underscores.");
				detailOutput.nextSteps([
					"Use underscores instead of hyphens",
					"Example: 'wheels_dev' instead of 'wheels-dev'"
				]);
				return;
			}

			detailOutput.metric("Database Type", local.dbType);
			detailOutput.metric("Database Name", local.dbName);
			detailOutput.divider();
			
			// Confirm unless forced
			if (!arguments.force) {
				local.confirm = ask("Are you sure you want to drop the database '#local.dbName#'? Type 'yes' to confirm: ");
				if (local.confirm != "yes") {
					detailOutput.statusWarning("Database drop cancelled.");
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
					detailOutput.statusFailed("Database drop not supported for driver: #local.dbType#");
					print.line("Please drop the database manually using your database management tools.").toConsole();
			}
			
		} catch (any e) {
			detailOutput.statusFailed("Error dropping database: #e.message#");
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				detailOutput.output("Details: #e.detail#", true);
			}
		}
	}

	/**
	 * Unified database drop function
	 */
	private void function dropDatabase(required struct dsInfo, required string dbName, required string dbType) {
		try {
			print.line("Initializing #arguments.dbType# database drop...").toConsole();
			
			// Get database-specific configuration
			local.dbConfig = getDatabaseConfig(arguments.dbType, arguments.dsInfo);
			
			// Build connection URL to system database (not the target database)
			local.url = buildSystemJDBCUrl(local.dbConfig.tempDS);
			local.username = local.dbConfig.tempDS.username ?: "";
			local.password = local.dbConfig.tempDS.password ?: "";
			
			print.line("Connecting to #arguments.dbType# server...").toConsole();
			
			// Create driver instance
			local.driver = "";
			local.driverFound = false;
			
			for (local.driverClass in local.dbConfig.driverClasses) {
				try {
					local.driver = createObject("java", local.driverClass);
					detailOutput.statusSuccess("Driver found: #local.driverClass#");
					local.driverFound = true;
					break;
				} catch (any driverError) {
					detailOutput.statusWarning("Driver not available: #local.driverClass#");
				}
			}
			
			if (!local.driverFound) {
				detailOutput.error("No #arguments.dbType# driver found. Ensure JDBC driver is in classpath.");
				return;
			}
			
			// Create properties for connection
			local.props = createObject("java", "java.util.Properties");
			local.props.setProperty("user", local.username);
			local.props.setProperty("password", local.password);
			
			// Test if driver accepts the URL
			if (!local.driver.acceptsURL(local.url)) {
				detailOutput.error("#arguments.dbType# driver does not accept the URL format");
				return;
			}
			
			// Connect using driver directly
			local.conn = local.driver.connect(local.url, local.props);
			
			if (isNull(local.conn)) {
				detailOutput.statusFailed("Connection failed");
				detailOutput.nextSteps([
					"1. #arguments.dbType# server is not running",
					"2. Wrong server/port configuration",
					"3. Invalid credentials",
					"4. Network/firewall issues"
				]);
				if (arguments.dbType == "PostgreSQL") {
					detailOutput.statusWarning("Check pg_hba.conf authentication settings");
				}
				detailOutput.error("Connection failed");
				return;
			}
			
			detailOutput.statusSuccess("Connected successfully to #arguments.dbType# server!");
			
			// Check if database exists before attempting to drop
			print.line("Checking if database exists...").toConsole();
			local.exists = checkDatabaseExists(local.conn, arguments.dbName, arguments.dbType);
			
			if (!local.exists) {
				detailOutput.statusWarning("Database '#arguments.dbName#' does not exist.");
				local.conn.close();
				return;
			}
			
			// Handle database-specific pre-drop operations
			if (arguments.dbType == "PostgreSQL") {
				print.line("Terminating active connections...").toConsole();
				terminatePostgreSQLConnections(local.conn, arguments.dbName);
			} else if (arguments.dbType == "SQLServer") {
				print.line("Setting database to single-user mode...").toConsole();
				setSQLServerSingleUserMode(local.conn, arguments.dbName);
			}
			
			// Drop the database
			print.line("Dropping #arguments.dbType# database '#arguments.dbName#'...").toConsole();
			executeDropDatabase(local.conn, arguments.dbName, arguments.dbType);
			detailOutput.statusSuccess("Database '#arguments.dbName#' dropped successfully!");
			
			// Clean up
			local.conn.close();
			
			detailOutput.divider();
			detailOutput.success("#arguments.dbType# database drop completed successfully!");
			
		} catch (any e) {
			handleDatabaseError(e, arguments.dbType, arguments.dbName);
		}
	}

	/**
	 * Drop H2 database (file-based)
	 */
	private void function dropH2Database(required struct dsInfo, required string dbName) {
		try {
			print.line("Dropping H2 database files...").toConsole();

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
				detailOutput.statusSuccess("Deleted database file: #local.dbFile#");
			}

			if (FileExists(local.lockFile)) {
				FileDelete(local.lockFile);
				detailOutput.statusSuccess("Deleted lock file: #local.lockFile#");
			}

			if (FileExists(local.traceFile)) {
				FileDelete(local.traceFile);
				detailOutput.statusSuccess("Deleted trace file: #local.traceFile#");
			}

			if (local.filesDeleted) {
				detailOutput.divider();
				detailOutput.success("H2 database dropped successfully!");
			} else {
				detailOutput.statusWarning("No H2 database files found for: #arguments.dbName#");
			}

		} catch (any e) {
			detailOutput.statusFailed("Error dropping H2 database: #e.message#");
			detailOutput.error(e.message);
			return;
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
							detailOutput.statusWarning("Server is running - stopping it to release database lock...");

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
									detailOutput.statusSuccess("SQLite database dropped successfully!");
									return;
								} else {
									detailOutput.error("File still locked after stopping server. Wait a moment and try again. " & deleteError.message);
									return;
								}
							} catch (any stopError) {
								detailOutput.error("Failed to stop server: " & stopError.message);
								return;
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
					detailOutput.error(local.errorMsg & " - " & deleteError.message);
					return;
				}
			}

			if (local.filesDeleted) {
				detailOutput.statusSuccess("SQLite database dropped successfully!");
			} else {
				detailOutput.statusWarning("No SQLite database files found");
			}

		} catch (any e) {
			detailOutput.error(e.message);
			return;
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
			"IF EXISTS (SELECT 1 FROM sys.databases WHERE name = '#arguments.dbName#') " &
			"ALTER DATABASE [#arguments.dbName#] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
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
					detailOutput.statusFailed("Access denied - check MySQL credentials and DROP privileges");
					local.errorHandled = true;
				} else if (FindNoCase("Communications link failure", arguments.e.message)) {
					detailOutput.statusFailed("Cannot connect to MySQL server - check if MySQL is running and accessible");
					local.errorHandled = true;
				}
				break;

			case "PostgreSQL":
				if (FindNoCase("does not exist", arguments.e.message)) {
					detailOutput.statusFailed("Database does not exist: #arguments.dbName#");
					local.errorHandled = true;
				} else if (FindNoCase("authentication failed", arguments.e.message)) {
					detailOutput.statusFailed("Authentication failed - check PostgreSQL credentials");
					local.errorHandled = true;
				} else if (FindNoCase("Connection refused", arguments.e.message)) {
					detailOutput.statusFailed("Connection refused - check if PostgreSQL is running and accessible");
					local.errorHandled = true;
				} else if (FindNoCase("database is being accessed by other users", arguments.e.message)) {
					detailOutput.statusFailed("Cannot drop database - other users are connected");
					local.errorHandled = true;
				}
				break;

			case "SQLServer":
				if (FindNoCase("Login failed", arguments.e.message)) {
					detailOutput.statusFailed("Login failed - check SQL Server credentials");
					local.errorHandled = true;
				}
				break;

			case "Oracle":
				if (FindNoCase("ORA-01918", arguments.e.message) || FindNoCase("user does not exist", arguments.e.message)) {
					detailOutput.statusFailed("User (schema) does not exist: #arguments.dbName#");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-28014", arguments.e.message) || FindNoCase("cannot drop administrative user", arguments.e.message)) {
					detailOutput.statusFailed("Cannot drop administrative/system user: #arguments.dbName#");
					detailOutput.statusWarning("Oracle system users like SYS, SYSTEM, ADMIN, XDB cannot be dropped");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-01017", arguments.e.message) || FindNoCase("invalid username/password", arguments.e.message)) {
					detailOutput.statusFailed("Invalid username/password - check Oracle credentials");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-12505", arguments.e.message) || FindNoCase("TNS:listener", arguments.e.message)) {
					detailOutput.statusFailed("Cannot connect to Oracle server - check SID and connection settings");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-01031", arguments.e.message) || FindNoCase("insufficient privileges", arguments.e.message)) {
					detailOutput.statusFailed("Insufficient privileges - user must have DROP USER privilege");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-65096", arguments.e.message) || FindNoCase("common user or role name", arguments.e.message)) {
					detailOutput.statusFailed("Oracle CDB requires C## prefix or _ORACLE_SCRIPT session variable");
					detailOutput.statusWarning("This may indicate insufficient privileges");
					local.errorHandled = true;
				}
				break;
		}

		if (!local.errorHandled) {
			detailOutput.statusFailed("#arguments.dbType# Error: #arguments.e.message#");
			if (isDefined("arguments.e.detail")) {
				detailOutput.output("Detail: #arguments.e.detail#", true);
			}
			detailOutput.error(arguments.e.message);
			return;
		}
	}
}