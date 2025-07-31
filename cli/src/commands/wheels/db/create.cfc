/**
 * Create a new database
 *
 * {code:bash}
 * wheels db create
 * wheels db create datasource=myapp_dev
 * {code}
 */
component extends="../base" {

	/**
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @environment Optional environment (defaults to current environment)
	 * @help Create a new database
	 */
	public void function run(
		string datasource = "",
		string environment = "",
		string database = "",
		boolean force = false
	) {
		arguments = reconstructArgs(arguments);
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

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
			
			printHeader("Database Creation Process");
			printInfo("Datasource", arguments.datasource);
			printInfo("Environment", arguments.environment);
			printDivider();
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource);
			
			if (StructIsEmpty(local.dsInfo)) {
				systemOutput("Please create the datasource in your CFML server admin first.", true, true);
				error("Datasource '" & arguments.datasource & "' not found in server configuration");
				return;
			}
			
			// Extract database name and connection info
			local.dbName = arguments.database != '' ? arguments.database : local.dsInfo.database != '' ? local.dsInfo.database : "wheels-dev";
			local.dbType = local.dsInfo.driver;
			
			printInfo("Database Type", local.dbType);
			printInfo("Database Name", local.dbName);
			printDivider();
			
			// Create database based on type
			switch (local.dbType) {
				case "MySQL":
				case "MySQL5":
					createDatabase(local.dsInfo, local.dbName, arguments.force, "MySQL");
					break;
				case "PostgreSQL":
					createDatabase(local.dsInfo, local.dbName, arguments.force, "PostgreSQL");
					break;
				case "MSSQLServer":
				case "MSSQL":
					createDatabase(local.dsInfo, local.dbName, arguments.force, "SQLServer");
					break;
				case "H2":
					printWarning("H2 databases are created automatically on first connection");
					printSuccess("No action needed - database will be created when application starts");
					break;
				default:
					systemOutput("Please create the database manually using your database management tools.", true, true);
					error("Database creation not supported for driver: " & local.dbType);
			}
			
		} catch (any e) {
			printError("Error creating database: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				printError("Details: " & e.detail);
			}
		}
	}

	/**
	 * Unified database creation function
	 */
	private void function createDatabase(required struct dsInfo, required string dbName, boolean force = false, required string dbType) {
		try {
			printStep("Initializing " & arguments.dbType & " database creation...");
			
			// Get database-specific configuration
			local.dbConfig = getDatabaseConfig(arguments.dbType, arguments.dsInfo, arguments.dbName);
			
			// Build connection URL
			local.url = buildJDBCUrl(local.dbConfig.tempDS);
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
				systemOutput("Driver returned null connection. Common causes:");
				systemOutput("1. " & arguments.dbType & " server is not running");
				systemOutput("2. Wrong server/port configuration");
				systemOutput("3. Invalid credentials");
				systemOutput("4. Network/firewall issues");
				if (arguments.dbType == "PostgreSQL") {
					systemOutput("5. pg_hba.conf authentication issues");
				}
				throw(message="Connection failed");
			}
			
			printSuccess("Connected successfully to " & arguments.dbType & " server!");
			
			// Check if database already exists
			printStep("Checking if database exists...");
			local.exists = checkDatabaseExists(local.conn, arguments.dbName, arguments.dbType);
			
			if (local.exists) {
				if (!arguments.force) {
					throw(message="Database '" & arguments.dbName & "' already exists! Use force=true to drop existing database.");
				}
				
				printWarning("Database '" & arguments.dbName & "' already exists!");
				
				// Handle active connections for PostgreSQL
				if (arguments.dbType == "PostgreSQL") {
					printStep("Terminating active connections...");
					terminatePostgreSQLConnections(local.conn, arguments.dbName);
				}
				
				// Drop existing database
				printStep("Dropping existing database...");
				dropDatabase(local.conn, arguments.dbName, arguments.dbType);
				printSuccess("Existing database dropped.");
			}
			
			// Create the database
			printStep("Creating " & arguments.dbType & " database '" & arguments.dbName & "'...");
			executeCreateDatabase(local.conn, arguments.dbName, arguments.dbType);
			printSuccess("Database '" & arguments.dbName & "' created successfully!");
			
			// Verify database was created
			printStep("Verifying database creation...");
			if (verifyDatabaseCreated(local.conn, arguments.dbName, arguments.dbType)) {
				printSuccess("Database '" & arguments.dbName & "' verified successfully!");
			} else {
				printWarning("Database creation verification failed");
			}
			
			// Clean up
			local.conn.close();
			
			printDivider();
			printSuccess(arguments.dbType & " database creation completed successfully!", true);
			
		} catch (any e) {
			handleDatabaseError(e, arguments.dbType, arguments.dbName);
		}
	}

	/**
	 * Drop database
	 */
	private void function dropDatabase(required any conn, required string dbName, required string dbType) {
		local.stmt = arguments.conn.createStatement();
		
		switch (arguments.dbType) {
			case "MySQL":
				local.stmt.executeUpdate("DROP DATABASE `" & arguments.dbName & "`");
				break;
			case "PostgreSQL":
				local.stmt.executeUpdate('DROP DATABASE "' & arguments.dbName & '"');
				break;
			case "SQLServer":
				local.stmt.execute("DROP DATABASE [" & arguments.dbName & "]");
				break;
		}
		
		local.stmt.close();
	}

	/**
	 * Execute database creation
	 */
	private void function executeCreateDatabase(required any conn, required string dbName, required string dbType) {
		local.stmt = arguments.conn.createStatement();
		local.createSQL = "";
		
		switch (arguments.dbType) {
			case "MySQL":
				local.createSQL = "CREATE DATABASE `" & arguments.dbName & "` " &
								"CHARACTER SET utf8mb4 " &
								"COLLATE utf8mb4_unicode_ci";
				local.stmt.executeUpdate(local.createSQL);
				break;
				
			case "PostgreSQL":
				local.createSQL = 'CREATE DATABASE "' & arguments.dbName & '" ' &
								'WITH ENCODING ''UTF8'' ' &
								'LC_COLLATE ''en_US.UTF-8'' ' &
								'LC_CTYPE ''en_US.UTF-8'' ' &
								'TEMPLATE template0';
				local.stmt.executeUpdate(local.createSQL);
				break;
				
			case "SQLServer":
				local.createSQL = "CREATE DATABASE [" & arguments.dbName & "]";
				local.stmt.execute(local.createSQL);
				break;
		}
		
		local.stmt.close();
	}

	/**
	 * Verify database was created
	 */
	private boolean function verifyDatabaseCreated(required any conn, required string dbName, required string dbType) {
		return checkDatabaseExists(arguments.conn, arguments.dbName, arguments.dbType);
	}

	/**
	 * Terminate PostgreSQL connections
	 */
	private void function terminatePostgreSQLConnections(required any conn, required string dbName) {
		local.stmt = arguments.conn.createStatement();
		local.sql = "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '" & arguments.dbName & "' AND pid <> pg_backend_pid()";
		local.stmt.executeQuery(local.sql);
		local.stmt.close();
	}

	/**
	 * Handle database-specific errors
	 */
	private void function handleDatabaseError(required any e, required string dbType, required string dbName) {
		local.errorHandled = false;
		
		switch (arguments.dbType) {
			case "MySQL":
				if (FindNoCase("database exists", arguments.e.message)) {
					printError("Database already exists: " & arguments.dbName);
					local.errorHandled = true;
				} else if (FindNoCase("Access denied", arguments.e.message)) {
					printError("Access denied - check MySQL credentials and permissions");
					local.errorHandled = true;
				} else if (FindNoCase("Communications link failure", arguments.e.message)) {
					printError("Cannot connect to MySQL server - check if MySQL is running and accessible");
					local.errorHandled = true;
				}
				break;
				
			case "PostgreSQL":
				if (FindNoCase("already exists", arguments.e.message)) {
					printError("Database already exists: " & arguments.dbName);
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
				if (FindNoCase("database exists", arguments.e.message)) {
					printError("Database already exists: " & arguments.dbName);
					local.errorHandled = true;
				} else if (FindNoCase("Login failed", arguments.e.message)) {
					printError("Login failed - check SQL Server credentials");
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