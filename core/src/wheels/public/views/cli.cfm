<!--- CLI & GUI Uses this file to talk to wheels via JSON when in maintenance/testing/development mode --->
<cfscript>
baseCfc = createObject("wheels.migrator.Base");
setting showDebugOutput="no";
migrator = application.wheels.migrator;

try {
	"data" = {};
	data["success"] = true;
	data["datasource"] = application.wheels.dataSourceName;
	data["wheelsVersion"] = application.wheels.version;
	data["currentVersion"] = migrator.getCurrentMigrationVersion();
	data["databaseType"] = baseCfc.$getDBType();
	data["migrations"] = migrator.getAvailableMigrations();
	data["lastVersion"] = 0;
	data["message"] = "";
	data["messages"] = "";
	data["command"] = "";
	
	if (ArrayLen(data.migrations)) {
		data.lastVersion = data.migrations[ArrayLen(data.migrations)].version;
	}

	if (StructKeyExists(request.wheels.params, "command")) {

		data.command = request.wheels.params.command;
		switch (request.wheels.params.command) {
			case "createMigration":
				if (StructKeyExists(request.wheels.params, "migrationPrefix") && Len(request.wheels.params.migrationPrefix)) {
					data.message = migrator.createMigration(
						request.wheels.params.migrationName,
						request.wheels.params.templateName,
						request.wheels.params.migrationPrefix
					);
				} else {
					data.message = migrator.createMigration(
						request.wheels.params.migrationName,
						request.wheels.params.templateName
					);
				}
				break;
			case "migrateTo":
				if (StructKeyExists(request.wheels.params, "version")) {
					data.message = migrator.migrateTo(request.wheels.params.version);
				}
				break;
			case "migrateToLatest":
				data.message = migrator.migrateToLatest();
				break;
			case "redoMigration":
				if (StructKeyExists(request.wheels.params, "version")) {
					local.redoVersion = request.wheels.params.version;
				} else {
					local.redoVersion = data.lastVersion;
				}
				data.message = migrator.redoMigration(local.redoVersion);
				break;
			case "info":
				data.message = "Returning what I know..";
				break;
			
			// Database commands
			case "dbStatus":
				// Return migration status
				data.success = true;
				data.currentVersion = data.currentVersion;
				data.migrations = [];
				
				// Format migrations for CLI consumption
				for (local.migration in migrator.getAvailableMigrations()) {
					local.migrationInfo = {
						version = local.migration.version,
						description = local.migration.name,
						status = local.migration.status,
						appliedAt = local.migration.loadedAt ?: ""
					};
					if (local.migration.version <= data.currentVersion) {
						local.migrationInfo.status = "applied";
					} else {
						local.migrationInfo.status = "pending";
					}
					arrayAppend(data.migrations, local.migrationInfo);
				}
				
				// Add summary
				local.applied = 0;
				local.pending = 0;
				for (local.m in data.migrations) {
					if (local.m.status == "applied") {
						local.applied++;
					} else {
						local.pending++;
					}
				}
				data.summary = {
					total = arrayLen(data.migrations),
					applied = local.applied,
					pending = local.pending
				};
				break;
				
			case "dbVersion":
				// Return current database version
				data.success = true;
				data.version = data.currentVersion;
				data.message = "Current database version: " & data.currentVersion;
				break;
				
			case "dbRollback":
				// Rollback database
				local.steps = structKeyExists(request.wheels.params, "steps") ? request.wheels.params.steps : 1;
				local.targetVersion = "";
				
				// Find target version based on steps
				local.appliedMigrations = [];
				for (local.migration in migrator.getAvailableMigrations()) {
					if (local.migration.version <= data.currentVersion) {
						arrayAppend(local.appliedMigrations, local.migration);
					}
				}
				
				if (arrayLen(local.appliedMigrations) >= local.steps) {
					local.targetIndex = arrayLen(local.appliedMigrations) - local.steps;
					if (local.targetIndex > 0) {
						local.targetVersion = local.appliedMigrations[local.targetIndex].version;
					} else {
						local.targetVersion = "0";
					}
				}
				
				if (len(local.targetVersion)) {
					data.message = migrator.migrateTo(local.targetVersion);
					data.success = true;
				} else {
					data.success = false;
					data.message = "No migrations to rollback";
				}
				break;
				
			case "dbSchema":
				// Export database schema
				data.success = true;
				data.schema = {};
				
				try {
					// Get database type from the baseCfc which was already created at the top
					data.schema.databaseType = data.databaseType;
					data.schema.tables = [];
					
					// Get all tables
					local.tables = [];
					
					// SQL Server specific query
					if (data.databaseType == "MicrosoftSQLServer" || data.databaseType == "SQLServer") {
						local.tablesQuery = new Query();
						local.tablesQuery.setDatasource(application.wheels.dataSourceName);
						local.tablesQuery.setSQL("
							SELECT 
								TABLE_NAME 
							FROM INFORMATION_SCHEMA.TABLES 
							WHERE TABLE_TYPE = 'BASE TABLE' 
								AND TABLE_CATALOG = DB_NAME()
								AND TABLE_SCHEMA = 'dbo'
							ORDER BY TABLE_NAME
						");
						local.tables = local.tablesQuery.execute().getResult();
					} else if (data.databaseType == "H2") {
						// H2 specific query
						local.tablesQuery = new Query();
						local.tablesQuery.setDatasource(application.wheels.dataSourceName);
						local.tablesQuery.setSQL("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'TABLE' AND TABLE_SCHEMA = 'PUBLIC'");
						local.tables = local.tablesQuery.execute().getResult();
					} else if (data.databaseType == "MySQL") {
						// MySQL specific query
						local.tablesQuery = new Query();
						local.tablesQuery.setDatasource(application.wheels.dataSourceName);
						local.tablesQuery.setSQL("
							SELECT 
								TABLE_NAME 
							FROM INFORMATION_SCHEMA.TABLES 
							WHERE TABLE_TYPE = 'BASE TABLE' 
								AND TABLE_SCHEMA = DATABASE()
							ORDER BY TABLE_NAME
						");
						local.tables = local.tablesQuery.execute().getResult();
					} else if (data.databaseType == "PostgreSQL") {
						// PostgreSQL specific query
						local.tablesQuery = new Query();
						local.tablesQuery.setDatasource(application.wheels.dataSourceName);
						local.tablesQuery.setSQL("
							SELECT 
								tablename AS TABLE_NAME 
							FROM pg_tables 
							WHERE schemaname = 'public'
							ORDER BY tablename
						");
						local.tables = local.tablesQuery.execute().getResult();
					} else {
						// Generic INFORMATION_SCHEMA query
						local.tablesQuery = new Query();
						local.tablesQuery.setDatasource(application.wheels.dataSourceName);
						local.tablesQuery.setSQL("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME");
						local.tables = local.tablesQuery.execute().getResult();
					}
					
					// Process each table
					for (local.table in local.tables) {
						local.tableInfo = {
							name = local.table.TABLE_NAME,
							columns = [],
							indexes = [],
							primaryKey = []
						};
						
						// Get columns for each table
						local.columns = new Query();
						local.columns.setDatasource(application.wheels.dataSourceName);
						
						if (data.databaseType == "MicrosoftSQLServer" || data.databaseType == "SQLServer") {
							local.columns.setSQL("
								SELECT 
									c.COLUMN_NAME,
									c.DATA_TYPE,
									c.CHARACTER_MAXIMUM_LENGTH,
									c.NUMERIC_PRECISION,
									c.NUMERIC_SCALE,
									c.IS_NULLABLE,
									c.COLUMN_DEFAULT,
									c.ORDINAL_POSITION
								FROM INFORMATION_SCHEMA.COLUMNS c
								WHERE c.TABLE_NAME = :tableName 
									AND c.TABLE_SCHEMA = 'dbo'
								ORDER BY c.ORDINAL_POSITION
							");
						} else if (data.databaseType == "H2") {
							local.columns.setSQL("
								SELECT 
									COLUMN_NAME, 
									TYPE_NAME as DATA_TYPE, 
									IS_NULLABLE, 
									COLUMN_DEFAULT,
									ORDINAL_POSITION
								FROM INFORMATION_SCHEMA.COLUMNS 
								WHERE TABLE_NAME = :tableName 
									AND TABLE_SCHEMA = 'PUBLIC'
								ORDER BY ORDINAL_POSITION
							");
						} else if (data.databaseType == "MySQL") {
							local.columns.setSQL("
								SELECT 
									COLUMN_NAME,
									DATA_TYPE,
									CHARACTER_MAXIMUM_LENGTH,
									NUMERIC_PRECISION,
									NUMERIC_SCALE,
									IS_NULLABLE,
									COLUMN_DEFAULT,
									ORDINAL_POSITION,
									COLUMN_KEY,
									EXTRA
								FROM INFORMATION_SCHEMA.COLUMNS 
								WHERE TABLE_NAME = :tableName 
									AND TABLE_SCHEMA = DATABASE()
								ORDER BY ORDINAL_POSITION
							");
						} else if (data.databaseType == "PostgreSQL") {
							local.columns.setSQL("
								SELECT 
									column_name AS COLUMN_NAME,
									data_type AS DATA_TYPE,
									character_maximum_length AS CHARACTER_MAXIMUM_LENGTH,
									numeric_precision AS NUMERIC_PRECISION,
									numeric_scale AS NUMERIC_SCALE,
									is_nullable AS IS_NULLABLE,
									column_default AS COLUMN_DEFAULT,
									ordinal_position AS ORDINAL_POSITION
								FROM information_schema.columns 
								WHERE table_name = :tableName 
									AND table_schema = 'public'
								ORDER BY ordinal_position
							");
						} else {
							local.columns.setSQL("
								SELECT 
									COLUMN_NAME, 
									DATA_TYPE, 
									IS_NULLABLE, 
									COLUMN_DEFAULT 
								FROM INFORMATION_SCHEMA.COLUMNS 
								WHERE TABLE_NAME = :tableName
								ORDER BY ORDINAL_POSITION
							");
						}
						
						local.columns.addParam(name="tableName", value=local.table.TABLE_NAME, cfsqltype="cf_sql_varchar");
						local.columnResult = local.columns.execute().getResult();
						
						// Process column information
						for (local.column in local.columnResult) {
							local.columnInfo = {
								name = local.column.COLUMN_NAME,
								type = local.column.DATA_TYPE,
								nullable = local.column.IS_NULLABLE,
								default = structKeyExists(local.column, "COLUMN_DEFAULT") ? (local.column.COLUMN_DEFAULT ?: "") : ""
							};
							
							// Add additional details if available
							if (structKeyExists(local.column, "CHARACTER_MAXIMUM_LENGTH") && len(local.column.CHARACTER_MAXIMUM_LENGTH)) {
								local.columnInfo.length = local.column.CHARACTER_MAXIMUM_LENGTH;
							}
							if (structKeyExists(local.column, "NUMERIC_PRECISION") && len(local.column.NUMERIC_PRECISION)) {
								local.columnInfo.precision = local.column.NUMERIC_PRECISION;
							}
							if (structKeyExists(local.column, "NUMERIC_SCALE") && len(local.column.NUMERIC_SCALE)) {
								local.columnInfo.scale = local.column.NUMERIC_SCALE;
							}
							if (structKeyExists(local.column, "EXTRA") && len(local.column.EXTRA)) {
								local.columnInfo.extra = local.column.EXTRA;
							}
							
							arrayAppend(local.tableInfo.columns, local.columnInfo);
						}
						
						// Try to get primary key information
						try {
							local.pkQuery = new Query();
							local.pkQuery.setDatasource(application.wheels.dataSourceName);
							
							if (data.databaseType == "MicrosoftSQLServer" || data.databaseType == "SQLServer") {
								local.pkQuery.setSQL("
									SELECT 
										c.COLUMN_NAME
									FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
									JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE c 
										ON c.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
										AND c.TABLE_NAME = tc.TABLE_NAME
										AND c.TABLE_SCHEMA = tc.TABLE_SCHEMA
									WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY' 
										AND tc.TABLE_NAME = :tableName
										AND tc.TABLE_SCHEMA = 'dbo'
									ORDER BY c.ORDINAL_POSITION
								");
							} else if (data.databaseType == "MySQL") {
								local.pkQuery.setSQL("
									SELECT 
										COLUMN_NAME
									FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
									WHERE CONSTRAINT_NAME = 'PRIMARY'
										AND TABLE_NAME = :tableName
										AND TABLE_SCHEMA = DATABASE()
									ORDER BY ORDINAL_POSITION
								");
							} else {
								// Generic query for primary keys
								local.pkQuery.setSQL("
									SELECT 
										c.COLUMN_NAME
									FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
									JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE c 
										ON c.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
										AND c.TABLE_NAME = tc.TABLE_NAME
									WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY' 
										AND tc.TABLE_NAME = :tableName
								");
							}
							
							local.pkQuery.addParam(name="tableName", value=local.table.TABLE_NAME, cfsqltype="cf_sql_varchar");
							local.pkResult = local.pkQuery.execute().getResult();
							
							for (local.pk in local.pkResult) {
								arrayAppend(local.tableInfo.primaryKey, local.pk.COLUMN_NAME);
							}
						} catch (any pkError) {
							// Ignore primary key errors - not all databases support this query
						}
						
						arrayAppend(data.schema.tables, local.tableInfo);
					}
					
					// Add summary information
					data.schema.tableCount = arrayLen(data.schema.tables);
					data.message = "Schema exported successfully. Found " & data.schema.tableCount & " tables.";
					
				} catch (any e) {
					data.success = false;
					data.message = "Error retrieving schema: " & e.message;
					if (structKeyExists(e, "detail")) {
						data.detail = e.detail;
					}
				}
				break;
				
			case "dbSeed":
				// Seed database with test data
				local.count = structKeyExists(request.wheels.params, "count") ? val(request.wheels.params.count) : 10;
				local.models = structKeyExists(request.wheels.params, "models") ? request.wheels.params.models : "";
				data.success = true;
				data.seeded = [];
				
				try {
					// Get all model files if no specific models requested
					local.modelList = [];
					if (len(local.models)) {
						local.modelList = listToArray(local.models);
					} else {
						// Find all model files in the app/models directory
						local.modelPath = expandPath("/app/models");
						if (directoryExists(local.modelPath)) {
							local.modelFiles = directoryList(local.modelPath, false, "name", "*.cfc");
							for (local.file in local.modelFiles) {
								// Skip any files that start with underscore (partials/helpers)
								if (left(local.file, 1) != "_") {
									arrayAppend(local.modelList, listFirst(local.file, "."));
								}
							}
						}
					}
					
					// Seed each model
					for (local.modelName in local.modelList) {
						try {
							// Create model instance
							local.model = model(local.modelName);
							local.seededCount = 0;
							
							// Get model properties
							local.properties = [];
							if (structKeyExists(local.model, "$classData") && structKeyExists(local.model.$classData(), "properties")) {
								local.properties = local.model.$classData().properties;
							}
							
							// Generate test data for each record
							for (local.i = 1; local.i <= local.count; local.i++) {
								local.record = {};
								
								// Generate data based on property names and types
								for (local.prop in local.properties) {
									if (local.prop.name != "id" && !listFindNoCase("createdAt,updatedAt,deletedAt", local.prop.name)) {
										// Generate appropriate test data based on property name and type
										local.record[local.prop.name] = generateTestData(local.prop.name, local.prop.type, local.i);
									}
								}
								
								// Create the record
								local.newRecord = local.model.new(local.record);
								if (local.newRecord.save()) {
									local.seededCount++;
								}
							}
							
							arrayAppend(data.seeded, {
								model = local.modelName,
								count = local.seededCount,
								success = true
							});
							
						} catch (any modelError) {
							arrayAppend(data.seeded, {
								model = local.modelName,
								count = 0,
								success = false,
								error = modelError.message
							});
						}
					}
					
					// Build success message
					local.totalSeeded = 0;
					for (local.result in data.seeded) {
						if (local.result.success) {
							local.totalSeeded += local.result.count;
						}
					}
					
					data.message = "Database seeding completed. Created #local.totalSeeded# records across #arrayLen(data.seeded)# models.";
					
				} catch (any e) {
					data.success = false;
					data.message = "Error during database seeding: " & e.message;
				}
				break;
				
			case "routes":
				// Return application routes
				data.success = true;
				data.routes = [];
				
				// Get routes from application
				local.appKey = application.wheels.appKey;
				if (structKeyExists(application, local.appKey) && structKeyExists(application[local.appKey], "routes")) {
					for (local.route in application[local.appKey].routes) {
						local.routeInfo = {
							name = structKeyExists(local.route, "name") ? local.route.name : "",
							pattern = structKeyExists(local.route, "pattern") ? local.route.pattern : "",
							controller = structKeyExists(local.route, "controller") ? local.route.controller : "",
							action = structKeyExists(local.route, "action") ? local.route.action : "",
							methods = structKeyExists(local.route, "methods") ? local.route.methods : "GET"
						};
						arrayAppend(data.routes, local.routeInfo);
					}
				}
				break;
				
			case "dbCreate":
				// Create database
				data.success = false;
				
				// For H2, we can provide helpful info and ensure schema table exists
				if (data.databaseType == "H2") {
					try {
						// Check if schemainfo table exists
						local.checkQuery = new Query();
						local.checkQuery.setDatasource(application.wheels.dataSourceName);
						local.checkQuery.setSQL("SELECT COUNT(*) as cnt FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SCHEMAINFO'");
						local.checkResult = local.checkQuery.execute().getResult();
						
						if (local.checkResult.cnt == 0) {
							// Create schemainfo table
							local.createQuery = new Query();
							local.createQuery.setDatasource(application.wheels.dataSourceName);
							local.createQuery.setSQL("CREATE TABLE IF NOT EXISTS schemainfo (version VARCHAR(25) DEFAULT '0')");
							local.createQuery.execute();
							
							// Insert initial version
							local.insertQuery = new Query();
							local.insertQuery.setDatasource(application.wheels.dataSourceName);
							local.insertQuery.setSQL("INSERT INTO schemainfo (version) VALUES ('0')");
							local.insertQuery.execute();
							
							data.message = "H2 database initialized successfully with schema tracking table.";
						} else {
							data.message = "H2 database already exists and is properly configured.";
						}
						data.success = true;
					} catch (any e) {
						data.message = "H2 database exists but error checking schema: " & e.message;
						data.success = true; // Still mark as success since H2 auto-creates
					}
				} else {
					data.message = "Database creation must be done through your database management system or hosting control panel.";
					
					// Provide helpful commands for common databases
					switch(data.databaseType) {
						case "MySQL":
							data.message &= chr(10) & chr(10) & "MySQL: CREATE DATABASE dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;";
							break;
						case "PostgreSQL":
							data.message &= chr(10) & chr(10) & "PostgreSQL: CREATE DATABASE dbname WITH ENCODING='UTF8';";
							break;
						case "SQLServer":
							data.message &= chr(10) & chr(10) & "SQL Server: CREATE DATABASE dbname;";
							break;
					}
				}
				break;
				
			case "dbDrop":
				// Drop database
				data.success = false;
				data.message = "Database dropping must be done through your database management system or hosting control panel for safety reasons.";
				break;
				
			case "dbReset":
				// Reset database (drop all tables and re-run migrations)
				try {
					// Get all tables
					local.tables = [];
					if (data.databaseType == "H2") {
						local.tablesQuery = new Query();
						local.tablesQuery.setDatasource(application.wheels.dataSourceName);
						local.tablesQuery.setSQL("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'TABLE' AND TABLE_SCHEMA = 'PUBLIC' AND TABLE_NAME != 'SCHEMAINFO'");
						local.tables = local.tablesQuery.execute().getResult();
					} else {
						local.tablesQuery = new Query();
						local.tablesQuery.setDatasource(application.wheels.dataSourceName);
						local.tablesQuery.setSQL("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME != 'schemainfo'");
						local.tables = local.tablesQuery.execute().getResult();
					}
					
					// Drop all tables except schemainfo
					for (local.table in local.tables) {
						local.dropQuery = new Query();
						local.dropQuery.setDatasource(application.wheels.dataSourceName);
						local.dropQuery.setSQL("DROP TABLE #local.table.TABLE_NAME#");
						local.dropQuery.execute();
					}
					
					// Reset migration version to 0
					local.resetQuery = new Query();
					local.resetQuery.setDatasource(application.wheels.dataSourceName);
					local.resetQuery.setSQL("UPDATE schemainfo SET version = '0'");
					local.resetQuery.execute();
					
					data.success = true;
					data.message = "Database reset successfully. All tables dropped and migration version reset to 0.";
				} catch (any e) {
					data.success = false;
					data.message = "Error resetting database: " & e.message;
				}
				break;
				
			case "dbSetup":
				// Setup database (create + migrate + seed)
				data.success = true;
				data.message = "Database setup: ";
				
				// Run migrations to latest
				try {
					local.migrateResult = migrator.migrateToLatest();
					data.message &= "Migrations completed. ";
					
					// Run seeding if requested
					if (structKeyExists(request.wheels.params, "seed") && request.wheels.params.seed) {
						// Use the dbSeed logic
						request.wheels.params.command = "dbSeed";
						local.seedCount = structKeyExists(request.wheels.params, "seedCount") ? val(request.wheels.params.seedCount) : 10;
						request.wheels.params.count = local.seedCount;
						
						// Re-run this switch for dbSeed
						data.command = "dbSeed";
						include "/wheels/public/views/cli.cfm";
						abort;
					}
				} catch (any e) {
					data.success = false;
					data.message &= "Migration failed: " & e.message & ". ";
				}
				break;
				
			case "dbDump":
				// Dump database
				data.success = false;
				data.dump = "";
				
				// For H2, we can generate a dump directly
				if (data.databaseType == "H2") {
					try {
						local.dumpQuery = new Query();
						local.dumpQuery.setDatasource(application.wheels.dataSourceName);
						local.dumpQuery.setSQL("SCRIPT SIMPLE");
						local.dumpResult = local.dumpQuery.execute().getResult();
						
						// Build SQL dump
						local.sqlDump = "";
						for (local.row in local.dumpResult) {
							local.sqlDump &= local.row.SCRIPT & ";" & chr(10);
						}
						
						data.success = true;
						data.dump = local.sqlDump;
						data.message = "Database dump generated successfully. Use --output parameter to save to file.";
						
						// If output file specified, save it
						if (structKeyExists(request.wheels.params, "output")) {
							local.outputFile = expandPath(request.wheels.params.output);
							fileWrite(local.outputFile, local.sqlDump);
							data.message = "Database dump saved to: " & request.wheels.params.output;
						}
						
					} catch (any e) {
						data.message = "Error generating dump: " & e.message;
					}
				} else {
					// Provide database-specific guidance for other systems
					data.message = "Database dump functionality requires command-line tools specific to your database system.";
					switch(data.databaseType) {
						case "MySQL":
							data.message &= " Use: mysqldump -u [username] -p [database] > backup.sql";
							break;
						case "PostgreSQL":
							data.message &= " Use: pg_dump -U [username] [database] > backup.sql";
							break;
						case "SQLServer":
							data.message &= " Use SQL Server Management Studio or: sqlcmd -S [server] -d [database] -Q 'BACKUP DATABASE...'";
							break;
					}
				}
				break;
				
			case "dbRestore":
				// Restore database
				data.success = false;
				data.message = "Database restore functionality requires command-line tools specific to your database system.";
				
				// Provide database-specific guidance
				switch(data.databaseType) {
					case "MySQL":
						data.message &= " Use: mysql -u [username] -p [database] < backup.sql";
						break;
					case "PostgreSQL":
						data.message &= " Use: psql -U [username] [database] < backup.sql";
						break;
					case "SQLServer":
						data.message &= " Use SQL Server Management Studio or: sqlcmd -S [server] -d [database] -i backup.sql";
						break;
					case "H2":
						data.message &= " Use: RUNSCRIPT FROM 'backup.sql' in H2 console";
						break;
				}
				break;
				
			case "dbShell":
				// Database shell
				data.success = false;
				
				// For H2, provide specific information about accessing the console
				if (data.databaseType == "H2") {
					data.message = "H2 Database Console Access:" & chr(10);
					data.message &= chr(10) & "Option 1: Web Console" & chr(10);
					data.message &= "The H2 web console may be available at the /h2-console path of your application." & chr(10);
					data.message &= "URL: http://localhost:[your-port]/h2-console" & chr(10);
					data.message &= "JDBC URL: " & application.wheels.dataSourceName & chr(10);
					
					// Try to get connection info
					try {
						local.dbinfo = new Query();
						local.dbinfo.setDatasource(application.wheels.dataSourceName);
						local.dbinfo.setSQL("SELECT DATABASE() as dbname, USER() as dbuser");
						local.dbResult = local.dbinfo.execute().getResult();
						if (local.dbResult.recordCount) {
							data.message &= "Database: " & local.dbResult.dbname & chr(10);
							data.message &= "User: " & local.dbResult.dbuser & chr(10);
						}
					} catch (any e) {
						// Ignore errors getting extra info
					}
					
					data.message &= chr(10) & "Option 2: Command Line" & chr(10);
					data.message &= "java -cp [path-to-h2.jar] org.h2.tools.Shell" & chr(10);
					
					// If command parameter provided, execute it
					if (structKeyExists(request.wheels.params, "command")) {
						try {
							local.shellQuery = new Query();
							local.shellQuery.setDatasource(application.wheels.dataSourceName);
							local.shellQuery.setSQL(request.wheels.params.command);
							local.shellResult = local.shellQuery.execute().getResult();
							
							data.success = true;
							data.result = local.shellResult;
							data.message = "Command executed successfully.";
						} catch (any e) {
							data.message = "Error executing command: " & e.message;
						}
					}
				} else {
					// Provide database-specific guidance
					data.message = "Database shell access requires command-line tools. ";
					switch(data.databaseType) {
						case "MySQL":
							data.message &= "Use: mysql -u [username] -p [database]";
							break;
						case "PostgreSQL":
							data.message &= "Use: psql -U [username] [database]";
							break;
						case "SQLServer":
							data.message &= "Use: sqlcmd -S [server] -d [database] -U [username]";
							break;
					}
				}
				break;
			case "configSet":
				data.success = false;
				
				// Validate required parameters
				if (!structKeyExists(request.wheels.params, "key") || !len(trim(request.wheels.params.key))) {
					data.message = "Configuration key is required";
					break;
				}
				
				if (!structKeyExists(request.wheels.params, "value")) {
					data.message = "Configuration value is required";
					break;
				}
				
				local.key = trim(request.wheels.params.key);
				local.value = request.wheels.params.value;
				local.environment = structKeyExists(request.wheels.params, "environment") ? request.wheels.params.environment : "development";
				local.encrypt = structKeyExists(request.wheels.params, "encrypt") && request.wheels.params.encrypt;
				
				try {
					switch(local.environment) {
						case "all":
							// Update base settings.cfm
							local.settingsPath = expandPath("/config/");
							break;
						default:
							local.settingsPath = expandPath("/config/#local.environment#/");
							break;
					}
					
					local.settingsFile = local.settingsPath & "settings.cfm";
					
					if (!len(local.settingsFile)) {
						break;
					}
					
					// Check if file exists
					if (!fileExists(local.settingsFile)) {
						data.message = "Settings file not found: " & local.settingsFile;
						break;
					}
					
					// Read the current settings file
					local.fileContent = fileRead(local.settingsFile);
					
					// Handle encryption if requested
					if (local.encrypt) {
						// For now, we'll use a simple base64 encoding as a placeholder
						// In production, you'd want to use proper encryption
						local.value = "encrypted:" & toBase64(local.value);
					}
					
					// Check if the setting already exists in the file
					local.settingPattern = 'set\s*\(\s*#local.key#\s*=';
					local.settingExists = reFindNoCase(local.settingPattern, local.fileContent);
					
					if (local.settingExists) {
						// Update existing setting
						// Find the line with this setting
						local.lines = listToArray(local.fileContent, chr(10));
						local.updated = false;
						
						for (local.i = 1; local.i <= arrayLen(local.lines); local.i++) {
							if (reFindNoCase(local.settingPattern, local.lines[local.i])) {
								// Determine the value format (string vs boolean vs numeric)
								if (isBoolean(local.value) && (local.value == "true" || local.value == "false")) {
									local.newLine = chr(9) & 'set(' & local.key & '=' & local.value & ');';
								} else if (isNumeric(local.value) && !local.encrypt) {
									local.newLine = chr(9) & 'set(' & local.key & '=' & local.value & ');';
								} else {
									// String value - need quotes
									local.newLine = chr(9) & 'set(' & local.key & '="' & local.value & '");';
								}
								local.lines[local.i] = local.newLine;
								local.updated = true;
								break;
							}
						}
						
						if (local.updated) {
							// Write the updated content back to the file
							local.newContent = arrayToList(local.lines, chr(10));
							fileWrite(local.settingsFile, local.newContent);
							
							data.success = true;
							data.message = "Configuration updated successfully. Key: " & local.key & " in " & local.environment & " environment.";
							data.updatedKey = local.key;
							data.environment = local.environment;
							data.encrypted = local.encrypt;
							
							// Check if reload is needed
							if (application.wheels.environment == local.environment || local.environment == "all") {
								data.reloadRequired = true;
								
								// Try to trigger reload if possible
								if (structKeyExists(application.wheels, "reloadPassword") && len(application.wheels.reloadPassword)) {
									data.message &= " Application reload required. Use ?reload=true&password=[reloadPassword] to reload.";
									data.reloadUrl = "?reload=true&password=[reloadPassword]";
								} else {
									data.message &= " Application reload required. Restart your application server or use the reload mechanism.";
								}
							}
						} else {
							data.message = "Could not update the setting in the file.";
						}
					} else {
						// Add new setting
						// Find the closing </cfscript> tag
						local.closeTagPos = findNoCase("</cfscript>", local.fileContent);
						
						if (local.closeTagPos > 0) {
							// Determine the value format
							if (isBoolean(local.value) && (local.value == "true" || local.value == "false")) {
								local.newSetting = chr(9) & 'set(' & local.key & '=' & local.value & ');' & chr(10);
							} else if (isNumeric(local.value) && !local.encrypt) {
								local.newSetting = chr(9) & 'set(' & local.key & '=' & local.value & ');' & chr(10);
							} else {
								// String value - need quotes
								local.newSetting = chr(9) & 'set(' & local.key & '="' & local.value & '");' & chr(10);
							}
							
							// Insert before the closing tag
							local.beforeTag = left(local.fileContent, local.closeTagPos - 1);
							local.afterTag = mid(local.fileContent, local.closeTagPos, len(local.fileContent));
							
							// Add a comment for new settings
							local.comment = chr(10) & chr(9) & '// Added by CLI on ' & dateFormat(now(), "yyyy-mm-dd") & ' ' & timeFormat(now(), "HH:mm:ss") & chr(10);
							
							local.newContent = local.beforeTag & local.comment & local.newSetting & local.afterTag;
							
							fileWrite(local.settingsFile, local.newContent);
							
							data.success = true;
							data.message = "New configuration added successfully. Key: " & local.key & " in " & local.environment & " environment.";
							data.addedKey = local.key;
							data.environment = local.environment;
							data.encrypted = local.encrypt;
							
							// Check if reload is needed
							if (application.wheels.environment == local.environment || local.environment == "all") {
								data.reloadRequired = true;
								
								// Try to trigger reload if possible
								if (structKeyExists(application.wheels, "reloadPassword") && len(application.wheels.reloadPassword)) {
									data.message &= " Application reload required. Use ?reload=true&password=[reloadPassword] to reload.";
									data.reloadUrl = "?reload=true&password=[reloadPassword]";
								} else {
									data.message &= " Application reload required. Restart your application server or use the reload mechanism.";
								}
							}
						} else {
							data.message = "Could not find proper location to add the setting in the file.";
						}
					}
					
					// Alternative: Try to clear specific caches if available
					if (data.success && structKeyExists(data, "reloadRequired") && data.reloadRequired) {
						try {
							// Clear any caches that might exist
							if (structKeyExists(application, "wheels") && structKeyExists(application.wheels, "cache")) {
								// Clear various caches
								if (structKeyExists(application.wheels.cache, "sql")) {
									structClear(application.wheels.cache.sql);
								}
								if (structKeyExists(application.wheels.cache, "image")) {
									structClear(application.wheels.cache.image);
								}
								if (structKeyExists(application.wheels.cache, "main")) {
									structClear(application.wheels.cache.main);
								}
								if (structKeyExists(application.wheels.cache, "action")) {
									structClear(application.wheels.cache.action);
								}
								if (structKeyExists(application.wheels.cache, "page")) {
									structClear(application.wheels.cache.page);
								}
								if (structKeyExists(application.wheels.cache, "partial")) {
									structClear(application.wheels.cache.partial);
								}
								if (structKeyExists(application.wheels.cache, "query")) {
									structClear(application.wheels.cache.query);
								}
								if (structKeyExists(application.wheels.cache, "sql")) {
									structClear(application.wheels.cache.sql);
								}
								
								data.message &= " Caches cleared.";
							}
						} catch (any cacheError) {
							// Ignore cache clearing errors
						}
					}
					
				} catch (any e) {
					data.success = false;
					data.message = "Error updating configuration: " & e.message;
					data.detail = e.detail;
				}
			break;

		}
	}
} catch (any e) {
	data.success = false;
	data.messages = e.message & ': ' & e.detail;
}

// Helper function to generate test data based on property name and type
function generateTestData(required string propertyName, string propertyType = "string", numeric index = 1) {
	// Common patterns for property names
	local.name = lCase(arguments.propertyName);
	
	// Email fields
	if (findNoCase("email", local.name)) {
		return "test#arguments.index#@example.com";
	}
	
	// Name fields
	if (findNoCase("firstname", local.name) || local.name == "fname") {
		local.firstNames = ["John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Edward", "Fiona", "George", "Helen"];
		return local.firstNames[(arguments.index - 1) mod arrayLen(local.firstNames) + 1];
	}
	
	if (findNoCase("lastname", local.name) || local.name == "lname") {
		local.lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"];
		return local.lastNames[(arguments.index - 1) mod arrayLen(local.lastNames) + 1];
	}
	
	if (local.name == "name" || findNoCase("username", local.name)) {
		return "TestUser#arguments.index#";
	}
	
	// Phone fields
	if (findNoCase("phone", local.name) || findNoCase("mobile", local.name)) {
		return "555-#numberFormat(1000 + arguments.index, '0000')#";
	}
	
	// Address fields
	if (findNoCase("address", local.name) || findNoCase("street", local.name)) {
		return "#arguments.index# Test Street";
	}
	
	if (findNoCase("city", local.name)) {
		local.cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego"];
		return local.cities[(arguments.index - 1) mod arrayLen(local.cities) + 1];
	}
	
	if (findNoCase("state", local.name) || findNoCase("province", local.name)) {
		local.states = ["CA", "TX", "FL", "NY", "PA", "IL", "OH", "GA"];
		return local.states[(arguments.index - 1) mod arrayLen(local.states) + 1];
	}
	
	if (findNoCase("zip", local.name) || findNoCase("postal", local.name)) {
		return numberFormat(10000 + arguments.index, "00000");
	}
	
	// URL fields
	if (findNoCase("url", local.name) || findNoCase("website", local.name)) {
		return "https://example#arguments.index#.com";
	}
	
	// Password fields
	if (findNoCase("password", local.name)) {
		return "TestPass#arguments.index#!";
	}
	
	// Boolean fields
	if (arguments.propertyType == "boolean" || findNoCase("active", local.name) || findNoCase("enabled", local.name) || findNoCase("published", local.name)) {
		return (arguments.index mod 2) == 1;
	}
	
	// Numeric fields
	if (arguments.propertyType == "integer" || arguments.propertyType == "numeric") {
		if (findNoCase("age", local.name)) {
			return 20 + (arguments.index mod 50);
		}
		if (findNoCase("price", local.name) || findNoCase("cost", local.name) || findNoCase("amount", local.name)) {
			return (arguments.index * 10) + 0.99;
		}
		if (findNoCase("quantity", local.name) || findNoCase("count", local.name)) {
			return arguments.index * 5;
		}
		return arguments.index;
	}
	
	// Date fields
	if (arguments.propertyType == "date" || arguments.propertyType == "datetime" || findNoCase("date", local.name) || findNoCase("birthday", local.name) || findNoCase("dob", local.name)) {
		return dateAdd("d", -arguments.index, now());
	}
	
	// Text/description fields
	if (arguments.propertyType == "text" || findNoCase("description", local.name) || findNoCase("content", local.name) || findNoCase("body", local.name)) {
		return "This is test content #arguments.index#. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
	}
	
	// Title fields
	if (findNoCase("title", local.name) || findNoCase("subject", local.name)) {
		return "Test Title #arguments.index#";
	}
	
	// Status fields
	if (findNoCase("status", local.name)) {
		local.statuses = ["pending", "active", "completed", "cancelled"];
		return local.statuses[(arguments.index - 1) mod arrayLen(local.statuses) + 1];
	}
	
	// Default string value
	return "#arguments.propertyName# Test #arguments.index#";
}
</cfscript>
<cfcontent reset="true" type="application/json"><cfoutput>#SerializeJSON(data)#</cfoutput>
<cfabort>
