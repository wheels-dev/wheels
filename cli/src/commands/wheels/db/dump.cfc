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
	 */

	property name="detailOutput" inject="detailOutputService@wheels-cli";
	
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
		local.appPath = getCWD();
		requireWheelsApp(local.appPath);
		arguments = reconstructArgs(arguments);

		// Validate options
		if (arguments.schemaOnly && arguments.dataOnly) {
			detailOutput.error("Cannot use both schemaOnly=true and dataOnly=true flags");
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
			
			detailOutput.header("Database Export Process");
			detailOutput.statusInfo("Datasource: #arguments.datasource#");
			detailOutput.statusInfo("Environment: #arguments.environment#");
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource, arguments.environment);

			if (StructIsEmpty(local.dsInfo)) {
				detailOutput.error("Datasource '" & arguments.datasource & "' not found in server configuration");
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
				detailOutput.divider();
				detailOutput.statusWarning("No database specified in datasource configuration");
				detailOutput.output("Fetching available databases...");
				
				// Call getAvailableDatabases from base.cfc
				local.databases = getAvailableDatabases(local.dsInfo);
				
				if (ArrayLen(local.databases) == 0) {
					detailOutput.error("No databases found or unable to connect to server");
					return;
				}
				
				detailOutput.line();
				detailOutput.output("Available databases:");
				for (local.i = 1; local.i <= ArrayLen(local.databases); local.i++) {
					detailOutput.output("#local.i#. #local.databases[local.i]#", true);
				}
				detailOutput.line();
				
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
					detailOutput.error("No database selected");
					return;
				}
			}
			
			// Update dsInfo with selected database
			local.dsInfo.database = local.selectedDatabase;
			
			// Generate output filename if not provided
			if (!Len(arguments.output)) {
				local.timestamp = DateFormat(Now(), "yyyymmdd") & TimeFormat(Now(), "HHmmss");
				arguments.output = fileSystemUtil.resolvePath("dump_" & local.selectedDatabase & "_" & local.timestamp & ".sql");
				if (arguments.compress) {
					arguments.output &= ".gz";
				}
			}
			
			// Make sure output path is absolute
			if (!FileExists((arguments.output)) && !DirectoryExists(fileSystemUtil.resolvePath(arguments.output))) {
				// If no directory specified, use current directory
				if (fileSystemUtil.resolvePath(arguments.output) == "") {
					arguments.output = local.appPath & "/" & arguments.output;
				}
			}

			
			detailOutput.statusInfo("Database: #local.selectedDatabase#");
			detailOutput.statusInfo("Output File: #arguments.output#");
			
			if (arguments.schemaOnly) {
				detailOutput.statusInfo("Mode: Schema only");
			} else if (arguments.dataOnly) {
				detailOutput.statusInfo("Mode: Data only");
			} else {
				detailOutput.statusInfo("Mode: Schema and data");
			}
			
			if (Len(arguments.tables)) {
				detailOutput.statusInfo("Tables: #arguments.tables#");
			}
			
			if (arguments.compress) {
				detailOutput.statusInfo("Compression: Enabled");
			}
			
			detailOutput.divider();
			
			// Display database connection info
			local.dbType = local.dsInfo.driver;
			local.dsInfo.host = local.dsInfo.host ?: "localhost";
			local.dsInfo.port = local.dsInfo.port ?: "default";
			detailOutput.statusInfo("Database Type: #local.dbType#");
			detailOutput.statusInfo("Host: #local.dsInfo.host#");
			detailOutput.statusInfo("Port: #local.dsInfo.port#");
			detailOutput.divider();
			
			// Execute dump based on database type
			local.success = false;
			
			switch (local.dbType) {
				case "MySQL":
				case "MySQL5":
					local.success = dumpMySQL(local.dsInfo, arguments);
					break;
				case "PostgreSQL":
				case "Postgres":
				case "Postgre":
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
					detailOutput.error("Database dump not supported for driver: " & local.dbType);
					detailOutput.statusInfo("Please use your database management tools to export the database.");
					return;
			}
			
			if (local.success) {
				detailOutput.divider();
				detailOutput.statusSuccess("Database exported successfully!");
				detailOutput.statusInfo("Output File: #arguments.output#");
				
				// Show file size
				if (FileExists(arguments.output)) {
					try {
						local.fileInfo = GetFileInfo(arguments.output);
						local.sizeInMB = NumberFormat(local.fileInfo.size / 1048576, "0.00");
						detailOutput.statusInfo("File Size: #local.sizeInMB# MB");
					} catch (any e) {
						// Ignore file info errors
					}
				}
				
				detailOutput.statusSuccess("Export completed successfully!");
			}
			
		} catch (any e) {
			detailOutput.error("Error exporting database: #e.message#");
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				detailOutput.error("Details: #e.detail#");
			}
			return;
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
				detailOutput.error("No database name specified");
				return false;
			}
			
			detailOutput.output("Preparing MySQL dump for database: #local.database#");
			
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
						detailOutput.statusInfo("Found mysqldump at:", local.path);
						break;
					}
				}
			}
			
			if (local.checkResult.success) {
				detailOutput.output("Found mysqldump, attempting native dump...");
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
					detailOutput.statusWarning("Authentication plugin issue detected, trying compatibility mode...");
					local.cmd = Replace(local.cmd, "mysqldump", "mysqldump --default-auth=mysql_native_password");
					local.result = executeSystemCommand(local.cmd, local.envVars);
				}
				
				local.mysqldumpSuccess = local.result.success;
				
				if (!local.mysqldumpSuccess) {
					detailOutput.statusWarning("mysqldump failed: " & (local.result.error ?: "Unknown error"));
				}
			}
			
			// If mysqldump failed or wasn't found, use JDBC fallback
			if (!local.mysqldumpSuccess) {
				if (local.mysqldumpAttempted) {
					detailOutput.output("Falling back to JDBC-based export...");
				} else {
					detailOutput.output("mysqldump not found, using JDBC-based export...");
				}

				return dumpMySQLViaJDBC(arguments.dsInfo, arguments.options);
			}
			
			// Handle compression for Windows if needed
			if (arguments.options.compress && isWindows() && FileExists(arguments.options.output)) {
				detailOutput.statusWarning("Note: Compression not available on Windows with mysqldump");
			}
			
			detailOutput.statusSuccess("MySQL dump completed successfully using mysqldump");
			return true;
			
		} catch (any e) {
			detailOutput.error("MySQL dump error: " & e.message);
			// Try JDBC as last resort
			detailOutput.output("Attempting JDBC fallback due to error...");
			try {
				return dumpMySQLViaJDBC(arguments.dsInfo, arguments.options);
			} catch (any jdbcError) {
				detailOutput.statusFailed("JDBC fallback also failed: " & jdbcError.message);
				return false;
			}
		}
	}

	private boolean function dumpMySQLViaJDBC(required struct dsInfo, required struct options) {
		try {
			detailOutput.output("Using JDBC connection for database export");
			detailOutput.statusWarning("Note: JDBC export may not include stored procedures, triggers, or views");
			
			// Get database connection
			local.connResult = getDatabaseConnection(arguments.dsInfo, "MySQL");
			
			if (!local.connResult.success) {
				detailOutput.error("Failed to connect to MySQL database via JDBC");
				if (Len(local.connResult.error)) {
					// Check for specific error types
					if (FindNoCase("Communications link failure", local.connResult.error)) {
						detailOutput.statusFailed("Connection failed - MySQL server may not be running");
						detailOutput.output("");
						detailOutput.statusWarning("Please check:");
						detailOutput.output("1. MySQL is running on port " & (arguments.dsInfo.port ?: "3306"));
						detailOutput.output("2. Firewall is not blocking the connection");
						detailOutput.output("3. Host '" & (arguments.dsInfo.host ?: "localhost") & "' is correct");
					} else if (FindNoCase("Access denied", local.connResult.error)) {
						detailOutput.statusFailed("Authentication failed");
						detailOutput.output("Please verify username and password are correct");
					} else {
						detailOutput.error("Error: " & local.connResult.error);
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
				
				detailOutput.statusInfo("Tables to export: " & ArrayLen(local.tableList));
				
				// Track progress
				local.tableCount = 0;
				local.totalRows = 0;
				
				// Process each table
				for (local.table in local.tableList) {
					local.tableCount++;
					detailOutput.statusInfo("Exporting table " & local.tableCount & "/" & ArrayLen(local.tableList) & ": " & local.table);
					
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
					detailOutput.output("Compressing output file...");
					// This is a basic implementation - could be enhanced
					detailOutput.statusWarning("Compression support is limited in JDBC mode");
				}
				
				detailOutput.statusSuccess("MySQL dump completed successfully via JDBC");
				detailOutput.statusInfo("Exported: " & ArrayLen(local.tableList) & " tables, " & local.totalRows & " rows");
				
				return true;
				
			} finally {
				if (IsDefined("local.conn")) {
					local.conn.close();
				}
			}
			
		} catch (any e) {
			detailOutput.error("MySQL JDBC dump error: " & e.message);
			if (StructKeyExists(e, "detail")) {
				detailOutput.error("Detail: " & e.detail);
			}
			return false;
		}
	}

	private boolean function dumpPostgreSQL(required struct dsInfo, required struct options) {
		try {
			local.host = arguments.dsInfo.host ?: "localhost";
			// Fix port handling - check for empty string too
			local.port = (StructKeyExists(arguments.dsInfo, "port") && Len(arguments.dsInfo.port)) ? arguments.dsInfo.port : "5432";
			local.database = arguments.dsInfo.database;
			local.username = arguments.dsInfo.username ?: "";
			
			// Check if database name is provided
			if (!Len(local.database)) {
				detailOutput.error("No database name specified");
				return false;
			}
			
			detailOutput.statusInfo("Preparing PostgreSQL dump for database: " & local.database);
			
			// Check if pg_dump is available FIRST
			local.checkCmd = isWindows() ? "where pg_dump" : "which pg_dump";
			local.checkResult = executeSystemCommand(local.checkCmd);
			
			if (!local.checkResult.success) {
				// pg_dump not found - provide installation guide and exit
				detailOutput.line();
				detailOutput.error("PostgreSQL client tools (pg_dump) not found!");
				detailOutput.line();
				detailOutput.statusWarning("pg_dump is required to export PostgreSQL databases");
				detailOutput.line();
				
				detailOutput.output("Installation Guide:");
				detailOutput.line();
				
				// Detect OS and provide specific instructions
				if (isWindows()) {
					detailOutput.output("For Windows:");
					detailOutput.output("1. Download PostgreSQL from: https://www.postgresql.org/download/windows/");
					detailOutput.output("2. Run the installer (you can choose 'Command Line Tools only' if you don't need the full server)");
					detailOutput.output("3. Add PostgreSQL bin directory to your PATH:");
					detailOutput.output("- Default location: C:\Program Files\PostgreSQL\[version]\bin", true);
					detailOutput.output("- Add to PATH: System Properties → Environment Variables → Path", true);
					detailOutput.output("4. Restart your terminal/CommandBox");
					detailOutput.line();
					detailOutput.output("Alternative - Using Chocolatey:");
					detailOutput.output("choco install postgresql", true);
				} else if (isMac()) {
					detailOutput.output("For macOS:");
					detailOutput.line();
					detailOutput.output("Option 1 - Using Homebrew (recommended):");
					detailOutput.output("brew install postgresql", true);
					detailOutput.line();
					detailOutput.output("Option 2 - PostgreSQL.app:");
					detailOutput.output("   Download from: https://postgresapp.com/");
					detailOutput.output("   After installation, add to PATH:");
					detailOutput.output("   export PATH=$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin");
					detailOutput.line();
					detailOutput.output("Option 3 - Using MacPorts:");
					detailOutput.output("   sudo port install postgresql16 +universal");
				} else {
					// Assume Linux/Unix
					detailOutput.output("For Linux:");
					detailOutput.line();
					detailOutput.output("Ubuntu/Debian:");
					detailOutput.output("   sudo apt-get update");
					detailOutput.output("   sudo apt-get install postgresql-client");
					detailOutput.line();
					detailOutput.output("RHEL/CentOS/Fedora:");
					detailOutput.output("   sudo yum install postgresql");
					detailOutput.output("   ## or for newer versions:");
					detailOutput.output("   sudo dnf install postgresql");
					detailOutput.line();
					detailOutput.output("Arch Linux:");
					detailOutput.output("   sudo pacman -S postgresql");
					detailOutput.line();
					detailOutput.output("Alpine Linux:");
					detailOutput.output("   apk add postgresql-client");
				}
				
				detailOutput.line();
				detailOutput.output("After installation:");
				detailOutput.output("1. Verify installation: pg_dump --version", true);
				detailOutput.output("2. Restart CommandBox", true);
				detailOutput.output("3. Try the export again", true);
				detailOutput.line();
				
				return false; // Exit - no pg_dump, no export
			}
			
			// pg_dump is available, proceed with dump
			detailOutput.statusSuccess("Found pg_dump, proceeding with database export...");
			
			// Ensure output directory exists
			local.outputFile = ExpandPath(arguments.options.output);
			if (arguments.options.output contains ":" || Left(arguments.options.output, 1) == "/" || Left(arguments.options.output, 1) == "\") {
				local.outputFile = arguments.options.output;
			}
			
			// Convert to absolute path and normalize
			local.outputFile = FileSystemUtil.resolvePath(local.outputFile);
			
			// For Windows: Fix the output file path
			if (isWindows()) {
				// Convert to forward slashes to avoid escaping issues
				local.outputFile = Replace(local.outputFile, "\", "/", "all");
				// Remove trailing slash if present
				if (Right(local.outputFile, 1) == "/") {
					local.outputFile = Left(local.outputFile, Len(local.outputFile)-1);
				}
			}
			
			local.outputDir = GetDirectoryFromPath(local.outputFile);
			if (Len(local.outputDir) && !DirectoryExists(local.outputDir)) {
				DirectoryCreate(local.outputDir, true);
				detailOutput.statusInfo("Created output directory: #local.outputDir#");
			}
			
			// Check if a folder with the .sql name exists and remove it
			if (DirectoryExists(local.outputFile)) {
				detailOutput.statusWarning("Found directory with same name as output file: " & local.outputFile);
				try {
					// Try to remove the directory if it's empty
					local.dirList = DirectoryList(local.outputFile, false, "name");
					if (ArrayLen(local.dirList) == 0) {
						DirectoryDelete(local.outputFile, false);
						detailOutput.statusInfo("Removed empty directory that was blocking file creation");
					} else {
						detailOutput.error("Directory is not empty, cannot remove. Please manually delete: " & local.outputFile);
						return false;
					}
				} catch(any e) {
					detailOutput.error("Could not remove directory: " & e.message);
				}
			}
			
			// Build pg_dump command WITHOUT quotes for Windows
			local.cmd = "pg_dump";
			local.cmd &= " -h " & local.host;  // No quotes
			local.cmd &= " -p " & local.port;
			local.cmd &= " -U " & local.username;  // No quotes
			local.cmd &= " -d " & local.database;  // No quotes
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
					local.cmd &= " -t " & Trim(local.table);  // No quotes
				}
			}
			
			// Handle compression
			if (arguments.options.compress) {
				local.cmd &= " -Z 9"; // Maximum compression
				// Add .gz extension if not already present
				if (ListLast(local.outputFile, ".") != "gz") {
					local.outputFile &= ".gz";
				}
			}
			
			// For Windows: Use shell redirection instead of -f option
			if (isWindows()) {
				// Use stdout redirection instead of -f parameter
				local.cmd &= " > " & Chr(34) & local.outputFile & Chr(34);
			} else if(isMac()) {
				// Mac OS: Use -f parameter without quotes
				local.cmd &= " -f " & local.outputFile;
			} else {
				// Unix/Linux: Use -f parameter
				local.cmd &= " -f " & Chr(34) & local.outputFile & Chr(34);
			}
			
			// Set PGPASSWORD environment variable if provided
			local.envVars = {};
			if (StructKeyExists(arguments.dsInfo, "password") && Len(arguments.dsInfo.password)) {
				local.envVars["PGPASSWORD"] = arguments.dsInfo.password;
			}
			
			detailOutput.output("Executing PostgreSQL dump...");
			detailOutput.statusInfo("Command: pg_dump (output to file)");
			detailOutput.statusInfo("Output file: " & local.outputFile);
			
			local.result = executeSystemCommand(local.cmd, local.envVars);
			
			if (local.result.success) {
				detailOutput.statusSuccess("PostgreSQL dump completed successfully");
				
				// Check if file was created and has content
				if (FileExists(local.outputFile)) {
					try {
						local.fileInfo = CreateObject("java", "java.io.File").init(local.outputFile);
						local.fileSize = local.fileInfo.length();
						if (local.fileSize > 0) {
							detailOutput.statusSuccess("Export file size: " & NumberFormat(local.fileSize / 1024, "0.00") & " KB");
						} else {
							detailOutput.statusWarning("Export file is empty - check database permissions");
						}
					} catch (any e) {
						// Just note that file was created
						detailOutput.statusSuccess("Export file created: " & local.outputFile);
					}
				} else {
					detailOutput.error("Export file was not created: " & local.outputFile);
					return false;
				}
			} else {
				detailOutput.error("PostgreSQL dump failed");
				if (StructKeyExists(local.result, "output") && Len(Trim(local.result.output))) {
					detailOutput.error("Output: " & local.result.output);
				}
				if (StructKeyExists(local.result, "error") && Len(local.result.error)) {
					detailOutput.error("Error: " & local.result.error);
				}
				
				detailOutput.line();
				detailOutput.statusInfo("Troubleshooting tips:");
				detailOutput.output("1. Check database connection settings", true);
				detailOutput.output("2. Verify user has necessary permissions", true);
				detailOutput.output("3. Ensure database name is correct", true);
				detailOutput.output("4. Check if PostgreSQL server is running", true);
				detailOutput.output("5. Try connecting with psql first to test credentials", true);
			}
			
			return local.result.success;
			
		} catch (any e) {
			detailOutput.error("PostgreSQL dump error: " & e.message);
			if (StructKeyExists(e, "detail")) {
				detailOutput.error("Details: " & e.detail);
			}
			return false;
		}
	}

	private boolean function dumpSQLServer(required struct dsInfo, required struct options) {
		try {
			detailOutput.output("Preparing SQL Server export...");

			/* ----------------------------------------------------
			1. Get database connection details
			---------------------------------------------------- */
			local.host = dsInfo.host ?: "localhost";
			local.port = dsInfo.port ?: "1433";
			local.database = dsInfo.database;
			local.username = dsInfo.username ?: "";
			local.password = dsInfo.password ?: "";
			
			if (!Len(local.database)) {
				detailOutput.error("No database name specified");
				return false;
			}

			detailOutput.statusInfo("Database: #local.database#");
			detailOutput.statusInfo("Server: #local.host#:#local.port#");

			/* ----------------------------------------------------
			2. Generate backup file path
			---------------------------------------------------- */
			local.outputFile = arguments.options.output;
			
			// If no output file specified, generate default .bak filename
			if (!Len(local.outputFile)) {
				local.timestamp = DateFormat(Now(), "yyyymmdd") & TimeFormat(Now(), "HHmmss");
				local.outputFile = fileSystemUtil.resolvePath("backup_" & local.database & "_" & local.timestamp & ".bak");
			} else {
				// Ensure it has .bak extension
				if (ListLast(local.outputFile, ".") != "bak") {
					local.outputFile &= ".bak";
				}
				local.outputFile = fileSystemUtil.resolvePath(local.outputFile);
			}
			
			// Ensure directory exists
			local.outputDir = GetDirectoryFromPath(local.outputFile);
			if (Len(local.outputDir) && !DirectoryExists(local.outputDir)) {
				DirectoryCreate(local.outputDir, true);
				detailOutput.statusInfo("Created directory: #local.outputDir#");
			}

			detailOutput.statusInfo("Backup file: #local.outputFile#");
			
			/* ----------------------------------------------------
			3. Try using sqlcmd (Windows)
			---------------------------------------------------- */
			local.useSqlCmd = false;
			local.sqlCmdResult = "";
			
			if (isWindows()) {
				detailOutput.output("Checking for sqlcmd...");
				local.checkCmd = "where sqlcmd";
				local.checkResult = executeSystemCommand(local.checkCmd);
				
				if (local.checkResult.success) {
					detailOutput.statusSuccess("Found sqlcmd, using native backup");
					local.useSqlCmd = true;
					
					// Convert path for Windows
					local.backupPath = Replace(local.outputFile, "/", "\", "all");
					local.backupPath = Replace(local.backupPath, "\\", "\", "all");
					
					// Build sqlcmd command
					local.cmd = 'sqlcmd';
					
					// Add authentication
					if (Len(local.username) && Len(local.password)) {
						local.cmd &= ' -S "#local.host#,#local.port#" -U "#local.username#" -P "#local.password#"';
					} else {
						local.cmd &= ' -S "#local.host#,#local.port#" -E'; // Windows Authentication
					}
					
					// Add backup command
					local.cmd &= ' -Q "BACKUP DATABASE [#local.database#] TO DISK=''#local.backupPath#'' WITH INIT, FORMAT, COMPRESSION, STATS=5"';
					
					detailOutput.statusInfo("Executing SQL Server backup...");
					local.sqlCmdResult = executeSystemCommand(local.cmd);
					
					if (local.sqlCmdResult.success) {
						detailOutput.statusSuccess("SQL Server backup completed successfully via sqlcmd");
						return true;
					} else {
						detailOutput.statusFailed("#local.sqlCmdResult.error#");
						return;
					}
				} else {
					detailOutput.statusWarning("sqlcmd not found");
				}
			}
			
		} catch (any e) {
			detailOutput.error("SQL Server export error: " & e.message);
			return false;
		}
	}

	private boolean function dumpH2(required struct dsInfo, required struct options) {
		try {
			detailOutput.output("Preparing H2 database export...");
			
			// Get database connection
			local.connResult = getDatabaseConnection(arguments.dsInfo, "H2");
			
			if (!local.connResult.success) {
				detailOutput.error("Failed to connect to H2 database");
				if (Len(local.connResult.error)) {
					detailOutput.error(local.connResult.error);
				}
				return false;
			}
			
			local.conn = local.connResult.connection;
			
			try {
				detailOutput.output("Generating H2 database script...");
				
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
				
				detailOutput.statusSuccess("H2 database exported successfully");
				return true;
				
			} catch (any e) {
				detailOutput.error("H2 export error: " & e.message);
				return false;
			} finally {
				if (IsDefined("local.conn")) {
					local.conn.close();
				}
			}
			
		} catch (any e) {
			detailOutput.error("H2 database export error: " & e.message);
			return false;
		}
	}

	private struct function executeSystemCommand(required string command, struct envVars = {}) {
		local.runtime = CreateObject("java", "java.lang.Runtime").getRuntime();
		local.isWin = isWindows();

		
		// Build the command array
		if (local.isWin) {
			// For Windows: Use array format to avoid quoting issues
			// Split the command into an array of arguments
			local.cmdArray = ["cmd", "/c", arguments.command];
			local.fullCommand = local.cmdArray;
		} else {
			// Unix/Linux/Mac: Use string command
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
		try {
			if (ArrayLen(local.envArray)) {
				if (local.isWin && IsArray(local.fullCommand)) {
					// Use array format for Windows
					local.process = local.runtime.exec(local.fullCommand, local.envArray);
				} else {
					local.process = local.runtime.exec(local.fullCommand, local.envArray);
				}
			} else {
				if (local.isWin && IsArray(local.fullCommand)) {
					// Use array format for Windows
					local.process = local.runtime.exec(local.fullCommand);
				} else {
					local.process = local.runtime.exec(local.fullCommand);
				}
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
				error: e.message & " " & e.detail,
				exitCode: -1,
				output: ""
			};
		}
	}

	private boolean function isWindows() {
		local.os = CreateObject("java", "java.lang.System").getProperty("os.name");
		return FindNoCase("Windows", local.os) > 0;
	}
	
	// Helper function to detect Mac OS
	private boolean function isMac() {
		local.os = CreateObject("java", "java.lang.System").getProperty("os.name");
		return FindNoCase("mac", local.os) > 0;
	}
}