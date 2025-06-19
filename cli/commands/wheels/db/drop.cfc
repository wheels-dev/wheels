/**
 * Drop an existing database
 *
 * {code:bash}
 * wheels db drop
 * wheels db drop --datasource=myapp_dev
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
		boolean force = false
	) {
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
				error("No datasource configured. Use --datasource parameter or set dataSourceName in settings.");
				return;
			}
			
			print.line();
			print.boldRedLine("⚠️  WARNING: This will permanently drop the database!");
			print.line("Datasource: " & arguments.datasource);
			print.line("Environment: " & arguments.environment);
			print.line();
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource);
			
			if (StructIsEmpty(local.dsInfo)) {
				error("Datasource '" & arguments.datasource & "' not found in server configuration");
				print.line("Please check your datasource configuration.");
				return;
			}
			
			// Extract database name
			local.dbName = local.dsInfo.database;
			local.dbType = local.dsInfo.driver;
			
			print.line("Database Type: " & local.dbType);
			print.line("Database Name: " & local.dbName);
			print.line();
			
			// Confirm unless forced
			if (!arguments.force) {
				local.confirm = ask("Are you sure you want to drop the database '#local.dbName#'? Type 'yes' to confirm: ");
				if (local.confirm != "yes") {
					print.yellowLine("Database drop cancelled.");
					return;
				}
			}
			
			// Drop database based on type
			switch (local.dbType) {
				case "MySQL":
				case "MySQL5":
					dropMySQLDatabase(local.dsInfo, local.dbName);
					break;
				case "PostgreSQL":
					dropPostgreSQLDatabase(local.dsInfo, local.dbName);
					break;
				case "MSSQLServer":
				case "MSSQL":
					dropSQLServerDatabase(local.dsInfo, local.dbName);
					break;
				case "H2":
					dropH2Database(local.dsInfo, local.dbName);
					break;
				default:
					error("Database drop not supported for driver: " & local.dbType);
					print.line("Please drop the database manually using your database management tools.");
			}
			
		} catch (any e) {
			error("Error dropping database: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
		}
	}

	private struct function getDatasourceInfo(required string datasourceName) {
		try {
			// Note: This is a placeholder - in a real implementation we would need to
			// query the server configuration or read from a datasource configuration file
			// For now, return empty struct which will prompt user to create datasource manually
			return {};
		} catch (any e) {
			// Server might not be running
		}
		return {};
	}

	private void function dropMySQLDatabase(required struct dsInfo, required string dbName) {
		try {
			// Create a temporary datasource without database specification
			local.tempDS = Duplicate(arguments.dsInfo);
			local.tempDS.database = "information_schema"; // Connect to system database
			
			// Create connection
			local.conn = CreateObject("java", "java.sql.DriverManager").getConnection(
				buildJDBCUrl(local.tempDS),
				local.tempDS.username ?: "",
				local.tempDS.password ?: ""
			);
			
			try {
				local.stmt = local.conn.createStatement();
				local.sql = "DROP DATABASE IF EXISTS `#arguments.dbName#`";
				local.stmt.executeUpdate(local.sql);
				
				print.greenLine("Database dropped successfully: " & arguments.dbName);
				
			} finally {
				if (IsDefined("local.stmt")) local.stmt.close();
				if (IsDefined("local.conn")) local.conn.close();
			}
			
		} catch (any e) {
			rethrow;
		}
	}

	private void function dropPostgreSQLDatabase(required struct dsInfo, required string dbName) {
		try {
			// Create a temporary datasource without database specification
			local.tempDS = Duplicate(arguments.dsInfo);
			local.tempDS.database = "postgres"; // Connect to system database
			
			// Create connection
			local.conn = CreateObject("java", "java.sql.DriverManager").getConnection(
				buildJDBCUrl(local.tempDS),
				local.tempDS.username ?: "",
				local.tempDS.password ?: ""
			);
			
			try {
				// Terminate existing connections to the database
				local.terminateStmt = local.conn.prepareStatement(
					"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = ? AND pid <> pg_backend_pid()"
				);
				local.terminateStmt.setString(1, arguments.dbName);
				local.terminateStmt.executeQuery();
				
				// Drop database
				local.stmt = local.conn.createStatement();
				local.sql = 'DROP DATABASE IF EXISTS "#arguments.dbName#"';
				local.stmt.executeUpdate(local.sql);
				
				print.greenLine("Database dropped successfully: " & arguments.dbName);
				
			} finally {
				if (IsDefined("local.terminateStmt")) local.terminateStmt.close();
				if (IsDefined("local.stmt")) local.stmt.close();
				if (IsDefined("local.conn")) local.conn.close();
			}
			
		} catch (any e) {
			rethrow;
		}
	}

	private void function dropSQLServerDatabase(required struct dsInfo, required string dbName) {
		try {
			// Create a temporary datasource without database specification
			local.tempDS = Duplicate(arguments.dsInfo);
			local.tempDS.database = "master"; // Connect to system database
			
			// Create connection
			local.conn = CreateObject("java", "java.sql.DriverManager").getConnection(
				buildJDBCUrl(local.tempDS),
				local.tempDS.username ?: "",
				local.tempDS.password ?: ""
			);
			
			try {
				// Set database to single user mode to close connections
				local.singleUserStmt = local.conn.createStatement();
				local.singleUserStmt.executeUpdate(
					"IF EXISTS (SELECT 1 FROM sys.databases WHERE name = '#arguments.dbName#') " &
					"ALTER DATABASE [#arguments.dbName#] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
				);
				
				// Drop database
				local.stmt = local.conn.createStatement();
				local.sql = "DROP DATABASE IF EXISTS [#arguments.dbName#]";
				local.stmt.executeUpdate(local.sql);
				
				print.greenLine("Database dropped successfully: " & arguments.dbName);
				
			} finally {
				if (IsDefined("local.singleUserStmt")) local.singleUserStmt.close();
				if (IsDefined("local.stmt")) local.stmt.close();
				if (IsDefined("local.conn")) local.conn.close();
			}
			
		} catch (any e) {
			rethrow;
		}
	}

	private void function dropH2Database(required struct dsInfo, required string dbName) {
		try {
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
				print.line("Deleted database file: " & local.dbFile);
			}
			
			if (FileExists(local.lockFile)) {
				FileDelete(local.lockFile);
				print.line("Deleted lock file: " & local.lockFile);
			}
			
			if (FileExists(local.traceFile)) {
				FileDelete(local.traceFile);
				print.line("Deleted trace file: " & local.traceFile);
			}
			
			if (local.filesDeleted) {
				print.greenLine("H2 database dropped successfully: " & arguments.dbName);
			} else {
				print.yellowLine("No H2 database files found for: " & arguments.dbName);
			}
			
		} catch (any e) {
			rethrow;
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
				return "jdbc:sqlserver://#local.host#:#local.port#;databaseName=#local.database#";
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
		local.pattern = 'set\s*\(\s*dataSourceName\s*=\s*["'']([^"'']+)["'']';
		local.match = REFind(local.pattern, arguments.content, 1, true);
		if (local.match.pos[1] > 0) {
			return Mid(arguments.content, local.match.pos[2], local.match.len[2]);
		}
		return "";
	}

}