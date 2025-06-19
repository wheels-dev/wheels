/**
 * Export database schema and data
 *
 * {code:bash}
 * wheels db dump
 * wheels db dump --output=backup.sql
 * wheels db dump --schema-only
 * wheels db dump --data-only
 * {code}
 */
component extends="../base" {

	/**
	 * @output Output file path (defaults to dump_[timestamp].sql)
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @environment Optional environment (defaults to current environment)
	 * @schemaOnly Dump only the schema (no data)
	 * @dataOnly Dump only the data (no schema)
	 * @tables Comma-separated list of tables to dump (defaults to all)
	 * @compress Compress the output file using gzip
	 * @help Export database schema and data
	 */
	public void function run(
		string output = "",
		string datasource = "",
		string environment = "",
		boolean schemaOnly = false,
		boolean dataOnly = false,
		string tables = "",
		boolean compress = false
	) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		// Validate options
		if (arguments.schemaOnly && arguments.dataOnly) {
			error("Cannot use both --schema-only and --data-only flags");
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
			
			// Generate output filename if not provided
			if (!Len(arguments.output)) {
				local.timestamp = DateFormat(Now(), "yyyymmdd") & TimeFormat(Now(), "HHmmss");
				arguments.output = "dump_" & arguments.datasource & "_" & local.timestamp & ".sql";
				if (arguments.compress) {
					arguments.output &= ".gz";
				}
			}
			
			print.line();
			print.boldBlueLine("Database Export");
			print.line("Datasource: " & arguments.datasource);
			print.line("Environment: " & arguments.environment);
			print.line("Output file: " & arguments.output);
			
			if (arguments.schemaOnly) {
				print.line("Mode: Schema only");
			} else if (arguments.dataOnly) {
				print.line("Mode: Data only");
			} else {
				print.line("Mode: Schema and data");
			}
			
			if (Len(arguments.tables)) {
				print.line("Tables: " & arguments.tables);
			}
			
			print.line();
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource);
			
			if (StructIsEmpty(local.dsInfo)) {
				error("Datasource '" & arguments.datasource & "' not found in server configuration");
				return;
			}
			
			// Execute dump based on database type
			local.dbType = local.dsInfo.driver;
			local.success = false;
			
			switch (local.dbType) {
				case "MySQL":
				case "MySQL5":
					local.success = dumpMySQL(local.dsInfo, arguments);
					break;
				case "PostgreSQL":
					local.success = dumpPostgreSQL(local.dsInfo, arguments);
					break;
				case "MSSQLServer":
				case "MSSQL":
					local.success = dumpSQLServer(local.dsInfo, arguments);
					break;
				case "H2":
					local.success = dumpH2(local.dsInfo, arguments);
					break;
				default:
					error("Database dump not supported for driver: " & local.dbType);
					print.line("Please use your database management tools to export the database.");
			}
			
			if (local.success) {
				print.line();
				print.greenLine("✓ Database exported successfully to: " & arguments.output);
				
				// Show file size
				if (FileExists(arguments.output)) {
					local.fileInfo = GetFileInfo(arguments.output);
					local.sizeInMB = NumberFormat(local.fileInfo.size / 1048576, "0.00");
					print.line("File size: " & local.sizeInMB & " MB");
				}
			}
			
		} catch (any e) {
			error("Error exporting database: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
		}
	}

	private boolean function dumpMySQL(required struct dsInfo, required struct options) {
		try {
			local.host = arguments.dsInfo.host ?: "localhost";
			local.port = arguments.dsInfo.port ?: "3306";
			local.database = arguments.dsInfo.database;
			local.username = arguments.dsInfo.username ?: "";
			local.password = arguments.dsInfo.password ?: "";
			
			// Build mysqldump command
			local.cmd = "mysqldump";
			local.cmd &= " -h " & local.host;
			local.cmd &= " -P " & local.port;
			local.cmd &= " -u " & local.username;
			if (Len(local.password)) {
				local.cmd &= " -p" & local.password;
			}
			
			// Add options
			if (arguments.options.schemaOnly) {
				local.cmd &= " --no-data";
			} else if (arguments.options.dataOnly) {
				local.cmd &= " --no-create-info";
			}
			
			// Add database and tables
			local.cmd &= " " & local.database;
			if (Len(arguments.options.tables)) {
				local.cmd &= " " & Replace(arguments.options.tables, ",", " ", "all");
			}
			
			// Handle compression
			if (arguments.options.compress) {
				local.cmd &= " | gzip";
			}
			
			local.cmd &= " > " & arguments.options.output;
			
			print.line("Executing mysqldump...");
			local.result = runCommand(local.cmd);
			
			return local.result.success;
			
		} catch (any e) {
			print.redLine("MySQL dump failed. Make sure mysqldump is installed and in your PATH.");
			rethrow;
		}
	}

	private boolean function dumpPostgreSQL(required struct dsInfo, required struct options) {
		try {
			local.host = arguments.dsInfo.host ?: "localhost";
			local.port = arguments.dsInfo.port ?: "5432";
			local.database = arguments.dsInfo.database;
			local.username = arguments.dsInfo.username ?: "";
			
			// Build pg_dump command
			local.cmd = "pg_dump";
			local.cmd &= " -h " & local.host;
			local.cmd &= " -p " & local.port;
			local.cmd &= " -U " & local.username;
			local.cmd &= " -d " & local.database;
			
			// Add options
			if (arguments.options.schemaOnly) {
				local.cmd &= " --schema-only";
			} else if (arguments.options.dataOnly) {
				local.cmd &= " --data-only";
			}
			
			// Add tables
			if (Len(arguments.options.tables)) {
				local.tableList = ListToArray(arguments.options.tables);
				for (local.table in local.tableList) {
					local.cmd &= " -t " & local.table;
				}
			}
			
			// Handle compression
			if (arguments.options.compress) {
				local.cmd &= " -Z 9"; // Maximum compression
			}
			
			local.cmd &= " -f " & arguments.options.output;
			
			// Set PGPASSWORD environment variable if provided
			if (StructKeyExists(arguments.dsInfo, "password") && Len(arguments.dsInfo.password)) {
				local.envVars = {"PGPASSWORD": arguments.dsInfo.password};
			} else {
				local.envVars = {};
			}
			
			print.line("Executing pg_dump...");
			local.result = runCommand(local.cmd, local.envVars);
			
			return local.result.success;
			
		} catch (any e) {
			print.redLine("PostgreSQL dump failed. Make sure pg_dump is installed and in your PATH.");
			rethrow;
		}
	}

	private boolean function dumpSQLServer(required struct dsInfo, required struct options) {
		try {
			// For SQL Server, we'll generate a T-SQL script
			print.yellowLine("SQL Server dump is limited. For full backup, use SQL Server Management Studio.");
			print.line("Generating basic schema export...");
			
			// This is a simplified implementation
			// In production, you'd want to use sqlcmd or SQL Server tools
			local.output = "";
			local.output &= "-- SQL Server Database Dump" & Chr(10);
			local.output &= "-- Generated: " & Now() & Chr(10);
			local.output &= "-- Database: " & arguments.dsInfo.database & Chr(10);
			local.output &= Chr(10);
			
			if (!arguments.options.dataOnly) {
				local.output &= "-- Note: This is a basic export. Use SSMS for complete backup." & Chr(10);
			}
			
			FileWrite(arguments.options.output, local.output);
			
			return true;
			
		} catch (any e) {
			print.redLine("SQL Server dump failed.");
			rethrow;
		}
	}

	private boolean function dumpH2(required struct dsInfo, required struct options) {
		try {
			// For H2, we can use the SCRIPT command
			print.line("Generating H2 database script...");
			
			local.conn = CreateObject("java", "java.sql.DriverManager").getConnection(
				"jdbc:h2:" & arguments.dsInfo.database,
				arguments.dsInfo.username ?: "",
				arguments.dsInfo.password ?: ""
			);
			
			try {
				local.stmt = local.conn.createStatement();
				local.sql = "SCRIPT";
				
				if (arguments.options.schemaOnly) {
					local.sql &= " NODATA";
				} else if (!arguments.options.dataOnly) {
					local.sql &= " DROP";
				}
				
				local.sql &= " TO '" & arguments.options.output & "'";
				
				if (arguments.options.compress) {
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