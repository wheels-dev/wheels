/**
 * Create a new database
 *
 * Supports MySQL, PostgreSQL, SQL Server, Oracle, H2, and SQLite databases.
 * For SQLite, this will create the database file immediately with a metadata table.
 * For H2, the database is created automatically on first connection.
 * For server-based databases, this will create the database on the server.
 *
 * {code:bash}
 * # Create database using current environment's datasource
 * wheels db create
 *
 * # Create specific datasource
 * wheels db create --datasource=myapp_dev
 *
 * # Create with specific environment
 * wheels db create --datasource=myapp_dev --environment=production
 *
 * # Overwrite existing database
 * wheels db create --force
 *
 * # Create with specific database type
 * wheels db create --dbtype=sqlite
 * wheels db create --dbtype=mysql
 * {code}
 */
component extends="../base" {

	property name="environmentService" inject="EnvironmentService@wheels-cli";
	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @environment Optional environment (defaults to current environment)
	 * @dbtype Optional database type (h2, sqlite, mysql, postgres, mssql, oracle)
	 * @help Create a new database
	 */
	public void function run(
		string datasource = "",
		string environment = "",
		string database = "",
		string dbtype = "",
		boolean force = false
	) {
		local.appPath = getCWD();
		requireWheelsApp(local.appPath);
		arguments = reconstructArgs(
			argStruct=arguments,
			allowedValues={
				dbtype: ["h2", "sqlite", "mysql", "postgres", "mssql", "oracle"]
			}
		);

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
					"Specify a datasource: wheels db create --datasource=myapp_dev",
					"Or configure dataSourceName in your app.cfm file"
				]);
				return;
			}

			detailOutput.header("Database Creation", 50);
			detailOutput.metric("Datasource", arguments.datasource);
			detailOutput.metric("Environment", arguments.environment);
			detailOutput.divider();

			// Normalize dbtype parameter
			if (Len(arguments.dbtype)) {
				arguments.dbtype = normalizeDbType(arguments.dbtype);
			}

			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource, arguments.environment);

			if (StructIsEmpty(local.dsInfo)) {
				detailOutput.statusWarning("Datasource '#arguments.datasource#' not found in server configuration.");
				
				// Ask if user wants to create datasource
				if (ask("Would you like to create this datasource now? [y/n]: ") == "y") {
					local.dsInfo = createInteractiveDatasource(
						datasourceName = arguments.datasource,
						appPath = local.appPath,
						environment = arguments.environment,
						dbtype = arguments.dbtype
					);
					if (StructIsEmpty(local.dsInfo)) {
						detailOutput.error("Datasource creation cancelled or failed");
						return;
					}
				} else {
					detailOutput.statusInfo("Please create the datasource in your config/app.cfm first.");
					detailOutput.statusFailed("Datasource '#arguments.datasource#' not found!");
					return;
				}
			} else {
				// Datasource found - check if dbtype parameter matches datasource type
				if (Len(arguments.dbtype) && normalizeDbType(arguments.dbtype) != normalizeDbType(local.dsInfo.driver)) {
					detailOutput.statusWarning("dbtype parameter ('#arguments.dbtype#') does not match datasource type ('#local.dsInfo.driver#')");
					detailOutput.statusInfo("Using datasource type: #local.dsInfo.driver#");
				}
			}

			// Extract database name and connection info
			local.dbName = arguments.database != '' ? arguments.database : local.dsInfo.database != '' ? local.dsInfo.database : "wheels_dev";
			local.dbType = local.dsInfo.driver;

			// For file-based databases (SQLite, H2), extract just the database name if a full path/connection string was provided
			if (local.dbType == "SQLite") {
				if (findNoCase("jdbc:sqlite:", local.dbName) == 1) {
					local.fullPath = mid(local.dbName, 14, len(local.dbName));
					local.fileName = listLast(local.fullPath, "/\");
					local.dbName = listFirst(local.fileName, ".");
				} else if (find("\", local.dbName) || find("/", local.dbName)) {
					local.fileName = listLast(local.dbName, "/\");
					local.dbName = listFirst(local.fileName, ".");
				}
				local.dsInfo.database = local.dbName;
			} else if (local.dbType == "H2") {
				if (findNoCase("jdbc:h2:", local.dbName) == 1) {
					local.fullPath = mid(local.dbName, 9, len(local.dbName));
					local.fileName = listLast(local.fullPath, "/\");
					local.dbName = listFirst(local.fileName, ";");
				} else if (find("\", local.dbName) || find("/", local.dbName)) {
					local.fileName = listLast(local.dbName, "/\");
					local.dbName = listFirst(local.fileName, ";");
				}
				local.dsInfo.database = local.dbName;
			}

			// Validate Oracle identifier (no hyphens or special characters allowed)
			if (local.dbType == "Oracle" && reFind("[^a-zA-Z0-9_$##]", local.dbName)) {
				detailOutput.error("Invalid Oracle identifier: '#local.dbName#'");
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
			
			// Create database based on type
			switch (local.dbType) {
				case "MySQL":
				case "MySQL5":
					createDatabase(local.dsInfo, local.dbName, arguments.force, "MySQL");
					break;
				case "Postgre":
				case "Postgres":
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
					detailOutput.statusInfo("H2 databases are created automatically on first connection");
					detailOutput.statusSuccess("No action needed - database will be created when application starts");
					break;
				case "SQLite":
					createSQLiteDatabase(local.dsInfo, local.dbName, arguments.force);
					break;
				default:
					detailOutput.statusInfo("Database creation not supported for driver: #local.dbType#");
					detailOutput.statusWarning("Please create the database manually using your database management tools.");
					return;
			}

			// After database creation, ensure environment setup exists
			ensureEnvironmentSetup(local.appPath, arguments.environment, arguments.datasource, local.dbType, local.dsInfo);

			// Now write datasource to app.cfm using environment variables
			writeDatasourceToAppCfmWithEnvVars(local.appPath, arguments.datasource, local.dbType, arguments.environment);

		} catch (any e) {
			// Display error if not already handled
			if (!FindNoCase("Database already exists", e.message) &&
			    !FindNoCase("Access denied", e.message) &&
			    !FindNoCase("authentication failed", e.message)) {
				detailOutput.statusFailed("Database creation failed: " & e.message);
				if (StructKeyExists(e, "detail") && Len(e.detail)) {
					detailOutput.output("Details: " & e.detail, true);
				}
			}
			setExitCode(1);
		}
	}

	/**
	 * Unified database creation function
	 */
	private void function createDatabase(required struct dsInfo, required string dbName, boolean force = false, required string dbType) {
		try {
			print.line("Initializing #arguments.dbType# database creation...").toConsole();
			
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
				detailOutput.error("No " & arguments.dbType & " driver found. Ensure JDBC driver is in classpath.");
				// Provide database-specific guidance for missing drivers
				switch (arguments.dbType) {
					case "Oracle":
						local.cbHome = getCommandBoxHome();
						local.libPath = formatLibPath(local.cbHome);
						detailOutput.divider();
						detailOutput.statusWarning("Oracle JDBC Driver Installation:");
						detailOutput.line();
						detailOutput.output("1. Download the driver from Oracle's official website:");
						detailOutput.output("   https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html");
						detailOutput.output("   - Download 'ojdbc11.jar' or 'ojdbc8.jar'");
						detailOutput.line();
						
						if (len(local.cbHome)) {
							detailOutput.output("2. Place the JAR file in this directory:");
							detailOutput.output("   #local.libPath#");
						} else {
							detailOutput.output("2. Place the JAR file in CommandBox's library directory:");
							detailOutput.output("   #local.libPath#");
						}
						
						detailOutput.line();
						detailOutput.output("3. Restart CommandBox completely:");
						detailOutput.output("   - Close all CommandBox instances (don't just reload)");
						detailOutput.output("   - This ensures the JDBC driver is properly loaded");
						detailOutput.line();
						detailOutput.output("4. Verify installation:");
						detailOutput.output("   wheels db create datasource=YourDataSourceName");
						detailOutput.output("   You should see: '[OK] Driver found: oracle.jdbc.OracleDriver'");
						break;
						
					default:
						detailOutput.statusWarning("Driver installation guidance:");
						detailOutput.output("1. Restart CommandBox completely");
						detailOutput.output("2. Check CommandBox lib directory for appropriate JAR files");
						detailOutput.output("3. Ensure required bundles are installed");
				}
				
				return;
			}
			
			// Create properties for connection
			local.props = createObject("java", "java.util.Properties");
			local.props.setProperty("user", local.username);
			local.props.setProperty("password", local.password);
			
			// Test if driver accepts the URL
			if (!local.driver.acceptsURL(local.url)) {
				detailOutput.error(arguments.dbType & " driver does not accept the URL format: #local.url#");
				return;
			}
			
			// Connect using driver directly
			local.conn = local.driver.connect(local.url, local.props);
			
			if (isNull(local.conn)) {
				detailOutput.statusFailed("Connection failed");
				detailOutput.nextSteps([
					"1. Check if #arguments.dbType# server is running",
					"2. Verify server/port configuration",
					"3. Check credentials",
					"4. Check network/firewall settings"
				]);
				if (arguments.dbType == "PostgreSQL") {
					detailOutput.statusWarning("Check pg_hba.conf authentication settings");
				}
				detailOutput.error("Connection failed");
				return;
			}
			
			detailOutput.statusSuccess("Connected successfully to #arguments.dbType# server!");
			
			// Check if database already exists
			print.line("Checking if database exists...").toConsole();
			local.exists = checkDatabaseExists(local.conn, arguments.dbName, arguments.dbType);
			
			if (local.exists) {
				if (!arguments.force) {
					detailOutput.error("Database '#arguments.dbName#' already exists! Use force=true to drop existing database.");
					return;
				}
				
				detailOutput.statusWarning("Database '#arguments.dbName#' already exists!");
				
				// Handle active connections for PostgreSQL
				if (arguments.dbType == "PostgreSQL") {
					print.line("Terminating active connections...").toConsole();
					terminatePostgreSQLConnections(local.conn, arguments.dbName);
				}
				
				// Drop existing database
				print.line("Dropping existing database...").toConsole();
				dropDatabase(local.conn, arguments.dbName, arguments.dbType);
				detailOutput.statusSuccess("Existing database dropped.");
			}
			
			// Create the database
			print.line("Creating #arguments.dbType# database '#arguments.dbName#'...").toConsole();
			executeCreateDatabase(local.conn, arguments.dbName, arguments.dbType);
			detailOutput.statusSuccess("Database '#arguments.dbName#' created successfully!");
			
			// Verify database was created
			print.line("Verifying database creation...").toConsole();
			if (verifyDatabaseCreated(local.conn, arguments.dbName, arguments.dbType)) {
				detailOutput.statusSuccess("Database '#arguments.dbName#' verified successfully!");
			} else {
				detailOutput.statusWarning("Database creation verification failed");
			}
			
			// Clean up
			local.conn.close();
			
			detailOutput.divider();
			detailOutput.success("#arguments.dbType# database creation completed successfully!");
			
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

				local.dropSQL = "DROP USER " & UCASE(arguments.dbName) & " CASCADE";
				detailOutput.getPrint().line("DEBUG - Executing DROP SQL: #local.dropSQL#");
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
				local.createSQL = "CREATE DATABASE `#arguments.dbName#` " &
								"CHARACTER SET utf8mb4 " &
								"COLLATE utf8mb4_unicode_ci";
				local.stmt.executeUpdate(local.createSQL);
				break;

			case "PostgreSQL":
				local.createSQL = 'CREATE DATABASE "#arguments.dbName#" ' &
								'WITH ENCODING ''UTF8'' ' &
								'LC_COLLATE ''en_US.UTF-8'' ' &
								'LC_CTYPE ''en_US.UTF-8'' ' &
								'TEMPLATE template0';
				local.stmt.executeUpdate(local.createSQL);
				break;

			case "SQLServer":
				local.createSQL = "CREATE DATABASE [#arguments.dbName#]";
				local.stmt.execute(local.createSQL);
				break;

			case "Oracle":
				// Oracle 12c+ CDB requires either C## prefix or _ORACLE_SCRIPT session variable
				// Enable creation of non-C## users in CDB (for development)
				try {
					local.alterSession = "ALTER SESSION SET ""_ORACLE_SCRIPT""=true";
					local.stmt.execute(local.alterSession);
				} catch (any e) {
					detailOutput.statusInfo("Note: Could not set _ORACLE_SCRIPT (may not be needed)");
				}

				local.createSQL = "CREATE USER #arguments.dbName# IDENTIFIED BY #arguments.dbName#_pass";
				detailOutput.getPrint().line("DEBUG - Executing SQL: #local.createSQL#");
				local.stmt.execute(local.createSQL);

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
					detailOutput.statusFailed("Database already exists: #arguments.dbName#");
					local.errorHandled = true;
				} else if (FindNoCase("Access denied", arguments.e.message)) {
					detailOutput.statusFailed("Access denied - check MySQL credentials and permissions");
					local.errorHandled = true;
				} else if (FindNoCase("Communications link failure", arguments.e.message)) {
					detailOutput.statusFailed("Cannot connect to MySQL server - check if MySQL is running and accessible");
					local.errorHandled = true;
				}
				break;

			case "PostgreSQL":
				if (FindNoCase("already exists", arguments.e.message)) {
					detailOutput.statusFailed("Database already exists: #arguments.dbName#");
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
				if (FindNoCase("database exists", arguments.e.message)) {
					detailOutput.statusFailed("Database already exists: #arguments.dbName#");
					local.errorHandled = true;
				} else if (FindNoCase("Login failed", arguments.e.message)) {
					detailOutput.statusFailed("Login failed - check SQL Server credentials");
					local.errorHandled = true;
				}
				break;

			case "Oracle":
				if (FindNoCase("ORA-01920", arguments.e.message) || FindNoCase("user name conflicts", arguments.e.message)) {
					detailOutput.statusFailed("User (schema) already exists: #arguments.dbName#");
					detailOutput.statusWarning("Use force=true to drop and recreate the user");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-28014", arguments.e.message) || FindNoCase("cannot drop administrative user", arguments.e.message)) {
					detailOutput.statusFailed("Cannot drop administrative/system user: #arguments.dbName#");
					detailOutput.statusWarning("Please choose a different database name (e.g., 'myapp_dev', 'wheels_dev')");
					detailOutput.statusWarning("Oracle system users like SYS, SYSTEM, ADMIN, XDB, ORACLE_OCM, etc. cannot be dropped");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-65096", arguments.e.message) || FindNoCase("common user or role name", arguments.e.message)) {
					detailOutput.statusFailed("Oracle CDB requires C## prefix for common users");
					detailOutput.statusWarning("This may indicate insufficient privileges to set _ORACLE_SCRIPT session variable");
					detailOutput.statusWarning("Try using a database name starting with 'C##' (e.g., 'C##MYAPP')");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-01017", arguments.e.message) || FindNoCase("invalid username/password", arguments.e.message)) {
					detailOutput.statusFailed("Invalid username/password - check Oracle credentials");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-12505", arguments.e.message) || FindNoCase("TNS:listener", arguments.e.message)) {
					detailOutput.statusFailed("Cannot connect to Oracle server - check SID and connection settings");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-01031", arguments.e.message) || FindNoCase("insufficient privileges", arguments.e.message)) {
					detailOutput.statusFailed("Insufficient privileges - user must have CREATE USER and GRANT privileges");
					local.errorHandled = true;
				} else if (FindNoCase("ORA-28001", arguments.e.message) || FindNoCase("password has expired", arguments.e.message)) {
					detailOutput.statusFailed("Password has expired - please update the password in Oracle");
					local.errorHandled = true;
				}
				break;
		}
		
		if (!local.errorHandled) {
			detailOutput.statusFailed("#arguments.dbType# Error: #arguments.e.message#");
		}

		// Always throw to propagate the error up
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
		detailOutput.header("Interactive Datasource Creation", 50);

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
				case "Postgre":
				case "Postgres":
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
				case "SQLite":
					local.templateKey = "sqlite";
					break;
				default:
					detailOutput.statusFailed("Invalid dbtype: #local.dbType#");
					return {};
			}

			detailOutput.statusSuccess("Using database type from parameter: #local.dbType#");
		} else {
			// Ask for database type interactively
			detailOutput.subHeader("Supported Database Types", 50);
			detailOutput.output("1. MySQL");
			detailOutput.output("2. PostgreSQL");
			detailOutput.output("3. SQL Server (MSSQL)");
			detailOutput.output("4. Oracle");
			detailOutput.output("5. H2");
			detailOutput.output("6. SQLite");
			detailOutput.line();

			local.dbTypeChoice = ask("Select database type [1-6]: ");

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
				case "6":
					local.dbType = "SQLite";
					local.templateKey = "sqlite";
					break;
				default:
					detailOutput.statusFailed("Invalid choice!");
					return {};
			}

			detailOutput.statusSuccess("Selected: #local.dbType#");
		}

		// Get datasource templates
		local.templates = getDatasourceTemplates();
		if (!structKeyExists(local.templates, local.templateKey)) {
			detailOutput.statusFailed("Template not found for #local.dbType#");
			return {};
		}

		local.template = local.templates[local.templateKey];

		// Prompt for connection details
		detailOutput.subHeader("Connection Details", 50);

		// H2 and SQLite are file-based - only need database name
		if (local.dbType == "H2" || local.dbType == "SQLite") {
			local.database = ask("Database name [wheels_dev]: ");
			if (!len(local.database)) {
				local.database = "wheels_dev";
			}

			if (local.dbType == "H2") {
				local.username = ask("Username [root]: ");
				if (!len(local.username)) {
					local.username = "root";
				}

				local.password = ask("Password (optional): ", "", true);
			} else {
				// SQLite doesn't use username/password
				local.username = "";
				local.password = "";
			}

			// H2 and SQLite don't use host/port
			local.host = "";
			local.port = "";

		} else {
			// For server-based databases
			local.host = ask("Host [#getDefaultValue(local.template, "host", "localhost")#]: ");
			if (!len(local.host)) {
				local.host = getDefaultValue(local.template, "host", "localhost");
			}

			local.port = ask("Port [#getDefaultValue(local.template, "port", getDefaultPort(local.dbType))#]: ");
			if (!len(local.port)) {
				local.port = getDefaultValue(local.template, "port", getDefaultPort(local.dbType));
			}

			local.database = ask("Database name [wheels_dev]: ");
			if (!len(local.database)) {
				local.database = "wheels_dev";
			}

			local.username = ask("Username [#getDefaultValue(local.template, "username", "root")#]: ");
			if (!len(local.username)) {
				local.username = getDefaultValue(local.template, "username", "root");
			}

			local.password = ask("Password: ", "", true);  // true for password masking

			// For Oracle, ask for connection type and details
			if (local.dbType == "Oracle") {
				detailOutput.output("Oracle Connection Type:");
				detailOutput.output("1. SID (System Identifier)");
				detailOutput.output("2. Service Name");
				detailOutput.line();
				
				local.connectionTypeChoice = ask("Select connection type [1-2]: ");
				
				if (local.connectionTypeChoice == "2") {
					// Service Name
					local.serviceName = ask("Service Name: ");
					if (!len(local.serviceName)) {
						detailOutput.statusWarning("Service Name is required");
						return {};
					}
					local.oracleConnectionType = "servicename";
					local.oracleIdentifier = local.serviceName;
				} else {
					// SID (default)
					local.sid = ask("SID [FREE]: ");
					if (!len(local.sid)) {
						local.sid = "FREE";
					}
					local.oracleConnectionType = "sid";
					local.oracleIdentifier = local.sid;
				}
			}
		}

		// Build connection string
		local.connectionString = buildConnectionString(
			local.dbType, 
			local.host, 
			local.port, 
			local.database, 
			local.sid ?: "", 
			local.serviceName ?: "", 
			local.oracleConnectionType ?: "sid"
		);

		detailOutput.subHeader("Configuration Review", 50);
		detailOutput.metric("Datasource Name", arguments.datasourceName);
		detailOutput.metric("Database Type", local.dbType);
		
		if (local.dbType != "H2" && local.dbType != "SQLite") {
			detailOutput.metric("Host", local.host);
			detailOutput.metric("Port", local.port);
		}
		
		detailOutput.metric("Database", local.database);
		
		if (local.dbType == "Oracle") {
			if (local.oracleConnectionType == "servicename") {
				detailOutput.metric("Service Name", local.serviceName);
			} else {
				detailOutput.metric("SID", local.sid);
			}
		}
		
		if (local.dbType != "SQLite") {
			detailOutput.metric("Username", local.username);
		}
		
		detailOutput.metric("Connection String", local.connectionString);
		detailOutput.line();

		if (ask("Create this datasource? [y/n]: ") != "y") {
			detailOutput.statusWarning("Datasource creation cancelled");
			return {};
		}

		// Create datasource configuration
		local.dsConfig = {
			class: local.template.class,
			bundleName: local.template.bundleName,
			connectionString: local.connectionString,
			username: local.username,
			password: local.password,
			connectionLimit: -1,
			liveTimeout: 15,
			validate: false
		};

		// Instead of saving hardcoded values, call wheels env setup to create proper environment-based configuration
		print.line("Setting up environment configuration with environment variables...").toConsole();

		try {
			command("wheels env setup")
				.params(
					environment = arguments.environment,
					dbtype = normalizeDbType(local.dbType),
					datasource = arguments.datasourceName,
					database = local.database,
					host = local.host,
					port = local.port,
					username = local.username,
					password = local.password,
					sid = local.sid ?: "",
					servicename = local.serviceName ?: "",
					oracleConnectionType = local.oracleConnectionType ?: "sid",
					skipDatabase = true
				)
				.run();

			detailOutput.statusSuccess("Environment configuration created with environment variables!");

		} catch (any e) {
			detailOutput.statusFailed("Failed to create environment configuration: #e.message#");
			detailOutput.statusWarning("You may need to manually run: wheels env setup environment=#arguments.environment#");
		}

		// Return datasource info in the format expected by the rest of the code
		local.result = {
			driver: local.dbType,
			database: local.database,
			host: local.host,
			port: local.port,
			username: local.username,
			password: local.password
		};
		
		// Add Oracle-specific connection information
		if (local.dbType == "Oracle") {
			if (local.oracleConnectionType == "servicename") {
				local.result.servicename = local.serviceName;
				local.result.oracleConnectionType = "servicename";
			} else {
				local.result.sid = local.sid;
				local.result.oracleConnectionType = "sid";
			}
		}
		
		return local.result;
	}

	/**
	 * Get datasource templates from app.cfm
	 */
	private struct function getDatasourceTemplates() {
		return {
			mysql: {
				class: "com.mysql.cj.jdbc.Driver",
				bundleName: "com.mysql.cj",
				host: "localhost",
				port: "3306",
				username: "root"
			},
			postgre: {
				class: "org.postgresql.Driver",
				bundleName: "org.postgresql.jdbc",
				host: "localhost",
				port: "5432",
				username: "postgres"
			},
			mssql: {
				class: "com.microsoft.sqlserver.jdbc.SQLServerDriver",
				bundleName: "org.lucee.mssql",
				host: "localhost",
				port: "1433",
				username: "admin"
			},
			oracle: {
				class: "oracle.jdbc.OracleDriver",
				bundleName: "org.lucee.oracle",
				host: "localhost",
				port: "1521",
				username: "system"
			},
			h2: {
				class: "org.h2.Driver",
				bundleName: "org.h2",
				host: "",
				port: "",
				username: "root"
			},
			sqlite: {
				class: "org.sqlite.JDBC",
				bundleName: "org.xerial.sqlite-jdbc",
				host: "",
				port: "",
				username: ""
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
	private string function buildConnectionString(required string dbType, required string host, required string port, required string database, string sid = "", string servicename = "", string oracleConnectionType = "sid") {
		switch (arguments.dbType) {
			case "MySQL":
				return "jdbc:mysql://#arguments.host#:#arguments.port#/#arguments.database#?characterEncoding=UTF-8&serverTimezone=UTC&maxReconnects=3";
			case "PostgreSQL":
			case "Postgre":
			case "Postgres":
				return "jdbc:postgresql://#arguments.host#:#arguments.port#/#arguments.database#";
			case "MSSQLServer":
				return "jdbc:sqlserver://#arguments.host#:#arguments.port#;DATABASENAME=#arguments.database#;trustServerCertificate=true;SelectMethod=direct";
			case "Oracle":
				if (arguments.oracleConnectionType == "servicename") {
					return "jdbc:oracle:thin:@#arguments.host#:#arguments.port#/#arguments.servicename#";
				} else {
					return "jdbc:oracle:thin:@#arguments.host#:#arguments.port#:#arguments.sid#";
				}
			case "H2":
				local.appPath = getCWD();
				return "jdbc:h2:#local.appPath#db/h2/#arguments.database#;MODE=MySQL";
			case "SQLite":
				local.appPath = getCWD();
				// Ensure path uses forward slashes and is properly formatted
				local.cleanPath = replace(local.appPath, "\", "/", "all");
				// Remove trailing slash if present
				if (right(local.cleanPath, 1) == "/") {
					local.cleanPath = left(local.cleanPath, len(local.cleanPath) - 1);
				}
				local.dbFilePath = local.cleanPath & "/db/" & arguments.database & ".db";
				return "jdbc:sqlite:" & local.dbFilePath;
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
				detailOutput.statusFailed("app.cfm not found at: #local.appCfmPath#");
				return false;
			}

			local.content = fileRead(local.appCfmPath);

			// Build datasource definition
			local.dsDefinition = '
	this.datasources["#arguments.dsName#"] = {
		class: "#arguments.dsConfig.class#",
		bundleName: "#arguments.dsConfig.bundleName#",
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
				detailOutput.statusWarning("Datasource already exists in app.cfm - skipping");
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
			detailOutput.statusSuccess("Datasource added to app.cfm");
			return true;

		} catch (any e) {
			detailOutput.statusFailed("Error saving to app.cfm: #e.message#");
			return false;
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
				detailOutput.statusWarning("Environment files not found for: #arguments.environment#");
				print.line("Creating environment configuration...").toConsole();

				// Call wheels env setup with skipDatabase to avoid infinite loop
				command("wheels env setup")
				.params(
					environment = arguments.environment,
					dbtype = normalizeDbType(arguments.dbType),
					datasource = arguments.datasource,
					database = arguments.dsInfo.database,
					host = arguments.dsInfo.host ?: "localhost",
					port = arguments.dsInfo.port ?: "",
					username = arguments.dsInfo.username ?: "root",
					password = arguments.dsInfo.password ?: "",
					sid = arguments.dsInfo.sid ?: "",
					servicename = arguments.dsInfo.servicename ?: "",
					oracleConnectionType = arguments.dsInfo.oracleConnectionType ?: "sid",
					skipDatabase = true
				)
					.run();

				detailOutput.statusSuccess("Environment configuration created!");
			}

		} catch (any e) {
			detailOutput.statusWarning("Could not create environment setup: #e.message#");
			detailOutput.statusWarning("You may need to run: wheels env setup environment=#arguments.environment#");
		}
	}

	/**
	 * Write datasource to app.cfm using environment variables
	 * This is called AFTER database creation to ensure .env files exist first
	 */
	private void function writeDatasourceToAppCfmWithEnvVars(required string appPath, required string datasourceName, required string dbType, required string environment) {
		try {
			print.line("Writing datasource to app.cfm...").toConsole();

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
				detailOutput.statusSuccess(local.result.message);
			} else {
				detailOutput.statusWarning(local.result.message);
			}

		} catch (any e) {
			detailOutput.statusWarning("Could not write datasource to app.cfm: #e.message#");
			detailOutput.statusWarning("You may need to manually add the datasource configuration");
		}
	}

	/**
	 * Create SQLite database (file-based)
	 */
	private void function createSQLiteDatabase(required struct dsInfo, required string dbName, boolean force = false) {
		try {
			print.line("Creating SQLite database...").toConsole();

			// Get the database path from dsInfo
			// dsInfo.database might be:
			// 1. Full JDBC connection string: "jdbc:sqlite:/path/to/db.db"
			// 2. Just the database name: "wheels_dev"
			local.databaseValue = arguments.dsInfo.database;
			local.dbPath = "";

			if (findNoCase("jdbc:sqlite:", local.databaseValue) == 1) {
				// It's a full JDBC connection string - extract the file path
				local.dbPath = mid(local.databaseValue, 14, len(local.databaseValue));
			} else {
				// It's just the database name - build the absolute path
				local.appPath = getCWD();
				local.cleanPath = replace(local.appPath, "\", "/", "all");
				// Remove trailing slash if present
				if (right(local.cleanPath, 1) == "/") {
					local.cleanPath = left(local.cleanPath, len(local.cleanPath) - 1);
				}
				// Build absolute path to database file
				local.dbPath = local.cleanPath & "/db/" & local.databaseValue & ".db";
			}
			// Normalize path separators to forward slashes
			local.dbPath = replace(local.dbPath, "\", "/", "all");

			// Check if database file already exists
			if (FileExists(local.dbPath)) {
				if (!arguments.force) {
					throw(message="Database file '#local.dbPath#' already exists! Use force=true to overwrite.");
				}

				detailOutput.statusWarning("Database file already exists: #local.dbPath#");
				print.line("Removing existing database file...").toConsole();

				// Delete auxiliary files first
				local.walFile = local.dbPath & "-wal";
				local.shmFile = local.dbPath & "-shm";
				local.journalFile = local.dbPath & "-journal";

				if (FileExists(local.walFile)) {
					try {
						FileDelete(local.walFile);
						detailOutput.statusSuccess("Deleted WAL file");
					} catch (any e) {
						detailOutput.statusWarning("Could not delete WAL file: #e.message#");
					}
				}

				if (FileExists(local.shmFile)) {
					try {
						FileDelete(local.shmFile);
						detailOutput.statusSuccess("Deleted SHM file");
					} catch (any e) {
						detailOutput.statusWarning("Could not delete SHM file: #e.message#");
					}
				}

				if (FileExists(local.journalFile)) {
					try {
						FileDelete(local.journalFile);
						detailOutput.statusSuccess("Deleted journal file");
					} catch (any e) {
						detailOutput.statusWarning("Could not delete journal file: #e.message#");
					}
				}

				// Delete main database file
				try {
					FileDelete(local.dbPath);
					detailOutput.statusSuccess("Deleted existing database file");
				} catch (any e) {
					throw(message="Could not delete existing database file: " & e.message, detail="Try stopping the application server first.");
				}
			}

			// Ensure parent directory exists
			local.dbDir = getDirectoryFromPath(local.dbPath);
			if (!directoryExists(local.dbDir)) {
				directoryCreate(local.dbDir, true);
				detailOutput.statusSuccess("Created database directory: #local.dbDir#");
			}

			// Create the SQLite database by establishing a connection and creating a table
			print.line("Initializing SQLite database file...").toConsole();

			// Load SQLite JDBC driver
			local.driver = "";
			try {
				local.driver = createObject("java", "org.sqlite.JDBC");
				detailOutput.statusSuccess("SQLite JDBC driver loaded");
			} catch (any e) {
				throw(message="SQLite JDBC driver not found. Ensure org.xerial.sqlite-jdbc is in classpath.");
			}

			// Create connection string
			local.connectionString = "jdbc:sqlite:" & local.dbPath;

			// Create properties for connection
			local.props = createObject("java", "java.util.Properties");

			// Connect to SQLite (this creates the file)
			local.conn = local.driver.connect(local.connectionString, local.props);

			if (isNull(local.conn)) {
				throw(message="Failed to create SQLite database connection");
			}

			detailOutput.statusSuccess("Database connection established");

			// Create a metadata table to initialize the database
			print.line("Initializing database schema...").toConsole();
			local.stmt = local.conn.createStatement();
			local.createTableSQL = "CREATE TABLE IF NOT EXISTS wheels_metadata (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				key TEXT NOT NULL UNIQUE,
				value TEXT,
				createdat DATETIME DEFAULT CURRENT_TIMESTAMP,
				updatedat DATETIME DEFAULT CURRENT_TIMESTAMP
			)";
			local.stmt.execute(local.createTableSQL);

			// Insert initial metadata
			local.insertSQL = "INSERT INTO wheels_metadata (key, value) VALUES ('database_created', datetime('now'))";
			local.stmt.execute(local.insertSQL);

			detailOutput.statusSuccess("Database schema initialized");

			// Close statement and connection
			local.stmt.close();
			local.conn.close();

			// Verify file was created
			if (FileExists(local.dbPath)) {
				local.fileInfo = getFileInfo(local.dbPath);
				detailOutput.statusSuccess("Database file created: #local.dbPath#");
				detailOutput.metric("File size", "#local.fileInfo.size# bytes");

				detailOutput.divider();
				detailOutput.success("SQLite database created successfully!");
			} else {
				throw(message="Database file was not created at: #local.dbPath#");
			}

		} catch (any e) {
			// Handle SQLite-specific errors
			handleSQLiteError(e, arguments.dbName);
		}
	}

	/**
	 * Handle SQLite-specific errors
	 */
	private void function handleSQLiteError(required any e, required string dbName) {
		local.errorHandled = false;
		local.errorMessage = arguments.e.message;

		// Check for common SQLite error patterns
		if (FindNoCase("already exists", local.errorMessage)) {
			detailOutput.statusFailed("Database file already exists: #arguments.dbName#.db");
			detailOutput.statusWarning("Use force=true to overwrite the existing database");
			local.errorHandled = true;
		} else if (FindNoCase("Could not delete", local.errorMessage)) {
			detailOutput.statusFailed("Cannot delete existing database file");
			detailOutput.statusWarning("The database file may be locked by another process");
			detailOutput.statusWarning("Try stopping the application server and running the command again");
			local.errorHandled = true;
		} else if (FindNoCase("driver not found", local.errorMessage) ||
		           FindNoCase("JDBC driver", local.errorMessage)) {
			detailOutput.statusFailed("SQLite JDBC driver not found");
			detailOutput.statusWarning("SQLite requires the org.xerial.sqlite-jdbc driver in the classpath");
			detailOutput.line();
			detailOutput.output("SQLite JDBC Driver Installation:");
			detailOutput.output("1. SQLite driver should be included with CommandBox/Lucee");
			detailOutput.output("2. If missing, ensure org.xerial.sqlite-jdbc bundle is installed");
			detailOutput.output("3. Try restarting CommandBox completely");
			detailOutput.output("4. Check that the driver is in the CommandBox lib directory");
			detailOutput.line();
			local.errorHandled = true;
		} else if (FindNoCase("Failed to create", local.errorMessage)) {
			detailOutput.statusFailed("Failed to create SQLite database connection");
			detailOutput.statusWarning("Check that the db directory exists and is writable");
			local.errorHandled = true;
		} else if (FindNoCase("Permission denied", local.errorMessage) ||
		           FindNoCase("Access is denied", local.errorMessage)) {
			detailOutput.statusFailed("Permission denied when creating database file");
			detailOutput.statusWarning("Ensure the application has write permissions to the db directory");
			local.errorHandled = true;
		} else if (FindNoCase("database is locked", local.errorMessage)) {
			detailOutput.statusFailed("Database is locked by another process");
			detailOutput.statusWarning("Close any applications that may be accessing the database file");
			local.errorHandled = true;
		}

		// If error wasn't specifically handled, show generic error
		if (!local.errorHandled) {
			detailOutput.statusFailed("SQLite Error: #local.errorMessage#");
		}

		// Show detail if available
		if (StructKeyExists(arguments.e, "detail") && Len(arguments.e.detail)) {
			detailOutput.output("Details: #arguments.e.detail#", true);
		}

		// Always throw to propagate the error up
		throw(message=arguments.e.message, detail=(StructKeyExists(arguments.e, "detail") ? arguments.e.detail : ""));
	}

	/**
	 * Get CommandBox Home directory by running info --json command
	 * Returns CLIHome path or empty string if not found
	 */
	private string function getCommandBoxHome() {
		local.infoResult = command("info").params(json=true).run(returnOutput=true);
		local.cleanResult = reReplace(
			local.infoResult,
			"\x1B\[[0-9;]*[A-Za-z]",
			"",
			"all"
		);

		local.cleanResult = trim( local.cleanResult );
		
		// Parse JSON response to extract CLIHome
		if (isJSON(local.cleanResult)) {
			local.infoData = deserializeJSON(local.cleanResult);
			if (structKeyExists(local.infoData, "CLIHome") && len(local.infoData.CLIHome)) {
				return local.infoData.CLIHome;
			}
		}
		
		return "";
	}

	/**
	 * Format file path with proper separators for the user's OS
	 */
	private string function formatLibPath(required string homeDir) {
		if (!len(arguments.homeDir)) {
			return "path/to/CommandBox/lib";
		}
		
		// For Mac/Linux, use forward slashes
		if (server.os.name contains "mac" || server.os.name contains "linux" || server.os.name contains "unix") {
			return arguments.homeDir & "/lib";
		}
		
		// For Windows, use backslashes
		return arguments.homeDir & "\lib";
	}

	/**
	 * Normalize database type to CLI parameter format
	 * Converts internal database type names to lowercase short form expected by env setup
	 */
	private string function normalizeDbType(required string dbType) {
		switch (arguments.dbType) {
			case "MySQL":
			case "MySQL5":
				return "mysql";
			case "Postgre":
			case "Postgres":
			case "PostgreSQL":
				return "postgres";
			case "MSSQLServer":
			case "MSSQL":
				return "mssql";
			case "Oracle":
				return "oracle";
			case "H2":
				return "h2";
			case "SQLite":
				return "sqlite";
			default:
				// If already in lowercase format, return as-is
				return lCase(arguments.dbType);
		}
	}

}