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
		string environment = ""
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
				error("No datasource configured. Use datasource= parameter or set dataSourceName in settings.");
				return;
			}
			
			print.line();
			print.boldLine("Creating database for datasource: " & arguments.datasource);
			print.line("Environment: " & arguments.environment);
			print.line();
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource);
			
			if (StructIsEmpty(local.dsInfo)) {
				error("Datasource '" & arguments.datasource & "' not found in server configuration");
				print.line("Please create the datasource in your CFML server admin first.");
				return;
			}
			
			// Extract database name and connection info
			local.dbName = local.dsInfo.database;
			local.dbType = local.dsInfo.driver;
			
			print.line("Database Type: " & local.dbType);
			print.line("Database Name: " & local.dbName);
			print.line();
			
			// Create database based on type
			switch (local.dbType) {
				case "MySQL":
				case "MySQL5":
					createMySQLDatabase(local.dsInfo, local.dbName);
					break;
				case "PostgreSQL":
					createPostgreSQLDatabase(local.dsInfo, local.dbName);
					break;
				case "MSSQLServer":
				case "MSSQL":
					createSQLServerDatabase(local.dsInfo, local.dbName);
					break;
				case "H2":
					print.yellowLine("H2 databases are created automatically on first connection");
					print.greenLine("No action needed - database will be created when application starts");
					break;
				default:
					error("Database creation not supported for driver: " & local.dbType);
					print.line("Please create the database manually using your database management tools.");
			}
			
		} catch (any e) {
			error("Error creating database: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
		}
	}

	private struct function getDatasourceInfo(required string datasourceName) {
		try {
			// Try to get datasource info from application.cfc
			local.appPath = getCWD();
			local.appCfcPath = local.appPath & "/config/app.cfm";
			
			if (fileExists(local.appCfcPath)) {
				local.content = fileRead(local.appCfcPath);
				
				// Look for datasource definition in this.datasources['name']
				local.pattern = "this\.datasources\['#arguments.datasourceName#'\]\s*=\s*\{([^}]+)\}";
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
					
					// Extract driver class
					local.classMatch = reFindNoCase("class\s*:\s*'([^']+)'", local.dsDefinition, 1, true);
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
					
					// Extract connection string
					local.connMatch = reFindNoCase("connectionString\s*:\s*'([^']+)'", local.dsDefinition, 1, true);
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
					}
					
					// Extract username
					local.userMatch = reFindNoCase("username\s*[=:]\s*'([^']*)'", local.dsDefinition, 1, true);
					if (local.userMatch.pos[2] > 0) {
						local.dsInfo.username = mid(local.dsDefinition, local.userMatch.pos[2], local.userMatch.len[2]);
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

	private void function createMySQLDatabase(required struct dsInfo, required string dbName) {
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
				local.sql = "CREATE DATABASE IF NOT EXISTS `#arguments.dbName#` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
				local.stmt.executeUpdate(local.sql);
				
				print.greenLine("Database created successfully: " & arguments.dbName);
				print.line("Character set: utf8mb4");
				print.line("Collation: utf8mb4_unicode_ci");
				
			} finally {
				if (IsDefined("local.stmt")) local.stmt.close();
				if (IsDefined("local.conn")) local.conn.close();
			}
			
		} catch (any e) {
			if (FindNoCase("database exists", e.message)) {
				print.yellowLine("Database already exists: " & arguments.dbName);
			} else {
				rethrow;
			}
		}
	}

	private void function createPostgreSQLDatabase(required struct dsInfo, required string dbName) {
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
				// Check if database exists
				local.checkStmt = local.conn.prepareStatement(
					"SELECT 1 FROM pg_database WHERE datname = ?"
				);
				local.checkStmt.setString(1, arguments.dbName);
				local.rs = local.checkStmt.executeQuery();
				
				if (local.rs.next()) {
					print.yellowLine("Database already exists: " & arguments.dbName);
				} else {
					// Create database
					local.stmt = local.conn.createStatement();
					local.sql = 'CREATE DATABASE "#arguments.dbName#" ENCODING ''UTF8''';
					local.stmt.executeUpdate(local.sql);
					
					print.greenLine("Database created successfully: " & arguments.dbName);
					print.line("Encoding: UTF8");
				}
				
			} finally {
				if (IsDefined("local.rs")) local.rs.close();
				if (IsDefined("local.checkStmt")) local.checkStmt.close();
				if (IsDefined("local.stmt")) local.stmt.close();
				if (IsDefined("local.conn")) local.conn.close();
			}
			
		} catch (any e) {
			rethrow;
		}
	}

	private void function createSQLServerDatabase(required struct dsInfo, required string dbName) {
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
				// Check if database exists
				local.checkStmt = local.conn.prepareStatement(
					"SELECT 1 FROM sys.databases WHERE name = ?"
				);
				local.checkStmt.setString(1, arguments.dbName);
				local.rs = local.checkStmt.executeQuery();
				
				if (local.rs.next()) {
					print.yellowLine("Database already exists: " & arguments.dbName);
				} else {
					// Create database
					local.stmt = local.conn.createStatement();
					local.sql = "CREATE DATABASE [#arguments.dbName#]";
					local.stmt.executeUpdate(local.sql);
					
					print.greenLine("Database created successfully: " & arguments.dbName);
				}
				
			} finally {
				if (IsDefined("local.rs")) local.rs.close();
				if (IsDefined("local.checkStmt")) local.checkStmt.close();
				if (IsDefined("local.stmt")) local.stmt.close();
				if (IsDefined("local.conn")) local.conn.close();
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