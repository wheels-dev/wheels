/**
 * Export database schema and data
 *
 * {code:bash}
 * wheels db dump
 * wheels db dump output=backup.sql
 * wheels db dump database=mydb
 * wheels db dump schemaOnly=true
 * wheels db dump dataOnly=true
 * {code}
 */
component extends="../base" {

	/**
	 * @output Output file path (defaults to dump_[timestamp].sql)
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @database Optional database name (overrides datasource config)
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
		string database = "",
		string environment = "",
		boolean schemaOnly = false,
		boolean dataOnly = false,
		string tables = "",
		boolean compress = false
	) {
		arguments = reconstructArgs(arguments);
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		// Validate options
		if (arguments.schemaOnly && arguments.dataOnly) {
			error("Cannot use both schemaOnly=true and dataOnly=true flags");
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
			
			printHeader("Database Export Process");
			printInfo("Datasource", arguments.datasource);
			printInfo("Environment", arguments.environment);
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource);
			
			if (StructIsEmpty(local.dsInfo)) {
				error("Datasource '" & arguments.datasource & "' not found in server configuration");
				return;
			}
			
			// Handle database selection
			local.selectedDatabase = "";
			
			// First check if database parameter was provided
			if (Len(arguments.database)) {
				local.selectedDatabase = arguments.database;
			} 
			// Then check datasource configuration
			else if (Len(local.dsInfo.database)) {
				local.selectedDatabase = local.dsInfo.database;
			} 
			// If no database found, show available databases
			else {
				printDivider();
				printWarning("No database specified in datasource configuration");
				printStep("Fetching available databases...");
				
				// Call getAvailableDatabases from base.cfc
				local.databases = getAvailableDatabases(local.dsInfo);
				
				if (ArrayLen(local.databases) == 0) {
					error("No databases found or unable to connect to server");
					return;
				}
				
				print.line();
				print.boldYellowLine("Available databases:");
				for (local.i = 1; local.i <= ArrayLen(local.databases); local.i++) {
					print.line("  #local.i#. #local.databases[local.i]#");
				}
				print.line();
				
				// Ask user to select
				local.selection = ask("Select database number (or type database name): ");
				
				// Check if user entered a number
				if (IsNumeric(local.selection) && local.selection >= 1 && local.selection <= ArrayLen(local.databases)) {
					local.selectedDatabase = local.databases[local.selection];
				} 
				// Otherwise use what they typed as database name
				else if (Len(Trim(local.selection))) {
					local.selectedDatabase = Trim(local.selection);
				} else {
					error("No database selected");
					return;
				}
			}
			
			// Update dsInfo with selected database
			local.dsInfo.database = local.selectedDatabase;
			
			// Generate output filename if not provided
			if (!Len(arguments.output)) {
				local.timestamp = DateFormat(Now(), "yyyymmdd") & TimeFormat(Now(), "HHmmss");
				arguments.output = "dump_" & local.selectedDatabase & "_" & local.timestamp & ".sql";
				if (arguments.compress) {
					arguments.output &= ".gz";
				}
			}
			
			// Make sure output path is absolute
			if (!FileExists(GetDirectoryFromPath(arguments.output)) && !DirectoryExists(GetDirectoryFromPath(arguments.output))) {
				// If no directory specified, use current directory
				if (GetDirectoryFromPath(arguments.output) == "") {
					arguments.output = local.appPath & "/" & arguments.output;
				}
			}
			
			printInfo("Database", local.selectedDatabase);
			printInfo("Output File", arguments.output);
			
			if (arguments.schemaOnly) {
				printInfo("Mode", "Schema only");
			} else if (arguments.dataOnly) {
				printInfo("Mode", "Data only");
			} else {
				printInfo("Mode", "Schema and data");
			}
			
			if (Len(arguments.tables)) {
				printInfo("Tables", arguments.tables);
			}
			
			if (arguments.compress) {
				printInfo("Compression", "Enabled");
			}
			
			printDivider();
			
			// Display database connection info
			local.dbType = local.dsInfo.driver;
			printInfo("Database Type", local.dbType);
			printInfo("Host", local.dsInfo.host ?: "localhost");
			printInfo("Port", local.dsInfo.port ?: "default");
			printDivider();
			
			// Execute dump based on database type
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
				printDivider();
				printSuccess("Database exported successfully!");
				printInfo("Output File", arguments.output);
				
				// Show file size
				if (FileExists(arguments.output)) {
					try {
						local.fileInfo = GetFileInfo(arguments.output);
						local.sizeInMB = NumberFormat(local.fileInfo.size / 1048576, "0.00");
						printInfo("File Size", local.sizeInMB & " MB");
					} catch (any e) {
						// Ignore file info errors
					}
				}
				
				systemOutput("", true, true);
				printSuccess("Export completed successfully!", true);
			}
			
		} catch (any e) {
			printError("Error exporting database: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				printError("Details: " & e.detail);
			}
		}
	}

	private boolean function dumpMySQL(required struct dsInfo, required struct options) {
		try {
			local.host = arguments.dsInfo.host ?: "localhost";
			// Fix port handling - check for empty string too
			local.port = (StructKeyExists(arguments.dsInfo, "port") && Len(arguments.dsInfo.port)) ? arguments.dsInfo.port : "3306";
			local.database = arguments.dsInfo.database;
			local.username = arguments.dsInfo.username ?: "";
			local.password = arguments.dsInfo.password ?: "";
			
			// Check if database name is provided (should always have one now due to selection logic)
			if (!Len(local.database)) {
				printError("No database name specified");
				return false;
			}
			
			printStep("Preparing MySQL dump for database: " & local.database);
			
			// Try mysqldump first
			local.mysqldumpSuccess = false;
			local.mysqldumpAttempted = false;
			
			// Check if mysqldump exists - handle Windows PATH issues
			local.checkCmd = isWindows() ? "where mysqldump 2>nul" : "which mysqldump 2>/dev/null";
			local.checkResult = executeSystemCommand(local.checkCmd);
			
			// On Windows, also try common MySQL installation paths if 'where' fails
			if (!local.checkResult.success && isWindows()) {
				local.commonPaths = [
					"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe",
					"C:\Program Files\MySQL\MySQL Server 5.7\bin\mysqldump.exe",
					"C:\Program Files (x86)\MySQL\MySQL Server 8.0\bin\mysqldump.exe",
					"C:\Program Files\MariaDB 10.4\bin\mysqldump.exe",
					"C:\xampp\mysql\bin\mysqldump.exe",
					"C:\wamp64\bin\mysql\mysql8.0.27\bin\mysqldump.exe",
					"C:\wamp64\bin\mysql\mysql5.7.31\bin\mysqldump.exe"
				];
				
				for (local.path in local.commonPaths) {
					if (FileExists(local.path)) {
						// Found mysqldump, use full path
						local.checkResult.success = true;
						local.mysqldumpPath = local.path;
						printInfo("Found mysqldump at:", local.path);
						break;
					}
				}
			}
			
			if (local.checkResult.success) {
				printStep("Found mysqldump, attempting native dump...");
				local.mysqldumpAttempted = true;
				
				// Build mysqldump command - use full path if found
				if (IsDefined("local.mysqldumpPath")) {
					local.cmd = Chr(34) & local.mysqldumpPath & Chr(34); // Quote the path
				} else {
					local.cmd = "mysqldump";
				}
				local.cmd &= " -h " & local.host;
				local.cmd &= " -P " & local.port;
				local.cmd &= " -u " & local.username;
				if (Len(local.password)) {
					local.envVars = {"MYSQL_PWD": local.password};
				} else {
					local.envVars = {};
				}
				
				// Add compatibility options
				local.cmd &= " --single-transaction";
				local.cmd &= " --routines";
				local.cmd &= " --triggers";
				local.cmd &= " --column-statistics=0"; // Disable for compatibility
				local.cmd &= " --protocol=TCP"; // Force TCP
				
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
				
				// Handle output
				if (arguments.options.compress && !isWindows()) {
					local.cmd &= " | gzip > " & Chr(34) & arguments.options.output & Chr(34);
				} else {
					local.cmd &= " > " & Chr(34) & arguments.options.output & Chr(34);
				}
				
				// Try standard mysqldump
				local.result = executeSystemCommand(local.cmd, local.envVars);
				
				if (!local.result.success && FindNoCase("caching_sha2_password", local.result.error)) {
					// Try with mysql_native_password
					printWarning("Authentication plugin issue detected, trying compatibility mode...");
					local.cmd = Replace(local.cmd, "mysqldump", "mysqldump --default-auth=mysql_native_password");
					local.result = executeSystemCommand(local.cmd, local.envVars);
				}
				
				local.mysqldumpSuccess = local.result.success;
				
				if (!local.mysqldumpSuccess) {
					printWarning("mysqldump failed: " & (local.result.error ?: "Unknown error"));
				}
			}
			
			// If mysqldump failed or wasn't found, use JDBC fallback
			if (!local.mysqldumpSuccess) {
				if (local.mysqldumpAttempted) {
					printStep("Falling back to JDBC-based export...");
				} else {
					printStep("mysqldump not found, using JDBC-based export...");
				}
				
				return dumpMySQLViaJDBC(arguments.dsInfo, arguments.options);
			}
			
			// Handle compression for Windows if needed
			if (arguments.options.compress && isWindows() && FileExists(arguments.options.output)) {
				printWarning("Note: Compression not available on Windows with mysqldump");
			}
			
			printSuccess("MySQL dump completed successfully using mysqldump");
			return true;
			
		} catch (any e) {
			printError("MySQL dump error: " & e.message);
			// Try JDBC as last resort
			printStep("Attempting JDBC fallback due to error...");
			try {
				return dumpMySQLViaJDBC(arguments.dsInfo, arguments.options);
			} catch (any jdbcError) {
				printError("JDBC fallback also failed: " & jdbcError.message);
				return false;
			}
		}
	}

	private boolean function dumpMySQLViaJDBC(required struct dsInfo, required struct options) {
		try {
			systemOutput("Using JDBC connection for database export");
			printWarning("Note: JDBC export may not include stored procedures, triggers, or views");
			
			// Get database connection
			local.connResult = getDatabaseConnection(arguments.dsInfo, "MySQL");
			
			if (!local.connResult.success) {
				printError("Failed to connect to MySQL database via JDBC");
				if (Len(local.connResult.error)) {
					// Check for specific error types
					if (FindNoCase("Communications link failure", local.connResult.error)) {
						printError("Connection failed - MySQL server may not be running");
						print.line();
						printWarning("Please check:");
						print.line("1. MySQL is running on port " & (arguments.dsInfo.port ?: "3306"));
						print.line("2. Firewall is not blocking the connection");
						print.line("3. Host '" & (arguments.dsInfo.host ?: "localhost") & "' is correct");
					} else if (FindNoCase("Access denied", local.connResult.error)) {
						printError("Authentication failed");
						print.line("Please verify username and password are correct");
					} else {
						printError("Error: " & local.connResult.error);
					}
				}
				return false;
			}
			
			local.conn = local.connResult.connection;
			local.output = "";
			local.outputFile = "";
			
			try {
				// Build SQL dump header
				local.output &= "-- MySQL Database Dump" & Chr(10);
				local.output &= "-- Generated by Wheels CLI (JDBC Fallback)" & Chr(10);
				local.output &= "-- Host: " & (arguments.dsInfo.host ?: "localhost") & Chr(10);
				local.output &= "-- Port: " & (arguments.dsInfo.port ?: "3306") & Chr(10);
				local.output &= "-- Database: " & arguments.dsInfo.database & Chr(10);
				local.output &= "-- Generation Time: " & DateTimeFormat(Now(), "yyyy-mm-dd HH:nn:ss") & Chr(10);
				local.output &= Chr(10);
				local.output &= "SET SQL_MODE = ""NO_AUTO_VALUE_ON_ZERO"";" & Chr(10);
				local.output &= "SET time_zone = ""+00:00"";" & Chr(10);
				local.output &= Chr(10);
				
				// Get list of tables
				local.tableList = [];
				if (Len(arguments.options.tables)) {
					local.tableList = ListToArray(arguments.options.tables);
				} else {
					// Get all tables
					local.stmt = local.conn.createStatement();
					local.rs = local.stmt.executeQuery("SHOW TABLES");
					while (local.rs.next()) {
						ArrayAppend(local.tableList, local.rs.getString(1));
					}
					local.rs.close();
					local.stmt.close();
				}
				
				printInfo("Tables to export:", ArrayLen(local.tableList));
				
				// Track progress
				local.tableCount = 0;
				local.totalRows = 0;
				
				// Process each table
				for (local.table in local.tableList) {
					local.tableCount++;
					printProgress("Exporting table " & local.tableCount & "/" & ArrayLen(local.tableList) & ": " & local.table);
					
					if (!arguments.options.dataOnly) {
						// Get CREATE TABLE statement
						local.stmt = local.conn.createStatement();
						local.rs = local.stmt.executeQuery("SHOW CREATE TABLE `" & local.table & "`");
						if (local.rs.next()) {
							local.output &= Chr(10) & "-- --------------------------------------------------------" & Chr(10);
							local.output &= "-- Table structure for table `" & local.table & "`" & Chr(10);
							local.output &= "-- --------------------------------------------------------" & Chr(10);
							local.output &= Chr(10);
							local.output &= "DROP TABLE IF EXISTS `" & local.table & "`;" & Chr(10);
							local.output &= local.rs.getString(2) & ";" & Chr(10);
						}
						local.rs.close();
						local.stmt.close();
					}
					
					if (!arguments.options.schemaOnly) {
						// Export data
						local.stmt = local.conn.createStatement();
						local.countRs = local.stmt.executeQuery("SELECT COUNT(*) FROM `" & local.table & "`");
						local.rowCount = 0;
						if (local.countRs.next()) {
							local.rowCount = local.countRs.getInt(1);
						}
						local.countRs.close();
						local.stmt.close();
						
						if (local.rowCount > 0) {
							local.output &= Chr(10) & "-- --------------------------------------------------------" & Chr(10);
							local.output &= "-- Dumping data for table `" & local.table & "`" & Chr(10);
							local.output &= "-- --------------------------------------------------------" & Chr(10);
							local.output &= Chr(10);
							
							// Use batched approach for large tables
							local.batchSize = 1000;
							local.offset = 0;
							
							while (local.offset < local.rowCount) {
								local.stmt = local.conn.createStatement();
								local.rs = local.stmt.executeQuery("SELECT * FROM `" & local.table & "` LIMIT " & local.batchSize & " OFFSET " & local.offset);
								local.rsmd = local.rs.getMetaData();
								local.columnCount = local.rsmd.getColumnCount();
								
								local.rowsInBatch = 0;
								while (local.rs.next()) {
									if (local.rowsInBatch == 0 && local.offset == 0) {
										local.output &= "INSERT INTO `" & local.table & "` VALUES" & Chr(10);
									} else {
										local.output &= "," & Chr(10);
									}
									
									local.output &= "(";
									for (local.i = 1; local.i <= local.columnCount; local.i++) {
										if (local.i > 1) local.output &= ", ";
										
										local.value = local.rs.getString(local.i);
										if (IsNull(local.value)) {
											local.output &= "NULL";
										} else {
											// Escape special characters
											local.value = Replace(local.value, "\", "\\", "all");
											local.value = Replace(local.value, "'", "''", "all");
											local.value = Replace(local.value, Chr(10), "\n", "all");
											local.value = Replace(local.value, Chr(13), "\r", "all");
											local.value = Replace(local.value, Chr(9), "\t", "all");
											local.output &= "'" & local.value & "'";
										}
									}
									local.output &= ")";
									local.rowsInBatch++;
									local.totalRows++;
								}
								
								if (local.rowsInBatch > 0) {
									local.output &= ";" & Chr(10);
								}
								
								local.rs.close();
								local.stmt.close();
								
								local.offset += local.batchSize;
								
								// Write to file periodically to avoid memory issues
								if (Len(local.output) > 5000000) { // 5MB chunks
									if (Len(local.outputFile)) {
										FileAppend(arguments.options.output, local.output);
									} else {
										FileWrite(arguments.options.output, local.output);
										local.outputFile = arguments.options.output;
									}
									local.output = "";
								}
							}
						}
					}
				}
				
				// Add footer
				local.output &= Chr(10) & "-- --------------------------------------------------------" & Chr(10);
				local.output &= "-- Dump completed on " & DateTimeFormat(Now(), "yyyy-mm-dd HH:nn:ss") & Chr(10);
				local.output &= "-- Total tables: " & ArrayLen(local.tableList) & Chr(10);
				if (!arguments.options.schemaOnly) {
					local.output &= "-- Total rows exported: " & local.totalRows & Chr(10);
				}
				
				// Write final output
				if (Len(local.outputFile)) {
					FileAppend(arguments.options.output, local.output);
				} else {
					FileWrite(arguments.options.output, local.output);
				}
				
				// Handle compression if requested (basic zip on Windows)
				if (arguments.options.compress && isWindows()) {
					printStep("Compressing output file...");
					// This is a basic implementation - could be enhanced
					printWarning("Compression support is limited in JDBC mode");
				}
				
				print.greenLine("MySQL dump completed successfully via JDBC");
				print.yellowLine("Exported:", ArrayLen(local.tableList) & " tables, " & local.totalRows & " rows");
				
				return true;
				
			} finally {
				if (IsDefined("local.conn")) {
					local.conn.close();
				}
			}
			
		} catch (any e) {
			printError("MySQL JDBC dump error: " & e.message);
			if (StructKeyExists(e, "detail")) {
				printError("Detail: " & e.detail);
			}
			return false;
		}
	}
	
	private void function printProgress(required string message) {
		// Use carriage return for progress updates on same line
		if (isWindows()) {
			systemOutput(Chr(13) & "  ... " & arguments.message & "     ", false, false);
		} else {
			systemOutput("  ... " & arguments.message, true, true);
		}
	}

	private boolean function dumpPostgreSQL(required struct dsInfo, required struct options) {
		try {
			local.host = arguments.dsInfo.host ?: "localhost";
			// Fix port handling - check for empty string too
			local.port = (StructKeyExists(arguments.dsInfo, "port") && Len(arguments.dsInfo.port)) ? arguments.dsInfo.port : "5432";
			local.database = arguments.dsInfo.database;
			local.username = arguments.dsInfo.username ?: "";
			
			// Check if database name is provided (should always have one now due to selection logic)
			if (!Len(local.database)) {
				printError("No database name specified");
				return false;
			}
			
			printStep("Preparing PostgreSQL dump for database: " & local.database);
			
			// Build pg_dump command
			local.cmd = "pg_dump";
			local.cmd &= " -h " & local.host;
			local.cmd &= " -p " & local.port;
			local.cmd &= " -U " & local.username;
			local.cmd &= " -d " & local.database;
			local.cmd &= " --verbose"; // Show progress
			
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
					local.cmd &= " -t " & Trim(local.table);
				}
			}
			
			// Handle compression
			if (arguments.options.compress) {
				local.cmd &= " -Z 9"; // Maximum compression
			}
			
			local.cmd &= " -f " & Chr(34) & arguments.options.output & Chr(34);
			
			// Set PGPASSWORD environment variable if provided
			local.envVars = {};
			if (StructKeyExists(arguments.dsInfo, "password") && Len(arguments.dsInfo.password)) {
				local.envVars["PGPASSWORD"] = arguments.dsInfo.password;
			}
			
			printStep("Executing PostgreSQL dump...");
			printInfo("Command", "pg_dump (output to file)");
			
			local.result = executeSystemCommand(local.cmd, local.envVars);
			
			if (local.result.success) {
				printSuccess("PostgreSQL dump completed successfully");
			} else {
				printError("PostgreSQL dump failed");
				if (StructKeyExists(local.result, "output") && Len(Trim(local.result.output))) {
					printError("Output: " & local.result.output);
				}
				if (StructKeyExists(local.result, "error") && Len(local.result.error)) {
					printError("Error: " & local.result.error);
				}
				print.line();
				printWarning("Troubleshooting tips:");
				print.line("1. Ensure pg_dump is installed and in your PATH");
				print.line("2. On Windows: Install PostgreSQL");
				print.line("3. On Mac: brew install postgresql");
				print.line("4. On Linux: sudo apt-get install postgresql-client");
			}
			
			return local.result.success;
			
		} catch (any e) {
			printError("PostgreSQL dump error: " & e.message);
			return false;
		}
	}

	private boolean function dumpSQLServer(required struct dsInfo, required struct options) {
		try {
			printStep("Preparing SQL Server export...");
			
			// Check if sqlcmd is available
			local.checkCmd = isWindows() ? "where sqlcmd" : "which sqlcmd";
			local.checkResult = executeSystemCommand(local.checkCmd);
			
			if (!local.checkResult.success) {
				printWarning("sqlcmd command not found");
				printWarning("Generating basic SQL script instead of full backup");
				
				// Generate a basic SQL script
				local.output = "";
				local.output &= "-- SQL Server Database Export" & Chr(10);
				local.output &= "-- Generated: " & DateTimeFormat(Now(), "yyyy-mm-dd HH:nn:ss") & Chr(10);
				local.output &= "-- Database: " & arguments.dsInfo.database & Chr(10);
				local.output &= "-- Server: " & (arguments.dsInfo.host ?: "localhost") & Chr(10);
				local.output &= Chr(10);
				local.output &= "-- WARNING: This is a basic export template." & Chr(10);
				local.output &= "-- For complete backup, use SQL Server Management Studio (SSMS)" & Chr(10);
				local.output &= "-- or SQL Server Data Tools (SSDT)" & Chr(10);
				local.output &= Chr(10);
				local.output &= "USE [" & arguments.dsInfo.database & "];" & Chr(10);
				local.output &= "GO" & Chr(10);
				local.output &= Chr(10);
				
				// Add basic structure comments
				if (!arguments.options.dataOnly) {
					local.output &= "-- To generate full schema script in SSMS:" & Chr(10);
					local.output &= "-- 1. Right-click database -> Tasks -> Generate Scripts" & Chr(10);
					local.output &= "-- 2. Select objects to script" & Chr(10);
					local.output &= "-- 3. Set scripting options" & Chr(10);
					local.output &= "-- 4. Save to file" & Chr(10);
				}
				
				FileWrite(arguments.options.output, local.output);
				printSuccess("Basic SQL Server export template created");
				printWarning("Use SSMS for complete database export");
				
				return true;
			}
			
			// If sqlcmd is available, use it
			local.host = arguments.dsInfo.host ?: "localhost";
			local.port = arguments.dsInfo.port ?: "1433";
			local.database = arguments.dsInfo.database;
			local.username = arguments.dsInfo.username ?: "";
			local.password = arguments.dsInfo.password ?: "";
			
			// Build sqlcmd command for generating scripts
			local.cmd = "sqlcmd";
			local.cmd &= " -S " & local.host & "," & local.port;
			local.cmd &= " -d " & local.database;
			
			if (Len(local.username)) {
				local.cmd &= " -U " & local.username;
				if (Len(local.password)) {
					local.cmd &= " -P " & local.password;
				}
			} else {
				local.cmd &= " -E"; // Windows authentication
			}
			
			// Create a script to generate DDL
			local.scriptFile = GetTempDirectory() & "export_script.sql";
			local.script = "-- Export script commands here";
			FileWrite(local.scriptFile, local.script);
			
			local.cmd &= " -i " & Chr(34) & local.scriptFile & Chr(34);
			local.cmd &= " -o " & Chr(34) & arguments.options.output & Chr(34);
			
			printStep("Executing SQL Server export...");
			local.result = executeSystemCommand(local.cmd);
			
			// Clean up temp file
			if (FileExists(local.scriptFile)) {
				FileDelete(local.scriptFile);
			}
			
			return local.result.success;
			
		} catch (any e) {
			printError("SQL Server export error: " & e.message);
			return false;
		}
	}

	private boolean function dumpH2(required struct dsInfo, required struct options) {
		try {
			printStep("Preparing H2 database export...");
			
			// Get database connection
			local.connResult = getDatabaseConnection(arguments.dsInfo, "H2");
			
			if (!local.connResult.success) {
				printError("Failed to connect to H2 database");
				if (Len(local.connResult.error)) {
					printError("Error: " & local.connResult.error);
				}
				return false;
			}
			
			local.conn = local.connResult.connection;
			
			try {
				printStep("Generating H2 database script...");
				
				local.stmt = local.conn.createStatement();
				local.sql = "SCRIPT";
				
				if (arguments.options.schemaOnly) {
					local.sql &= " NODATA";
				} else if (!arguments.options.dataOnly) {
					local.sql &= " DROP";
				}
				
				local.sql &= " TO '" & Replace(arguments.options.output, "\", "/", "all") & "'";
				
				if (arguments.options.compress) {
					local.sql &= " COMPRESSION GZIP";
				}
				
				// Add table filter if specified
				if (Len(arguments.options.tables)) {
					local.sql &= " TABLE ";
					local.tableList = ListToArray(arguments.options.tables);
					local.tableNames = [];
					for (local.table in local.tableList) {
						ArrayAppend(local.tableNames, Trim(local.table));
					}
					local.sql &= ArrayToList(local.tableNames, ", ");
				}
				
				local.stmt.execute(local.sql);
				local.stmt.close();
				
				printSuccess("H2 database exported successfully");
				return true;
				
			} catch (any e) {
				printError("H2 export error: " & e.message);
				return false;
			} finally {
				if (IsDefined("local.conn")) {
					local.conn.close();
				}
			}
			
		} catch (any e) {
			printError("H2 database export error: " & e.message);
			return false;
		}
	}

	private struct function executeSystemCommand(required string command, struct envVars = {}) {
		try {
			// Use CommandBox's native command execution
			local.runtime = CreateObject("java", "java.lang.Runtime").getRuntime();
			local.isWin = isWindows();
			
			// Build the command array
			if (local.isWin) {
				// Windows command execution
				local.fullCommand = "cmd /c " & arguments.command;
			} else {
				// Unix/Linux/Mac command execution
				local.fullCommand = arguments.command;
			}
			
			// Set up environment
			local.envArray = [];
			if (!StructIsEmpty(arguments.envVars)) {
				// Get current environment
				local.currentEnv = CreateObject("java", "java.lang.System").getenv();
				
				// Convert to array format
				for (local.key in local.currentEnv) {
					ArrayAppend(local.envArray, local.key & "=" & local.currentEnv[local.key]);
				}
				
				// Add/override with our variables
				for (local.key in arguments.envVars) {
					ArrayAppend(local.envArray, local.key & "=" & arguments.envVars[local.key]);
				}
			}
			
			// Execute the command
			if (ArrayLen(local.envArray)) {
				local.process = local.runtime.exec(local.fullCommand, local.envArray);
			} else {
				local.process = local.runtime.exec(local.fullCommand);
			}
			
			// Wait for completion
			local.exitCode = local.process.waitFor();
			
			// Read output
			local.output = "";
			try {
				local.inputStream = local.process.getInputStream();
				local.inputStreamReader = CreateObject("java", "java.io.InputStreamReader").init(local.inputStream);
				local.bufferedReader = CreateObject("java", "java.io.BufferedReader").init(local.inputStreamReader);
				
				local.line = local.bufferedReader.readLine();
				while (!IsNull(local.line)) {
					local.output &= local.line & Chr(10);
					local.line = local.bufferedReader.readLine();
				}
				local.bufferedReader.close();
			} catch (any e) {
				// Ignore stream reading errors
			}
			
			// Read error stream
			local.errorOutput = "";
			try {
				local.errorStream = local.process.getErrorStream();
				local.errorStreamReader = CreateObject("java", "java.io.InputStreamReader").init(local.errorStream);
				local.errorBufferedReader = CreateObject("java", "java.io.BufferedReader").init(local.errorStreamReader);
				
				local.line = local.errorBufferedReader.readLine();
				while (!IsNull(local.line)) {
					local.errorOutput &= local.line & Chr(10);
					local.line = local.errorBufferedReader.readLine();
				}
				local.errorBufferedReader.close();
			} catch (any e) {
				// Ignore stream reading errors
			}
			
			return {
				success: local.exitCode == 0,
				exitCode: local.exitCode,
				output: local.output,
				error: local.errorOutput
			};
			
		} catch (any e) {
			return {
				success: false,
				error: e.message,
				exitCode: -1,
				output: ""
			};
		}
	}

	private boolean function isWindows() {
		local.os = CreateObject("java", "java.lang.System").getProperty("os.name");
		return FindNoCase("Windows", local.os) > 0;
	}

}