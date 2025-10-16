/**
 * Create a new database
 *
 * {code:bash}
 * wheels db create
 * wheels db create datasource=myapp_dev
 * {code}
 */
component extends="../base" {

	property name="environmentService" inject="EnvironmentService@wheels-cli";

	/**
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @environment Optional environment (defaults to current environment)
	 * @dbtype Optional database type (h2, mysql, postgres, mssql, oracle)
	 * @help Create a new database
	 */
	public void function run(
		string datasource = "",
		string environment = "",
		string database = "",
		string dbtype = "",
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

			// Normalize dbtype parameter
			if (Len(arguments.dbtype)) {
				arguments.dbtype = normalizeDbType(arguments.dbtype);
			}

			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource);

			if (StructIsEmpty(local.dsInfo)) {
				print.line();
				print.yellowLine("Datasource '" & arguments.datasource & "' not found in server configuration.");
				print.line();

				// Ask if user wants to create datasource
				if (ask("Would you like to create this datasource now? [y/n]: ") == "y") {
					local.dsInfo = createInteractiveDatasource(
						datasourceName = arguments.datasource,
						appPath = local.appPath,
						environment = arguments.environment,
						dbtype = arguments.dbtype
					);
					if (StructIsEmpty(local.dsInfo)) {
						error("Datasource creation cancelled or failed");
						return;
					}
				} else {
					systemOutput("Please create the datasource in your CFML server admin first.", true, true);
					error("Datasource '" & arguments.datasource & "' not found in server configuration");
					return;
				}
			} else {
				// Datasource found - check if dbtype parameter matches datasource type
				// Normalize both for comparison to avoid false mismatches (MSSQL vs MSSQLServer)
				if (Len(arguments.dbtype) && normalizeDbType(arguments.dbtype) != normalizeDbType(local.dsInfo.driver)) {
					print.line();
					print.yellowLine("WARNING: dbtype parameter ('#arguments.dbtype#') does not match datasource type ('#local.dsInfo.driver#')");
					print.yellowLine("Using datasource type: #local.dsInfo.driver#");
					print.line();
				}
			}

			// Extract database name and connection info
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
				case "Oracle":
					createDatabase(local.dsInfo, local.dbName, arguments.force, "Oracle");
					break;
				case "H2":
					printWarning("H2 databases are created automatically on first connection");
					printSuccess("No action needed - database will be created when application starts");
					break;
				default:
					systemOutput("Please create the database manually using your database management tools.", true, true);
					error("Database creation not supported for driver: " & local.dbType);
			}

			// After database creation, ensure environment setup exists
			ensureEnvironmentSetup(local.appPath, arguments.environment, arguments.datasource, local.dbType, local.dsInfo);

			// Now write datasource to app.cfm using environment variables
			// This is done AFTER database creation so the actual values from dsInfo were used for DB creation
			writeDatasourceToAppCfmWithEnvVars(local.appPath, arguments.datasource, local.dbType, arguments.environment);

		} catch (any e) {
			// Errors are already handled and displayed by handleDatabaseError() function
			// Just set exit code to indicate failure
			setExitCode(1);
		}
	}

	/**
	 * Unified database creation function
	 */
	private void function createDatabase(required struct dsInfo, required string dbName, boolean force = false, required string dbType) {
		try {
			printStep("Initializing " & arguments.dbType & " database creation...");
			
			// Get database-specific configuration (don't pass target dbName, use system DB)
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
			case "Oracle":
				// Oracle uses DROP USER CASCADE to remove tablespace and objects
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

			case "Oracle":
				// Oracle 12c+ CDB requires either C## prefix or _ORACLE_SCRIPT session variable
				// Enable creation of non-C## users in CDB (for development)
				try {
					local.alterSession = "ALTER SESSION SET ""_ORACLE_SCRIPT""=true";
					local.stmt.execute(local.alterSession);
				} catch (any e) {
					// Ignore if this fails (non-CDB Oracle or insufficient privileges)
					systemOutput("Note: Could not set _ORACLE_SCRIPT (may not be needed)", true);
				}

				// Create Oracle user (schema)
				local.createSQL = "CREATE USER #arguments.dbName# IDENTIFIED BY #arguments.dbName#_pass";
				systemOutput("DEBUG - Executing SQL: " & local.createSQL, true);
				local.stmt.execute(local.createSQL);

				// Grant privileges
				local.grantSQL = "GRANT CONNECT, RESOURCE TO #arguments.dbName#";
				local.stmt.execute(local.grantSQL);
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

			case "Oracle":
				if (FindNoCase("ORA-01920", arguments.e.message) || FindNoCase("user name conflicts", arguments.e.message)) {
					printError("User (schema) already exists: " & arguments.dbName);
					printWarning("Use force=true to drop and recreate the user");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-28014", arguments.e.message) || FindNoCase("cannot drop administrative user", arguments.e.message)) {
					printError("Cannot drop administrative/system user: " & arguments.dbName);
					printWarning("Please choose a different database name (e.g., 'myapp_dev', 'wheels_dev')");
					printWarning("Oracle system users like SYS, SYSTEM, ADMIN, XDB, ORACLE_OCM, etc. cannot be dropped");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-65096", arguments.e.message) || FindNoCase("common user or role name", arguments.e.message)) {
					printError("Oracle CDB requires C## prefix for common users");
					printWarning("This may indicate insufficient privileges to set _ORACLE_SCRIPT session variable");
					printWarning("Try using a database name starting with 'C##' (e.g., 'C##MYAPP')");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-01017", arguments.e.message) || FindNoCase("invalid username/password", arguments.e.message)) {
					printError("Invalid username/password - check Oracle credentials");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-12505", arguments.e.message) || FindNoCase("TNS:listener", arguments.e.message)) {
					printError("Cannot connect to Oracle server - check SID and connection settings");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-01031", arguments.e.message) || FindNoCase("insufficient privileges", arguments.e.message)) {
					printError("Insufficient privileges - user must have CREATE USER and GRANT privileges");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-28001", arguments.e.message) || FindNoCase("password has expired", arguments.e.message)) {
					printError("Password has expired - please update the password in Oracle");
					local.errorHandled = true;
				}
				break;
		}
		
		if (!local.errorHandled) {
			printError(arguments.dbType & " Error: " & arguments.e.message);
		}

		// Always throw to propagate the error up (prevents duplicate error messages)
		throw(message=arguments.e.message, detail=(isDefined("arguments.e.detail") ? arguments.e.detail : ""));
	}

	/**
	 * Create datasource interactively
	 */
	private struct function createInteractiveDatasource(
		required string datasourceName,
		required string appPath,
		required string environment,
		string dbtype = ""
	) {
		print.line();
		print.cyanBoldLine("=== Interactive Datasource Creation ===");
		print.line();

		local.dbType = "";
		local.templateKey = "";

		// If dbtype parameter was provided, use it directly
		if (Len(arguments.dbtype)) {
			local.dbType = arguments.dbtype;

			// Map to template key
			switch (local.dbType) {
				case "MySQL":
				case "MySQL5":
					local.templateKey = "mysql";
					break;
				case "PostgreSQL":
					local.templateKey = "postgre";
					break;
				case "MSSQLServer":
				case "MSSQL":
					local.templateKey = "mssql";
					break;
				case "Oracle":
					local.templateKey = "oracle";
					break;
				case "H2":
					local.templateKey = "h2";
					break;
				default:
					printError("Invalid dbtype: " & local.dbType);
					return {};
			}

			print.greenLine("Using database type from parameter: " & local.dbType);
			print.line();
		} else {
			// Ask for database type interactively
			print.yellowLine("Supported database types:");
			print.line("  1. MySQL");
			print.line("  2. PostgreSQL");
			print.line("  3. SQL Server (MSSQL)");
			print.line("  4. Oracle");
			print.line("  5. H2");
			print.line();

			local.dbTypeChoice = ask("Select database type [1-5]: ");

			switch (local.dbTypeChoice) {
				case "1":
					local.dbType = "MySQL";
					local.templateKey = "mysql";
					break;
				case "2":
					local.dbType = "PostgreSQL";
					local.templateKey = "postgre";
					break;
				case "3":
					local.dbType = "MSSQLServer";
					local.templateKey = "mssql";
					break;
				case "4":
					local.dbType = "Oracle";
					local.templateKey = "oracle";
					break;
				case "5":
					local.dbType = "H2";
					local.templateKey = "h2";
					break;
				default:
					printError("Invalid choice!");
					return {};
			}

			print.line();
			print.greenLine("Selected: " & local.dbType);
			print.line();
		}

		// Get datasource templates
		local.templates = getDatasourceTemplates();
		if (!structKeyExists(local.templates, local.templateKey)) {
			printError("Template not found for " & local.dbType);
			return {};
		}

		local.template = local.templates[local.templateKey];

		// Prompt for connection details
		print.cyanLine("Enter connection details:");
		print.line();

		// H2 is embedded - only needs database name and username (optional password)
		if (local.dbType == "H2") {
			local.database = ask("Database name [wheels_dev]: ");
			if (!len(local.database)) {
				local.database = "wheels_dev";
			}

			local.username = ask("Username [root]: ");
			if (!len(local.username)) {
				local.username = "root";
			}

			local.password = ask("Password (optional): ", "", true);

			// H2 doesn't use host/port
			local.host = "";
			local.port = "";

		} else {
			// For server-based databases (MySQL, PostgreSQL, MSSQL, Oracle)
			local.host = ask("Host [" & getDefaultValue(local.template, "host", "localhost") & "]: ");
			if (!len(local.host)) {
				local.host = getDefaultValue(local.template, "host", "localhost");
			}

			local.port = ask("Port [" & getDefaultValue(local.template, "port", getDefaultPort(local.dbType)) & "]: ");
			if (!len(local.port)) {
				local.port = getDefaultValue(local.template, "port", getDefaultPort(local.dbType));
			}

			local.database = ask("Database name [wheels_dev]: ");
			if (!len(local.database)) {
				local.database = "wheels_dev";
			}

			local.username = ask("Username [" & getDefaultValue(local.template, "username", "root") & "]: ");
			if (!len(local.username)) {
				local.username = getDefaultValue(local.template, "username", "root");
			}

			local.password = ask("Password: ", "", true);  // true for password masking

			// For Oracle, ask for SID
			if (local.dbType == "Oracle") {
				local.sid = ask("SID [FREE]: ");
				if (!len(local.sid)) {
					local.sid = "FREE";
				}
			}
		}

		// Build connection string
		local.connectionString = buildConnectionString(local.dbType, local.host, local.port, local.database, local.sid ?: "");

		print.line();
		print.yellowLine("Review datasource configuration:");
		print.line("  Datasource Name: " & arguments.datasourceName);
		print.line("  Database Type: " & local.dbType);

		// Only show host/port for server-based databases
		if (local.dbType != "H2") {
			print.line("  Host: " & local.host);
			print.line("  Port: " & local.port);
		}

		print.line("  Database: " & local.database);
		print.line("  Username: " & local.username);
		print.line("  Connection String: " & local.connectionString);
		print.line();

		if (ask("Create this datasource? [y/n]: ") != "y") {
			printWarning("Datasource creation cancelled");
			return {};
		}

		// Create datasource configuration
		local.dsConfig = {
			class: local.template.class,
			bundleName: local.template.bundleName,
			bundleVersion: local.template.bundleVersion,
			connectionString: local.connectionString,
			username: local.username,
			password: local.password,
			connectionLimit: -1,
			liveTimeout: 15,
			validate: false
		};

		// Instead of saving hardcoded values, call wheels env setup to create proper environment-based configuration
		print.line();
		print.yellowLine("Setting up environment configuration with environment variables...");
		print.line();

		try {
			command("wheels env setup")
				.params(
					environment = arguments.environment,
					dbtype = local.dbType,
					datasource = arguments.datasourceName,
					database = local.database,
					host = local.host,
					port = local.port,
					username = local.username,
					password = local.password,
					sid = local.sid ?: "",
					skipDatabase = true,
					force = true
				)
				.run();

			print.line();
			printSuccess("Environment configuration created with environment variables!");
			print.line();

		} catch (any e) {
			printError("Failed to create environment configuration: " & e.message);
			printWarning("You may need to manually run: wheels env setup environment=#arguments.environment#");
		}

		// Return datasource info in the format expected by the rest of the code
		return {
			driver: local.dbType,
			database: local.database,
			host: local.host,
			port: local.port,
			username: local.username,
			password: local.password,
			sid: local.sid ?: ""
		};
	}

	/**
	 * Get datasource templates from app.cfm
	 */
	private struct function getDatasourceTemplates() {
		return {
			mysql: {
				class: "com.mysql.cj.jdbc.Driver",
				bundleName: "com.mysql.cj",
				bundleVersion: "9.1.0",
				host: "localhost",
				port: "3306",
				username: "root"
			},
			postgre: {
				class: "org.postgresql.Driver",
				bundleName: "org.postgresql.jdbc",
				bundleVersion: "42.7.4",
				host: "localhost",
				port: "5432",
				username: "postgres"
			},
			mssql: {
				class: "com.microsoft.sqlserver.jdbc.SQLServerDriver",
				bundleName: "org.lucee.mssql",
				bundleVersion: "12.6.3.jre11",
				host: "localhost",
				port: "1433",
				username: "admin"
			},
			oracle: {
				class: "oracle.jdbc.OracleDriver",
				bundleName: "org.lucee.oracle",
				bundleVersion: "21.8.0.0-ojdbc11",
				host: "localhost",
				port: "1521",
				username: "system"
			},
			h2: {
				class: "org.h2.Driver",
				bundleName: "org.h2",
				bundleVersion: "1.3.172",
				host: "",
				port: "",
				username: "root"
			}
		};
	}

	/**
	 * Get default port for database type
	 */
	private string function getDefaultPort(required string dbType) {
		switch (arguments.dbType) {
			case "MySQL":
				return "3306";
			case "PostgreSQL":
				return "5432";
			case "MSSQLServer":
				return "1433";
			case "Oracle":
				return "1521";
			default:
				return "";
		}
	}

	/**
	 * Get default value from template
	 */
	private string function getDefaultValue(required struct template, required string key, string defaultValue = "") {
		return structKeyExists(arguments.template, arguments.key) ? arguments.template[arguments.key] : arguments.defaultValue;
	}

	/**
	 * Build connection string
	 */
	private string function buildConnectionString(required string dbType, required string host, required string port, required string database, string sid = "") {
		switch (arguments.dbType) {
			case "MySQL":
				return "jdbc:mysql://#arguments.host#:#arguments.port#/#arguments.database#?characterEncoding=UTF-8&serverTimezone=UTC&maxReconnects=3";
			case "PostgreSQL":
				return "jdbc:postgresql://#arguments.host#:#arguments.port#/#arguments.database#";
			case "MSSQLServer":
				return "jdbc:sqlserver://#arguments.host#:#arguments.port#;DATABASENAME=#arguments.database#;trustServerCertificate=true;SelectMethod=direct";
			case "Oracle":
				return "jdbc:oracle:thin:@#arguments.host#:#arguments.port#:#arguments.sid#";
			case "H2":
				local.appPath = getCWD();
				return "jdbc:h2:#local.appPath#db/h2/#arguments.database#;MODE=MySQL";
			default:
				return "";
		}
	}

	/**
	 * Save datasource to app.cfm
	 */
	private boolean function saveDatasourceToAppCfm(required string dsName, required struct dsConfig, required string appPath) {
		try {
			local.appCfmPath = arguments.appPath & "/config/app.cfm";
			if (!fileExists(local.appCfmPath)) {
				printError("app.cfm not found at: " & local.appCfmPath);
				return false;
			}

			local.content = fileRead(local.appCfmPath);

			// Build datasource definition
			local.dsDefinition = '
	this.datasources["#arguments.dsName#"] = {
		class: "#arguments.dsConfig.class#",
		bundleName: "#arguments.dsConfig.bundleName#",
		bundleVersion: "#arguments.dsConfig.bundleVersion#",
		connectionString: "#arguments.dsConfig.connectionString#",
		username: "#arguments.dsConfig.username#",
		password: "#arguments.dsConfig.password#",

		// optional settings
		connectionLimit:#arguments.dsConfig.connectionLimit#,
		liveTimeout:#arguments.dsConfig.liveTimeout#,
		validate:#arguments.dsConfig.validate#
	};
';

			// Check if datasource already exists
			if (find('this.datasources["#arguments.dsName#"]', local.content)) {
				printWarning("Datasource already exists in app.cfm - skipping");
				return true;
			}

			// Insert before CLI-Appends-Here marker
			if (find("// CLI-Appends-Here", local.content)) {
				local.content = replace(local.content, "// CLI-Appends-Here", local.dsDefinition & chr(10) & chr(9) & "// CLI-Appends-Here");
			} else {
				// Insert before closing cfscript tag
				local.closingTag = "<" & "/cfscript>";
				local.content = replace(local.content, local.closingTag, local.dsDefinition & local.closingTag);
			}

			fileWrite(local.appCfmPath, local.content);
			printSuccess("Datasource added to app.cfm");
			return true;

		} catch (any e) {
			printError("Error saving to app.cfm: " & e.message);
			return false;
		}
	}

	/**
	 * Save datasource to CFConfig.json
	 */
	private boolean function saveDatasourceToCFConfig(required string dsName, required struct dsConfig, required string dbType, required string host, required string port, required string database, required string appPath) {
		try {
			local.cfconfigPath = arguments.appPath & "/CFConfig.json";
			if (!fileExists(local.cfconfigPath)) {
				printWarning("CFConfig.json not found - skipping");
				return true; // Not critical
			}

			local.cfconfig = deserializeJSON(fileRead(local.cfconfigPath));

			if (!structKeyExists(local.cfconfig, "datasources")) {
				local.cfconfig.datasources = {};
			}

			// Map driver to CFConfig class
			local.cfconfigClass = "";
			switch (arguments.dbType) {
				case "MySQL":
					local.cfconfigClass = "com.mysql.cj.jdbc.Driver";
					break;
				case "PostgreSQL":
					local.cfconfigClass = "org.postgresql.Driver";
					break;
				case "MSSQLServer":
					local.cfconfigClass = "com.microsoft.sqlserver.jdbc.SQLServerDriver";
					break;
				case "Oracle":
					local.cfconfigClass = "oracle.jdbc.OracleDriver";
					break;
				case "H2":
					local.cfconfigClass = "org.h2.Driver";
					break;
			}

			local.cfconfig.datasources[arguments.dsName] = {
				class: local.cfconfigClass,
				connectionString: arguments.dsConfig.connectionString,
				username: arguments.dsConfig.username,
				password: arguments.dsConfig.password,
				host: arguments.host,
				port: val(arguments.port),
				database: arguments.database
			};

			fileWrite(local.cfconfigPath, serializeJSON(local.cfconfig));
			printSuccess("Datasource added to CFConfig.json");
			return true;

		} catch (any e) {
			printWarning("Error saving to CFConfig.json: " & e.message);
			return false; // Non-critical
		}
	}

	/**
	 * Ensure environment setup exists after database creation
	 * If .env files don't exist, call wheels env setup with --skipDatabase to avoid infinite loops
	 */
	private void function ensureEnvironmentSetup(required string appPath, required string environment, required string datasource, required string dbType, required struct dsInfo) {
		try {
			// Check if .env file exists for this environment
			local.envFile = arguments.appPath & "/.env." & arguments.environment;

			if (!fileExists(local.envFile)) {
				print.line();
				print.yellowLine("Environment files not found for: " & arguments.environment);
				print.yellowLine("Creating environment configuration...");
				print.line();

				// Call wheels env setup with skipDatabase to avoid infinite loop
				command("wheels env setup")
					.params(
						environment = arguments.environment,
						dbtype = arguments.dbType,
						datasource = arguments.datasource,
						database = arguments.dsInfo.database,
						host = arguments.dsInfo.host ?: "localhost",
						port = arguments.dsInfo.port ?: "",
						username = arguments.dsInfo.username ?: "root",
						password = arguments.dsInfo.password ?: "",
						sid = arguments.dsInfo.sid ?: "",
						skipDatabase = true,
						force = true
					)
					.run();

				print.line();
				printSuccess("Environment configuration created!");
			}

		} catch (any e) {
			printWarning("Could not create environment setup: " & e.message);
			printWarning("You may need to run: wheels env setup environment=#arguments.environment#");
		}
	}

	/**
	 * Write datasource to app.cfm using environment variables
	 * This is called AFTER database creation to ensure .env files exist first
	 */
	private void function writeDatasourceToAppCfmWithEnvVars(required string appPath, required string datasourceName, required string dbType, required string environment) {
		try {
			print.line();
			printStep("Writing datasource to app.cfm...");

			// Build config structure expected by writeDatasourceToAppCfm
			local.config = {
				"dbtype": arguments.dbType,
				"datasourceInfo": {
					"datasource": arguments.datasourceName,
					"driver": arguments.dbType
				}
			};

			// Call writeDatasourceToAppCfm from EnvironmentService using injected property
			local.result = variables.environmentService.writeDatasourceToAppCfm(
				arguments.environment,
				local.config,
				arguments.appPath
			);

			if (local.result.success) {
				printSuccess(local.result.message);
			} else {
				printWarning(local.result.message);
			}

		} catch (any e) {
			printWarning("Could not write datasource to app.cfm: " & e.message);
			printWarning("You may need to manually add the datasource configuration");
		}
	}

}