<!--- CLI & GUI Uses this file to talk to wheels via JSON when in maintenance/testing/development mode --->
<cfscript>
setting showDebugOutput="no";
migrator = application.wheels.migrator;
try {
	local.cliCommand = StructKeyExists(request.wheels.params, "command") ? request.wheels.params.command : "";

	// ── Security gate (2026-06-09 review SEC-4) ─────────────────────────
	// State-changing commands must arrive as POST from loopback carrying
	// the reload password — a plain GET here was CSRF-reachable (an <img>
	// tag on any page a developer visits could drop every table via
	// dbReset). Read-only commands stay on GET for the CLI and legacy GUI.
	local.writesMigrationFiles = StructKeyExists(request.wheels.params, "write") && request.wheels.params.write == "true";
	if (Len(local.cliCommand) && $cliCommandIsMutating(local.cliCommand, local.writesMigrationFiles)) {
		local.gate = $cliMutationGateCheck(
			requestMethod = cgi.request_method,
			remoteAddr = cgi.remote_addr,
			forwardedFor = cgi.http_x_forwarded_for,
			// Form scope ONLY: request.wheels.params merges URL + form, so a
			// ?password=... query string would satisfy the gate while logging
			// the reload password in access logs / proxies — contradicting the
			// SEC-4 design of carrying it as a form field (#2947 review, #2977).
			password = StructKeyExists(form, "password") ? form.password : ""
		);
		if (!local.gate.allowed) {
			cfheader(statuscode = local.gate.statusCode);
			cfcontent(type = "application/json");
			WriteOutput(
				SerializeJSON({
					"success" = false,
					"command" = local.cliCommand,
					"message" = local.gate.error,
					"messages" = local.gate.error
				})
			);
			abort;
		}
	}

	// ── Lazy migration discovery (2026-06-09 review P10) ────────────────
	// getAvailableMigrations() instantiates every migration CFC (a $dbinfo
	// round-trip each) and $getDBType() costs another probe, so only the
	// commands that actually consume them pay — `routes`, `introspect`, and
	// the jobs* commands job workers poll every few seconds skip discovery
	// entirely. An empty command keeps the full legacy ping payload.
	local.needsMigrations = !Len(local.cliCommand)
		|| ListFindNoCase("info,migrateUp,migrateDown,redoMigration,dbStatus,dbRollback", local.cliCommand) > 0;
	local.needsVersion = local.needsMigrations || CompareNoCase(local.cliCommand, "dbVersion") == 0;
	local.needsDbType = !Len(local.cliCommand)
		|| ListFindNoCase("info,doctor,dbSchema,dbCreate,dbReset,dbDump,dbRestore,dbShell", local.cliCommand) > 0;

	"data" = {};
	data["success"] = true;
	data["datasource"] = application.wheels.dataSourceName;
	data["wheelsVersion"] = application.wheels.version;
	data["currentVersion"] = local.needsVersion ? migrator.getCurrentMigrationVersion() : "";
	data["databaseType"] = local.needsDbType ? $cliDatabaseType() : "";
	data["migrations"] = local.needsMigrations ? migrator.getAvailableMigrations() : [];
	data["lastVersion"] = 0;
	data["message"] = "";
	data["messages"] = "";
	data["command"] = "";

	if (ArrayLen(data.migrations)) {
		data.lastVersion = data.migrations[ArrayLen(data.migrations)].version;
	}

	if (Len(local.cliCommand)) {
		data.command = local.cliCommand;
		switch (local.cliCommand) {
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
			case "migrateUp":
				// Walk the migration list (sorted ascending by version) and
				// migrate to the first pending version after the current one.
				// `migrateTo` handles the actual transaction + status update.
				local.targetVersion = "";
				for (local.m in data.migrations) {
					if (local.m.status != "migrated" && local.m.version > data.currentVersion) {
						local.targetVersion = local.m.version;
						break;
					}
				}
				if (Len(local.targetVersion)) {
					data.message = migrator.migrateTo(local.targetVersion);
				} else {
					data.message = "No pending migrations. Database is at version #data.currentVersion#.";
				}
				break;
			case "migrateDown":
				// Walk the list in reverse to find the migration immediately
				// below the current version, then migrate down to it. If the
				// current version is the first applied migration, target "0"
				// (rolls back the only migration).
				local.targetVersion = "0";
				for (local.i = ArrayLen(data.migrations); local.i >= 1; local.i--) {
					local.m = data.migrations[local.i];
					if (local.m.version < data.currentVersion && local.m.status == "migrated") {
						local.targetVersion = local.m.version;
						break;
					}
				}
				if (data.currentVersion == "0") {
					data.message = "Database is at version 0; nothing to roll back.";
				} else {
					data.message = migrator.migrateTo(local.targetVersion);
				}
				break;
			case "renameSystemTables":
				// F15 Phase 2: opt-in rename of legacy c_o_r_e_* system tables.
				// Returns the full result struct (success/renamed/skipped/errors/sql)
				// rather than a flat message — the CLI decodes and prints each field.
				local.dryRun = (StructKeyExists(request.wheels.params, "dryRun") && request.wheels.params.dryRun == "true");
				data.renameResult = migrator.renameSystemTables(dryRun = local.dryRun);
				data.success = data.renameResult.success;
				if (Len(data.renameResult.skipped)) {
					data.message = data.renameResult.skipped;
				} else if (ArrayLen(data.renameResult.renamed)) {
					data.message = "Renamed: " & ArrayToList(data.renameResult.renamed, "; ");
				} else if (local.dryRun && ArrayLen(data.renameResult.sql)) {
					data.message = "Dry run — SQL that would execute:" & Chr(10) & ArrayToList(data.renameResult.sql, ";" & Chr(10)) & ";";
				}
				break;
			case "diff":
				try {
					local.autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
					local.options = {};

					// Parse hints from URL: hints={"renames":{"old":"new"}} as JSON-encoded string
					if (StructKeyExists(request.wheels.params, "hints") && Len(request.wheels.params.hints)) {
						local.decodedHints = DeserializeJSON(request.wheels.params.hints);
						if (IsStruct(local.decodedHints)) {
							StructAppend(local.options, local.decodedHints, true);
						}
					}
					if (StructKeyExists(request.wheels.params, "threshold") && Len(request.wheels.params.threshold) && IsNumeric(request.wheels.params.threshold)) {
						local.options.heuristicThreshold = request.wheels.params.threshold;
					}

					if (StructKeyExists(request.wheels.params, "modelName") && Len(request.wheels.params.modelName)) {
						local.diffResult = local.autoMigrator.diff(request.wheels.params.modelName, local.options);

						// Optionally write the migration file
						local.migrationWritten = "";
						if (StructKeyExists(request.wheels.params, "write") && request.wheels.params.write == "true") {
							local.migName = StructKeyExists(request.wheels.params, "name") && Len(request.wheels.params.name) ? request.wheels.params.name : "";
							local.autoMigrator.writeMigration(local.diffResult, local.migName);
							local.migrationWritten = "written";
						}

						data.success = true;
						data.model = local.diffResult;
						data.migrationWritten = local.migrationWritten;
					} else {
						// diffAll path
						local.diffAllResult = local.autoMigrator.diffAll(local.options);

						local.written = [];
						if (StructKeyExists(request.wheels.params, "write") && request.wheels.params.write == "true") {
							for (local.m in local.diffAllResult) {
								local.autoMigrator.writeMigration(local.diffAllResult[local.m], "");
								ArrayAppend(local.written, local.m);
							}
						}

						data.success = true;
						data.models = local.diffAllResult;
						data.migrationsWritten = local.written;
					}
				} catch (any e) {
					data.success = false;
					data.error = e.type;
					data.message = e.message;
				}
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
				// Build a human-readable status block. The migrations list
				// is rendered by Migrator.$buildInfoOutput() so the logic
				// is unit-testable without exercising the HTTP dispatcher.
				// Issue #2780 surfaced orphan versions (DB rows with no
				// matching file) — those are rendered with a [?] marker
				// and an explanatory footer.
				local.lines = [];
				ArrayAppend(local.lines, "Datasource: " & data.datasource);
				ArrayAppend(local.lines, "Database type: " & data.databaseType);
				for (local.line in migrator.$buildInfoOutput()) {
					ArrayAppend(local.lines, local.line);
				}
				data.message = ArrayToList(local.lines, Chr(10));
				break;
			case "doctor":
				// Comprehensive migrator health diagnostic. Returns a struct
				// describing orphans, pending, and applied counts. See #2780.
				// Plan 3: orphansWithMeta exposes the peer's migration name
				// + apply timestamp when the schema is enriched.
				local.report = migrator.doctor();
				data.healthy = local.report.healthy;
				data.currentVersion = local.report.currentVersion;
				data.orphans = local.report.orphans;
				data.orphansWithMeta = local.report.orphansWithMeta;
				data.pending = local.report.pending;
				data.summary = local.report.summary;
				local.docLines = [];
				ArrayAppend(local.docLines, local.report.message);
				ArrayAppend(local.docLines, "");
				ArrayAppend(local.docLines, "  Datasource: " & data.datasource);
				ArrayAppend(local.docLines, "  Database type: " & data.databaseType);
				ArrayAppend(local.docLines, "  Current version: " & (Len(local.report.currentVersion) ? local.report.currentVersion : "0"));
				ArrayAppend(local.docLines, "  Total migrations: " & local.report.summary.total);
				ArrayAppend(local.docLines, "    applied: " & local.report.summary.applied);
				ArrayAppend(local.docLines, "    pending: " & local.report.summary.pending);
				if (local.report.summary.orphan > 0) {
					ArrayAppend(local.docLines, "    orphan:  " & local.report.summary.orphan & " (" & ArrayToList(local.report.orphans, ", ") & ")");
				}
				if (ArrayLen(local.report.pending) > 0) {
					ArrayAppend(local.docLines, "");
					ArrayAppend(local.docLines, "Pending local migrations:");
					for (local.v in local.report.pending) {
						ArrayAppend(local.docLines, "  [ ] " & local.v);
					}
				}
				if (ArrayLen(local.report.orphansWithMeta) > 0) {
					ArrayAppend(local.docLines, "");
					ArrayAppend(local.docLines, "Orphan versions (no matching file):");
					for (local.o in local.report.orphansWithMeta) {
						local.orphanLine = "  [?] " & local.o.version;
						if (Len(local.o.name)) {
							local.orphanLine &= " " & local.o.name;
						}
						if (Len(local.o.appliedAt)) {
							local.orphanLine &= " (applied " & local.o.appliedAt & ")";
						}
						ArrayAppend(local.docLines, local.orphanLine);
					}
					ArrayAppend(local.docLines, "");
					ArrayAppend(local.docLines, "Resolve: `wheels migrate forget <version> --yes` to remove an orphan row,");
					ArrayAppend(local.docLines, "         or pull the peer's migration file via git.");
				}
				data.message = ArrayToList(local.docLines, Chr(10));
				break;
			case "forgetVersion":
				// Remove a row from wheels_migrator_versions without running
				// down(). Refuses if the version has a matching local file.
				local.versionArg = request.wheels.params.version ?: "";
				if (!Len(local.versionArg)) {
					data.success = false;
					data.message = "Missing required argument: version. Usage: wheels migrate forget <version>";
					break;
				}
				local.forgetResult = migrator.forgetVersion(local.versionArg);
				data.success = local.forgetResult.success;
				data.removed = local.forgetResult.removed;
				data.message = local.forgetResult.message;
				break;
			case "pretendVersion":
				// Record a version as applied without running up(). Refuses
				// if already applied or if no local file matches.
				local.pretendArg = request.wheels.params.version ?: "";
				if (!Len(local.pretendArg)) {
					data.success = false;
					data.message = "Missing required argument: version. Usage: wheels migrate pretend <version>";
					break;
				}
				local.pretendResult = migrator.pretendVersion(local.pretendArg);
				data.success = local.pretendResult.success;
				data.recorded = local.pretendResult.recorded;
				data.message = local.pretendResult.message;
				break;

			// Database commands
			case "dbStatus":
				// Return migration status straight from the migrator's own
				// status field — see Public.cfc::$cliFormatMigrationStatus()
				// for why the old version-comparison heuristic was wrong.
				// Reuses the list discovered in the preamble instead of
				// running discovery a second time.
				local.statusReport = $cliFormatMigrationStatus(data.migrations);
				data.success = true;
				data.migrations = local.statusReport.migrations;
				data.summary = local.statusReport.summary;
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
				
				// Find target version based on steps. Reuses the list
				// discovered in the preamble instead of re-discovering.
				// Filter on tracked status, not version <= current: on a shared
				// dev DB a peer-applied version above your latest local file
				// made the version heuristic count pending/orphan rows as
				// applied, so `steps=N` rolled back fewer real migrations
				// (same P3 fix dbStatus got in #2947; #2977).
				local.appliedMigrations = [];
				for (local.migration in data.migrations) {
					if (local.migration.status == "migrated") {
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
					// Use database adapter to get schema information
					local.adapter = application.wheels.dataAdapter;
					data.schema.databaseType = data.databaseType;
					data.schema.tables = [];
					
					// Get all tables
					local.tables = [];
					if (data.databaseType == "H2") {
						// H2 specific query
						local.tablesQuery = new Query();
						local.tablesQuery.setDatasource(application.wheels.dataSourceName);
						local.tablesQuery.setSQL("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'TABLE' AND TABLE_SCHEMA = 'PUBLIC'");
						local.tables = local.tablesQuery.execute().getResult();
					} else {
						// Generic INFORMATION_SCHEMA query
						local.tablesQuery = new Query();
						local.tablesQuery.setDatasource(application.wheels.dataSourceName);
						local.tablesQuery.setSQL("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'");
						local.tables = local.tablesQuery.execute().getResult();
					}
					
					for (local.table in local.tables) {
						local.tableInfo = {
							name = local.table.TABLE_NAME,
							columns = []
						};
						
						// Get columns for each table
						local.columns = new Query();
						local.columns.setDatasource(application.wheels.dataSourceName);
						if (data.databaseType == "H2") {
							local.columns.setSQL("SELECT COLUMN_NAME, TYPE_NAME as DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = :tableName AND TABLE_SCHEMA = 'PUBLIC'");
						} else {
							local.columns.setSQL("SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = :tableName");
						}
						local.columns.addParam(name="tableName", value=local.table.TABLE_NAME, cfsqltype="cf_sql_varchar");
						local.columnResult = local.columns.execute().getResult();
						
						for (local.column in local.columnResult) {
							arrayAppend(local.tableInfo.columns, {
								name = local.column.COLUMN_NAME,
								type = local.column.DATA_TYPE,
								nullable = local.column.IS_NULLABLE,
								default = local.column.COLUMN_DEFAULT ?: ""
							});
						}
						
						arrayAppend(data.schema.tables, local.tableInfo);
					}
				} catch (any e) {
					data.success = false;
					data.message = "Error retrieving schema: " & e.message;
				}
				break;

			case "introspect":
				data.success = false;
				if (!structKeyExists(request.wheels.params, "model") || !len(request.wheels.params.model)) {
					data.message = "Missing required parameter: model";
					break;
				}

				try {
					local.modelName = request.wheels.params.model;
					local.modelInstance = model(local.modelName);
					local.classData = local.modelInstance.$classData();

					data.model = local.modelName;
					data.tableName = local.classData.tableName ?: lCase(local.modelName) & "s";
					data.primaryKey = local.classData.keys ?: "id";

					data.columns = [];
					if (structKeyExists(local.classData, "properties")) {
						for (local.propName in local.classData.properties) {
							local.prop = local.classData.properties[local.propName];
							local.colInfo = {
								name: local.propName,
								type: local.prop.type ?: "string",
								primaryKey: listFindNoCase(data.primaryKey, local.propName) > 0
							};
							if (structKeyExists(local.prop, "maxLength") && val(local.prop.maxLength) > 0) {
								local.colInfo.maxLength = local.prop.maxLength;
							}
							if (right(local.propName, 2) == "Id" && len(local.propName) > 2) {
								local.colInfo.foreignKey = true;
								local.refName = left(local.propName, len(local.propName) - 2);
								local.colInfo.referencedModel = uCase(left(local.refName, 1)) & mid(local.refName, 2, len(local.refName) - 1);
							}
							arrayAppend(data.columns, local.colInfo);
						}
					}

					data.associations = [];
					if (structKeyExists(local.classData, "associations")) {
						for (local.assocName in local.classData.associations) {
							local.assoc = local.classData.associations[local.assocName];
							local.assocModelName = local.assoc.modelName ?: local.assocName;
							local.assocModelName = uCase(left(local.assocModelName, 1)) & mid(local.assocModelName, 2, len(local.assocModelName) - 1);
							arrayAppend(data.associations, {
								type: local.assoc.type ?: "belongsTo",
								name: local.assocName,
								modelName: local.assocModelName
							});
						}
					}

					data.success = true;
					data.message = "Model introspected successfully";
				} catch (any e) {
					data.message = "Error introspecting model: " & e.message;
				}
				break;

			case "dbSeed":
				// The seed orchestration lives in the page-level
				// runDbSeed() UDF (defined alongside generateTestData
				// below). Extracted so `dbSetup` can compose seeding
				// without re-entering the dispatcher (issue ##2959).
				local.seedResult = runDbSeed(request.wheels.params);
				StructAppend(data, local.seedResult, true);
				break;
				
			case "routes":
				// Return application routes. Routes live at application.wheels.routes
				// (the convention every other case in this file uses); the previous
				// `application[application.wheels.appKey]` indirection was broken
				// because `appKey` is a function, not a property.
				data.success = true;
				data.routes = [];
				if (structKeyExists(application, "wheels") && structKeyExists(application.wheels, "routes")) {
					for (local.route in application.wheels.routes) {
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

				try {
					local.migrateResult = migrator.migrateToLatest();
					data.message &= "Migrations completed. ";

					if (structKeyExists(request.wheels.params, "seed") && request.wheels.params.seed) {
						// Compose seeding through a direct UDF call —
						// the legacy path mutated `request.wheels.params`
						// and re-included `cli.cfm`, which rebuilt the
						// envelope from scratch and silently discarded
						// the "Migrations completed." string we just set
						// (issue ##2959). Merge the seed result on top
						// of `data` while preserving the dbSetup envelope
						// (command, prefixed message, combined success).
						local.seedParams = Duplicate(request.wheels.params);
						local.seedParams.count = StructKeyExists(request.wheels.params, "seedCount")
							? val(request.wheels.params.seedCount) : 10;
						local.seedResult = runDbSeed(local.seedParams);
						local.setupMessage = data.message;
						StructAppend(data, local.seedResult, true);
						data.command = "dbSetup";
						data.message = local.setupMessage & local.seedResult.message;
						if (!local.seedResult.success) {
							data.success = false;
						}
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
						
						// If output file specified, save it. The path is
						// canonicalized and confined to the application root
						// (2026-06-09 review SEC-5) — `../` traversal would
						// otherwise make this an arbitrary-location file write.
						if (structKeyExists(request.wheels.params, "output")) {
							local.outputFile = $cliResolveDumpPath(request.wheels.params.output);
							if (Len(local.outputFile)) {
								fileWrite(local.outputFile, local.sqlDump);
								data.message = "Database dump saved to: " & request.wheels.params.output;
							} else {
								data.success = false;
								data.message = "Invalid output path: the dump file must resolve inside the application root.";
							}
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

					// NOTE: an earlier revision tried to execute
					// request.wheels.params.command as SQL here, but that
					// param is always the literal dispatch value "dbShell",
					// so the branch executed "dbShell" as SQL, always threw,
					// and clobbered the help text above with an error
					// (2026-06-09 review P1). An SQL pass-through would also
					// need the POST + reload-password gate; use the console
					// (`wheels console`) for ad-hoc statements instead.
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

			// ── Job Worker Commands ──────────────────────────────────────

			case "jobsProcessNext":
				// Process the next available job (used by `wheels jobs work`)
				try {
					local.worker = new wheels.JobWorker();
					local.jobQueues = structKeyExists(request.wheels.params, "queues") ? request.wheels.params.queues : "";
					local.jobTimeout = structKeyExists(request.wheels.params, "timeout") ? val(request.wheels.params.timeout) : 300;
					local.jobResult = local.worker.processNext(queues=local.jobQueues, timeout=local.jobTimeout);
					data.success = true;
					data.jobResult = local.jobResult;
					data.message = local.jobResult.skipped ? "No jobs available" : "Processed job #local.jobResult.jobId#";
				} catch (any e) {
					data.success = false;
					data.message = "Error processing job: " & e.message;
				}
				break;

			case "jobsStatus":
				// Get queue statistics (used by `wheels jobs status`)
				try {
					local.worker = new wheels.JobWorker();
					local.jobQueue = structKeyExists(request.wheels.params, "queue") ? request.wheels.params.queue : "";
					data.success = true;
					data.stats = local.worker.getStats(queue=local.jobQueue);
					data.message = "Queue statistics retrieved";
				} catch (any e) {
					data.success = false;
					data.message = "Error getting status: " & e.message;
				}
				break;

			case "jobsRetry":
				// Retry failed jobs (used by `wheels jobs retry`)
				try {
					local.worker = new wheels.JobWorker();
					local.jobQueue = structKeyExists(request.wheels.params, "queue") ? request.wheels.params.queue : "";
					local.jobLimit = structKeyExists(request.wheels.params, "limit") ? val(request.wheels.params.limit) : 0;
					local.retryCount = local.worker.retryFailed(queue=local.jobQueue, limit=local.jobLimit);
					data.success = true;
					data.retried = local.retryCount;
					data.message = "Retried #local.retryCount# failed job(s)";
				} catch (any e) {
					data.success = false;
					data.message = "Error retrying jobs: " & e.message;
				}
				break;

			case "jobsPurge":
				// Purge old jobs (used by `wheels jobs purge`)
				try {
					local.worker = new wheels.JobWorker();
					local.jobQueue = structKeyExists(request.wheels.params, "queue") ? request.wheels.params.queue : "";
					local.purgeStatus = structKeyExists(request.wheels.params, "status") ? request.wheels.params.status : "completed";
					local.purgeDays = structKeyExists(request.wheels.params, "days") ? val(request.wheels.params.days) : 7;
					local.purgeCount = local.worker.purge(status=local.purgeStatus, days=local.purgeDays, queue=local.jobQueue);
					data.success = true;
					data.purged = local.purgeCount;
					data.message = "Purged #local.purgeCount# #local.purgeStatus# job(s)";
				} catch (any e) {
					data.success = false;
					data.message = "Error purging jobs: " & e.message;
				}
				break;

			case "jobsMonitor":
				// Get monitoring data (used by `wheels jobs monitor`)
				try {
					local.worker = new wheels.JobWorker();
					local.jobQueue = structKeyExists(request.wheels.params, "queue") ? request.wheels.params.queue : "";
					local.minutes = structKeyExists(request.wheels.params, "minutes") ? val(request.wheels.params.minutes) : 60;
					data.success = true;
					data.monitor = local.worker.getMonitorData(queue=local.jobQueue, minutes=local.minutes);
					data.stats = local.worker.getStats(queue=local.jobQueue);
					local.timeouts = local.worker.checkTimeouts();
					if (local.timeouts > 0) {
						data.timeoutsRecovered = local.timeouts;
					}
					data.message = "Monitor data retrieved";
				} catch (any e) {
					data.success = false;
					data.message = "Error getting monitor data: " & e.message;
				}
				break;

		}
	}
} catch (any e) {
	data.success = false;
	// Envelope consistency: per-command catches surface their failure via
	// `data.message` (singular); the outer catch historically only set
	// `data.messages` (plural), so a CLI client reading either name in
	// isolation missed half the failure modes (issue ##2959). Mirror the
	// error on both keys so the plural stays backward-compatible while
	// the singular matches every other code path.
	data.message = e.message & ': ' & e.detail;
	data.messages = data.message;
}

// Seed orchestration extracted from the `dbSeed` switch case so that
// `dbSetup` can compose seeding through a direct call instead of the
// legacy recursive cfinclude (issue ##2959). Returns a struct with
// {success, mode, message, ...mode-specific fields} that the caller
// merges into the response envelope via StructAppend.
function runDbSeed(struct seedParams = {}) {
	var result = {success = true, mode = "auto", message = ""};
	var sp = arguments.seedParams;
	var requestedMode = structKeyExists(sp, "mode") ? sp.mode : "auto";
	var environment = structKeyExists(sp, "environment") ? sp.environment : get("environment");
	result.mode = requestedMode;

	try {
		var useConvention = false;
		if (requestedMode == "convention") {
			useConvention = true;
		} else if (requestedMode == "generate") {
			useConvention = false;
		} else if (structKeyExists(application.wheels, "seeder") && application.wheels.seeder.hasSeedFiles()) {
			useConvention = true;
		}

		if (useConvention) {
			result.mode = "convention";
			var seeder = application.wheels.seeder;
			var conventionResult = seeder.runSeeds(environment = environment);
			result.success = conventionResult.success;
			result.message = conventionResult.message;
			result.environment = environment;
			result.totalCreated = conventionResult.totalCreated;
			result.totalSkipped = conventionResult.totalSkipped;
			if (structKeyExists(conventionResult, "totalFailed")) {
				result.totalFailed = conventionResult.totalFailed;
			}
			result.results = conventionResult.results;
			if (structKeyExists(conventionResult, "detail")) {
				result.detail = conventionResult.detail;
			}
		} else {
			result.mode = "generate";
			var count = structKeyExists(sp, "count") ? val(sp.count) : 10;
			var modelsArg = structKeyExists(sp, "models") ? sp.models : "";
			result.seeded = [];

			var modelList = [];
			if (len(modelsArg)) {
				modelList = listToArray(modelsArg);
			} else {
				var modelPath = expandPath("/app/models");
				if (directoryExists(modelPath)) {
					var modelFiles = directoryList(modelPath, false, "name", "*.cfc");
					for (var file in modelFiles) {
						if (left(file, 1) != "_") {
							arrayAppend(modelList, listFirst(file, "."));
						}
					}
				}
			}

			for (var modelName in modelList) {
				try {
					var modelInstance = model(modelName);
					var seededCount = 0;
					var properties = [];
					if (structKeyExists(modelInstance, "$classData") && structKeyExists(modelInstance.$classData(), "properties")) {
						properties = modelInstance.$classData().properties;
					}
					for (var i = 1; i <= count; i++) {
						var record = {};
						for (var prop in properties) {
							if (prop.name != "id" && !listFindNoCase("createdAt,updatedAt,deletedAt", prop.name)) {
								record[prop.name] = generateTestData(prop.name, prop.type, i);
							}
						}
						var newRecord = modelInstance.new(record);
						if (newRecord.save()) {
							seededCount++;
						}
					}
					arrayAppend(result.seeded, {
						model = modelName,
						count = seededCount,
						success = true
					});
				} catch (any modelError) {
					arrayAppend(result.seeded, {
						model = modelName,
						count = 0,
						success = false,
						error = modelError.message
					});
				}
			}

			var totalSeeded = 0;
			for (var seedEntry in result.seeded) {
				if (seedEntry.success) {
					totalSeeded += seedEntry.count;
				}
			}
			result.message = "Database seeding completed. Created #totalSeeded# records across #arrayLen(result.seeded)# models.";
		}
	} catch (any e) {
		result.success = false;
		result.message = "Error during database seeding: " & e.message;
	}

	return result;
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
