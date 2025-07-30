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
		string database = "wheels-dev",
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
				error("Datasource '" & arguments.datasource & "' not found in server configuration");
				systemOutput("Please create the datasource in your CFML server admin first.", true, true);
				return;
			}
			
			// Extract database name and connection info
			local.dbName = local.dsInfo.database != '' ? local.dsInfo.database : arguments.database;
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
					error("Database creation not supported for driver: " & local.dbType);
					systemOutput("Please create the database manually using your database management tools.", true, true);
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
	 * Get database-specific configuration
	 */
	private struct function getDatabaseConfig(required string dbType, required struct dsInfo, required string dbName) {
		local.config = {
			tempDS: Duplicate(arguments.dsInfo),
			driverClasses: []
		};
		
		switch (arguments.dbType) {
			case "MySQL":
				local.config.tempDS.database = ""; // Connect without database
				local.config.driverClasses = [
					"com.mysql.cj.jdbc.Driver",      // MySQL 8.0+
					"com.mysql.jdbc.Driver",         // MySQL 5.x
					"org.mariadb.jdbc.Driver"        // MariaDB
				];
				break;
				
			case "PostgreSQL":
				local.config.tempDS.database = "postgres"; // Connect to system database
				local.config.driverClasses = [
					"org.postgresql.Driver",         // Standard PostgreSQL driver
					"postgresql.Driver"              // Alternative name
				];
				break;
				
			case "SQLServer":
				local.config.tempDS.database = "master"; // Connect to system database
				local.config.driverClasses = [
					"com.microsoft.sqlserver.jdbc.SQLServerDriver"
				];
				break;
		}
		
		return local.config;
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
		}
		
		return local.exists;
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

	/**
	 * Print formatted output helpers
	 */
	private void function printHeader(required string text) {
		systemOutput("", true, true);
		systemOutput("==================================================================", true, true);
		systemOutput("  " & arguments.text, true, true);
		systemOutput("==================================================================", true, true);
		systemOutput("", true, true);
	}

	private void function printDivider() {
		systemOutput("------------------------------------------------------------------", true, true);
	}

	private void function printInfo(required string label, required string value) {
		systemOutput("  " & PadRight(arguments.label & ":", 20) & arguments.value, true, true);
	}

	private void function printStep(required string message) {
		systemOutput("", true, true);
		systemOutput(">> " & arguments.message, true, true);
	}

	private void function printSuccess(required string message, boolean bold = false) {
		if (arguments.bold) {
			print.boldGreenLine(arguments.message);
		} else {
			print.greenLine("  [OK] " & arguments.message);
		}
		systemOutput("", true, false); // Force flush
	}

	private void function printWarning(required string message) {
		print.yellowLine("  [WARN] " & arguments.message);
		systemOutput("", true, false); // Force flush
	}

	private void function printError(required string message) {
		print.redLine("  [ERROR] " & arguments.message);
		systemOutput("", true, false); // Force flush
	}

	private string function PadRight(required string text, required numeric length) {
		if (Len(arguments.text) >= arguments.length) {
			return Left(arguments.text, arguments.length);
		}
		return arguments.text & RepeatString(" ", arguments.length - Len(arguments.text));
	}

	// Keep existing helper functions unchanged
	private struct function getDatasourceInfo(required string datasourceName) {
		try {
			// Try to get datasource info from application.cfc
			local.appPath = getCWD();
			local.appCfcPath = local.appPath & "/config/app.cfm";
			
			if (fileExists(local.appCfcPath)) {
				local.content = fileRead(local.appCfcPath);
				
				// Look for datasource definition in this.datasources['name']
				local.pattern = "this\.datasources\[['""]#arguments.datasourceName#['""]]\s*=\s*\{([^}]+)\}";
				local.match = reFindNoCase(local.pattern, local.content, 1, true);
				
				if (local.match.pos[1] > 0) {
					local.dsDefinition = mid(local.content, local.match.pos[1], local.match.len[1]);
					local.dsInfo = {
						"datasource": arguments.datasourceName,
						"database": "",
						"driver": "",
						"host": "localhost",
						"port": "",
						"username": "",
						"password": ""
					};
					
					// Extract driver class - handle both single and double quotes
					local.classMatch = reFindNoCase("class\s*:\s*['""]([^'""]+)['""]", local.dsDefinition, 1, true);
					if (local.classMatch.pos[2] > 0) {
						local.className = mid(local.dsDefinition, local.classMatch.pos[2], local.classMatch.len[2]);
						switch(local.className) {
							case "org.h2.Driver":
								local.dsInfo.driver = "H2";
								break;
							case "com.mysql.cj.jdbc.Driver":
							case "com.mysql.jdbc.Driver":
								local.dsInfo.driver = "MySQL";
								break;
							case "org.postgresql.Driver":
								local.dsInfo.driver = "PostgreSQL";
								break;
							case "com.microsoft.sqlserver.jdbc.SQLServerDriver":
								local.dsInfo.driver = "MSSQL";
								break;
						}
					}
					
					// Extract connection string - handle both single and double quotes
					local.connMatch = reFindNoCase("connectionString\s*:\s*['""]([^'""]+)['""]", local.dsDefinition, 1, true);
					if (local.connMatch.pos[2] > 0) {
						local.connString = mid(local.dsDefinition, local.connMatch.pos[2], local.connMatch.len[2]);
						
						// Parse H2 database path
						if (local.dsInfo.driver == "H2") {
							if (find("jdbc:h2:file:", local.connString)) {
								local.dbPath = replaceNoCase(local.connString, "jdbc:h2:file:", "");
								local.dbPath = listFirst(local.dbPath, ";");
								local.dsInfo.database = local.dbPath;
							}
						}
						
						// Parse database name from connection string for other drivers
						if (local.dsInfo.driver == "MySQL") {
							// jdbc:mysql://host:port/database
							local.dbMatch = reFindNoCase("jdbc:mysql://[^/]+/([^?;]+)", local.connString, 1, true);
							if (local.dbMatch.pos[2] > 0) {
								local.dsInfo.database = mid(local.connString, local.dbMatch.pos[2], local.dbMatch.len[2]);
							}
						} else if (local.dsInfo.driver == "PostgreSQL") {
							// jdbc:postgresql://host:port/database
							local.dbMatch = reFindNoCase("jdbc:postgresql://[^/]+/([^?;]+)", local.connString, 1, true);
							if (local.dbMatch.pos[2] > 0) {
								local.dsInfo.database = mid(local.connString, local.dbMatch.pos[2], local.dbMatch.len[2]);
							}
						} else if (local.dsInfo.driver == "MSSQL") {
							// jdbc:sqlserver://host:port;databaseName=database
							local.dbMatch = reFindNoCase("databaseName=([^;]+)", local.connString, 1, true);
							if (local.dbMatch.pos[2] > 0) {
								local.dsInfo.database = mid(local.connString, local.dbMatch.pos[2], local.dbMatch.len[2]);
							}
						}
						
						// Extract host and port from connection string
						local.hostPortMatch = reFindNoCase("jdbc:[^:]+://([^:/]+)(?::(\d+))?", local.connString, 1, true);
						if (local.hostPortMatch.pos[2] > 0) {
							local.dsInfo.host = mid(local.connString, local.hostPortMatch.pos[2], local.hostPortMatch.len[2]);
							if (local.hostPortMatch.pos[3] > 0) {
								local.dsInfo.port = mid(local.connString, local.hostPortMatch.pos[3], local.hostPortMatch.len[3]);
							}
						}
					}
					
					// Extract username - handle both single and double quotes
					local.userMatch = reFindNoCase("username\s*[:=]\s*['""]([^'""]*)['""]", local.dsDefinition, 1, true);
					if (local.userMatch.pos[2] > 0) {
						local.dsInfo.username = mid(local.dsDefinition, local.userMatch.pos[2], local.userMatch.len[2]);
					}
					// Extract password - handle both single and double quotes
					local.passwordMatch = reFindNoCase("password\s*[:=]\s*['""]([^'""]*)['""]", local.dsDefinition, 1, true);
					if (local.passwordMatch.pos[2] > 0) {
						local.dsInfo.password = mid(local.dsDefinition, local.passwordMatch.pos[2], local.passwordMatch.len[2]);
					}
					
					return local.dsInfo;
				}
			}
			
			// If not found in app.cfm, return empty struct
			return {};
		} catch (any e) {
			// Server might not be running or file read error
			return {};
		}
	}

	private string function buildJDBCUrl(required struct dsInfo) {
		local.driver = arguments.dsInfo.driver;
		local.host = arguments.dsInfo.host ?: "localhost";
		local.port = arguments.dsInfo.port ?: "";
		local.database = arguments.dsInfo.database ?: "";
		
		switch (local.driver) {
			case "MySQL":
			case "MySQL5":
				if (!Len(local.port)) local.port = "3306";
				return "jdbc:mysql://#local.host#:#local.port#/#local.database#";
			case "PostgreSQL":
				if (!Len(local.port)) local.port = "5432";
				return "jdbc:postgresql://#local.host#:#local.port#/#local.database#";
			case "MSSQLServer":
			case "MSSQL":
				if (!Len(local.port)) local.port = "1433";
				local.database = "master";
				return "jdbc:sqlserver://#local.host#:#local.port#;databaseName=#local.database#;encrypt=false;trustServerCertificate=true";
			case "H2":
				return "jdbc:h2:#local.database#";
			default:
				return "";
		}
	}

	private string function getEnvironment(required string appPath) {
		// Same logic as get environment command
		local.environment = "";
		
		// Check .env file
		local.envFile = arguments.appPath & "/.env";
		if (FileExists(local.envFile)) {
			local.envContent = FileRead(local.envFile);
			local.envMatch = REFind("(?m)^WHEELS_ENV\s*=\s*(.+)$", local.envContent, 1, true);
			if (local.envMatch.pos[1] > 0) {
				local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
			}
		}
		
		// Check environment variable
		if (!Len(local.environment)) {
			local.sysEnv = CreateObject("java", "java.lang.System");
			local.wheelsEnv = local.sysEnv.getenv("WHEELS_ENV");
			if (!IsNull(local.wheelsEnv) && Len(local.wheelsEnv)) {
				local.environment = local.wheelsEnv;
			}
		}
		
		// Default to development
		if (!Len(local.environment)) {
			local.environment = "development";
		}
		
		return local.environment;
	}

	private string function getDataSourceName(required string appPath, required string environment) {
		// Check environment-specific settings first
		local.envSettingsFile = arguments.appPath & "/config/" & arguments.environment & "/settings.cfm";
		if (FileExists(local.envSettingsFile)) {
			local.dsName = extractDataSourceName(FileRead(local.envSettingsFile));
			if (Len(local.dsName)) return local.dsName;
		}
		
		// Check general settings
		local.settingsFile = arguments.appPath & "/config/settings.cfm";
		if (FileExists(local.settingsFile)) {
			local.dsName = extractDataSourceName(FileRead(local.settingsFile));
			if (Len(local.dsName)) return local.dsName;
		}
		
		return "";
	}

	private string function extractDataSourceName(required string content) {
		// Step 1: Remove multi-line block comments: /* ... */
		local.cleaned = REReplace(arguments.content, "/\*[\s\S]*?\*/", "", "all");

		// Step 2: Remove single-line comments: // ... until end of line
		local.cleaned = REReplace(local.cleaned, "//.*", "", "all");

		// Step 3: Match set(dataSourceName="...")
		local.pattern = "set\s*\(\s*dataSourceName\s*=\s*[""']([^""']+)[""']";
		local.match = REFind(local.pattern, local.cleaned, 1, true);

		if (arrayLen(local.match.pos) >= 2 && local.match.pos[2] > 0) {
			return Mid(local.cleaned, local.match.pos[2], local.match.len[2]);
		}
		return "";
	}

}