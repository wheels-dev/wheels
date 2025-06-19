/**
 * Restore database from dump file
 *
 * {code:bash}
 * wheels db restore backup.sql
 * wheels db restore backup.sql.gz --compressed
 * wheels db restore backup.sql --clean
 * {code}
 */
component extends="../base" {

	/**
	 * @file Path to the dump file to restore
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @environment Optional environment (defaults to current environment)
	 * @clean Drop existing objects before restore
	 * @force Skip confirmation prompt
	 * @compressed File is compressed with gzip
	 * @help Restore database from dump file
	 */
	public void function run(
		required string file,
		string datasource = "",
		string environment = "",
		boolean clean = false,
		boolean force = false,
		boolean compressed = false
	) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		// Check if file exists
		if (!FileExists(arguments.file)) {
			error("Dump file not found: " & arguments.file);
			return;
		}

		// Auto-detect compression if not specified
		if (!arguments.compressed && (Right(arguments.file, 3) == ".gz" || Right(arguments.file, 4) == ".gzip")) {
			arguments.compressed = true;
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
			print.boldBlueLine("Database Restore");
			print.line("Datasource: " & arguments.datasource);
			print.line("Environment: " & arguments.environment);
			print.line("Input file: " & arguments.file);
			
			// Show file info
			local.fileInfo = GetFileInfo(arguments.file);
			local.sizeInMB = NumberFormat(local.fileInfo.size / 1048576, "0.00");
			print.line("File size: " & local.sizeInMB & " MB");
			
			if (arguments.compressed) {
				print.line("Compression: Yes");
			}
			
			if (arguments.clean) {
				print.yellowLine("Mode: Clean restore (existing objects will be dropped)");
			}
			
			print.line();
			
			// Warning for production
			if (arguments.environment == "production" && !arguments.force) {
				print.boldRedLine("⚠️  WARNING: Restoring to PRODUCTION environment!");
				print.line("This will overwrite existing data!");
				local.confirm = ask("Type 'restore production' to confirm: ");
				if (local.confirm != "restore production") {
					print.yellowLine("Restore cancelled.");
					return;
				}
			} else if (!arguments.force) {
				print.yellowLine("⚠️  This will overwrite existing data!");
				local.confirm = ask("Are you sure you want to restore? Type 'yes' to confirm: ");
				if (local.confirm != "yes") {
					print.yellowLine("Restore cancelled.");
					return;
				}
			}
			
			print.line();
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource);
			
			if (StructIsEmpty(local.dsInfo)) {
				error("Datasource '" & arguments.datasource & "' not found in server configuration");
				return;
			}
			
			// Execute restore based on database type
			local.dbType = local.dsInfo.driver;
			local.success = false;
			
			switch (local.dbType) {
				case "MySQL":
				case "MySQL5":
					local.success = restoreMySQL(local.dsInfo, arguments);
					break;
				case "PostgreSQL":
					local.success = restorePostgreSQL(local.dsInfo, arguments);
					break;
				case "MSSQLServer":
				case "MSSQL":
					local.success = restoreSQLServer(local.dsInfo, arguments);
					break;
				case "H2":
					local.success = restoreH2(local.dsInfo, arguments);
					break;
				default:
					error("Database restore not supported for driver: " & local.dbType);
					print.line("Please use your database management tools to import the database.");
			}
			
			if (local.success) {
				print.line();
				print.greenLine("✓ Database restored successfully from: " & arguments.file);
				
				// Show migration status
				print.line();
				print.line("Running 'wheels db status' to show current state:");
				command("wheels db status")
					.run();
			}
			
		} catch (any e) {
			error("Error restoring database: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
		}
	}

	private boolean function restoreMySQL(required struct dsInfo, required struct options) {
		try {
			local.host = arguments.dsInfo.host ?: "localhost";
			local.port = arguments.dsInfo.port ?: "3306";
			local.database = arguments.dsInfo.database;
			local.username = arguments.dsInfo.username ?: "";
			local.password = arguments.dsInfo.password ?: "";
			
			// Build mysql command
			local.cmd = "";
			
			// Handle decompression if needed
			if (arguments.options.compressed) {
				local.cmd = "gunzip -c " & arguments.options.file & " | ";
			}
			
			local.cmd &= "mysql";
			local.cmd &= " -h " & local.host;
			local.cmd &= " -P " & local.port;
			local.cmd &= " -u " & local.username;
			if (Len(local.password)) {
				local.cmd &= " -p" & local.password;
			}
			local.cmd &= " " & local.database;
			
			if (!arguments.options.compressed) {
				local.cmd &= " < " & arguments.options.file;
			}
			
			print.line("Executing mysql restore...");
			local.result = runCommand(local.cmd);
			
			return local.result.success;
			
		} catch (any e) {
			print.redLine("MySQL restore failed. Make sure mysql client is installed and in your PATH.");
			rethrow;
		}
	}

	private boolean function restorePostgreSQL(required struct dsInfo, required struct options) {
		try {
			local.host = arguments.dsInfo.host ?: "localhost";
			local.port = arguments.dsInfo.port ?: "5432";
			local.database = arguments.dsInfo.database;
			local.username = arguments.dsInfo.username ?: "";
			
			// Build psql command
			local.cmd = "psql";
			local.cmd &= " -h " & local.host;
			local.cmd &= " -p " & local.port;
			local.cmd &= " -U " & local.username;
			local.cmd &= " -d " & local.database;
			
			if (arguments.options.clean) {
				local.cmd &= " -c";
			}
			
			local.cmd &= " -f " & arguments.options.file;
			
			// Set PGPASSWORD environment variable if provided
			if (StructKeyExists(arguments.dsInfo, "password") && Len(arguments.dsInfo.password)) {
				local.envVars = {"PGPASSWORD": arguments.dsInfo.password};
			} else {
				local.envVars = {};
			}
			
			print.line("Executing psql restore...");
			local.result = runCommand(local.cmd, local.envVars);
			
			return local.result.success;
			
		} catch (any e) {
			print.redLine("PostgreSQL restore failed. Make sure psql is installed and in your PATH.");
			rethrow;
		}
	}

	private boolean function restoreSQLServer(required struct dsInfo, required struct options) {
		try {
			print.yellowLine("SQL Server restore is limited. For full restore, use SQL Server Management Studio.");
			print.line("You can execute the SQL file using SSMS or sqlcmd tool.");
			
			// Provide instructions
			print.line();
			print.line("To restore using sqlcmd:");
			print.line("sqlcmd -S " & (arguments.dsInfo.host ?: "localhost") & " -d " & arguments.dsInfo.database & " -i " & arguments.options.file);
			
			return false;
			
		} catch (any e) {
			print.redLine("SQL Server restore failed.");
			rethrow;
		}
	}

	private boolean function restoreH2(required struct dsInfo, required struct options) {
		try {
			// For H2, we can use the RUNSCRIPT command
			print.line("Restoring H2 database...");
			
			local.conn = CreateObject("java", "java.sql.DriverManager").getConnection(
				"jdbc:h2:" & arguments.dsInfo.database,
				arguments.dsInfo.username ?: "",
				arguments.dsInfo.password ?: ""
			);
			
			try {
				local.stmt = local.conn.createStatement();
				local.sql = "RUNSCRIPT FROM '" & arguments.options.file & "'";
				
				if (arguments.options.compressed) {
					local.sql &= " COMPRESSION GZIP";
				}
				
				local.stmt.execute(local.sql);
				
				return true;
				
			} finally {
				if (IsDefined("local.stmt")) local.stmt.close();
				if (IsDefined("local.conn")) local.conn.close();
			}
			
		} catch (any e) {
			rethrow;
		}
	}

	private struct function runCommand(required string command, struct envVars = {}) {
		try {
			// Set up process builder
			local.pb = CreateObject("java", "java.lang.ProcessBuilder");
			local.commandArray = ["sh", "-c", arguments.command];
			local.pb.init(local.commandArray);
			
			// Set environment variables
			if (!StructIsEmpty(arguments.envVars)) {
				local.env = local.pb.environment();
				for (local.key in arguments.envVars) {
					local.env.put(local.key, arguments.envVars[local.key]);
				}
			}
			
			// Execute command
			local.process = local.pb.start();
			local.exitCode = local.process.waitFor();
			
			return {
				success: local.exitCode == 0,
				exitCode: local.exitCode
			};
			
		} catch (any e) {
			return {
				success: false,
				error: e.message
			};
		}
	}

	private struct function getDatasourceInfo(required string datasourceName) {
		// Placeholder implementation
		return {};
	}

	private string function getEnvironment(required string appPath) {
		// Same implementation as other commands
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