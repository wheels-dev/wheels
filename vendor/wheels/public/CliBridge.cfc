/**
 * CliBridge — dev-UI / CLI command handlers, extracted from the former
 * 935-line `vendor/wheels/public/views/cli.cfm` god template (issue #2959,
 * review finding P2).
 *
 * cli.cfm is now a thin dispatcher: it builds the response envelope preamble
 * (security gate, lazy migration discovery, version/db-type), constructs a
 * `context` struct, then asks this service to run the command. Each command
 * is one method here, so the handlers are individually unit-testable — the
 * regression net the template never had.
 *
 * Dispatch is allowlist-gated: `variables.commandMap` maps a command name to
 * a handler method name, and `dispatch()` only ever `invoke()`s a method that
 * appears in that map. `params` is passed to handlers as a single named
 * argument (never spread), so a query-string key cannot become an arbitrary
 * function argument (the remote arg-injection risk flagged in the #2959
 * cross-framework research).
 *
 * The component is stateless (only the immutable `commandMap` lives in
 * `variables`), so a single instance is cached on `application.wheels` and
 * shared across concurrent requests; `?reload=true` rebuilds `application`
 * and re-creates it. Framework primitives the handlers need (`model()`,
 * `get()`, `$cliFormatMigrationStatus()`, `$cliResolveDumpPath()`) are reached
 * through `context.host` — the `wheels.Public` instance that includes cli.cfm.
 *
 * Context shape (built by cli.cfm):
 *   { host, migrator, datasource, databaseType, currentVersion,
 *     lastVersion, migrations }
 *
 * Each handler returns a partial struct that the dispatcher merges into the
 * response envelope via `StructAppend(data, result, true)`.
 */
component output="false" displayName="CLI Bridge" {

	public any function init() {
		// Allowlist: command name -> handler method name. Command names match
		// method names, but the explicit map (not a name-equality shortcut) is
		// what prevents `init`, `dispatch`, `handles`, or any other component
		// method from being reachable as a command.
		variables.commandMap = {
			// Migration commands
			"createMigration" = "createMigration",
			"migrateTo" = "migrateTo",
			"migrateToLatest" = "migrateToLatest",
			"migrateUp" = "migrateUp",
			"migrateDown" = "migrateDown",
			"renameSystemTables" = "renameSystemTables",
			"diff" = "diff",
			"redoMigration" = "redoMigration",
			"info" = "info",
			"doctor" = "doctor",
			"forgetVersion" = "forgetVersion",
			"pretendVersion" = "pretendVersion",
			// Database commands
			"dbStatus" = "dbStatus",
			"dbVersion" = "dbVersion",
			"dbRollback" = "dbRollback",
			"dbSchema" = "dbSchema",
			"introspect" = "introspect",
			"dbSeed" = "dbSeed",
			"routes" = "routes",
			"dbCreate" = "dbCreate",
			"dbDrop" = "dbDrop",
			"dbReset" = "dbReset",
			"dbSetup" = "dbSetup",
			"dbDump" = "dbDump",
			"dbRestore" = "dbRestore",
			"dbShell" = "dbShell",
			// Job worker commands
			"jobsProcessNext" = "jobsProcessNext",
			"jobsStatus" = "jobsStatus",
			"jobsRetry" = "jobsRetry",
			"jobsPurge" = "jobsPurge",
			"jobsMonitor" = "jobsMonitor"
		};
		return this;
	}

	/**
	 * Whether `command` is a declared, dispatchable command.
	 */
	public boolean function handles(required string command) {
		return Len(arguments.command) && StructKeyExists(variables.commandMap, arguments.command);
	}

	/**
	 * Run a command. Throws `Wheels.UnknownCliCommand` if the command is not on
	 * the allowlist — callers gate on `handles()` first to preserve the legacy
	 * "unknown command is a silent no-op" envelope behaviour.
	 */
	public struct function dispatch(required string command, required struct context, required struct params) {
		if (!handles(arguments.command)) {
			Throw(
				type = "Wheels.UnknownCliCommand",
				message = "Unknown CLI command: " & arguments.command
			);
		}
		local.method = variables.commandMap[arguments.command];
		return invoke(this, local.method, {context = arguments.context, params = arguments.params});
	}

	// ── Migration commands ──────────────────────────────────────────────

	public struct function createMigration(required struct context, required struct params) {
		local.rv = {};
		if (StructKeyExists(arguments.params, "migrationPrefix") && Len(arguments.params.migrationPrefix)) {
			local.rv.message = arguments.context.migrator.createMigration(
				arguments.params.migrationName,
				arguments.params.templateName,
				arguments.params.migrationPrefix
			);
		} else {
			local.rv.message = arguments.context.migrator.createMigration(
				arguments.params.migrationName,
				arguments.params.templateName
			);
		}
		return local.rv;
	}

	public struct function migrateTo(required struct context, required struct params) {
		local.rv = {};
		if (StructKeyExists(arguments.params, "version")) {
			local.rv.message = arguments.context.migrator.migrateTo(arguments.params.version);
		}
		return local.rv;
	}

	public struct function migrateToLatest(required struct context, required struct params) {
		return {message = arguments.context.migrator.migrateToLatest()};
	}

	public struct function migrateUp(required struct context, required struct params) {
		// Walk the migration list (sorted ascending by version) and migrate to
		// the first pending version after the current one.
		local.rv = {};
		local.targetVersion = "";
		for (local.m in arguments.context.migrations) {
			if (local.m.status != "migrated" && local.m.version > arguments.context.currentVersion) {
				local.targetVersion = local.m.version;
				break;
			}
		}
		if (Len(local.targetVersion)) {
			local.rv.message = arguments.context.migrator.migrateTo(local.targetVersion);
		} else {
			local.rv.message = "No pending migrations. Database is at version #arguments.context.currentVersion#.";
		}
		return local.rv;
	}

	public struct function migrateDown(required struct context, required struct params) {
		// Walk the list in reverse to find the migration immediately below the
		// current version, then migrate down to it.
		local.rv = {};
		local.targetVersion = "0";
		for (local.i = ArrayLen(arguments.context.migrations); local.i >= 1; local.i--) {
			local.m = arguments.context.migrations[local.i];
			if (local.m.version < arguments.context.currentVersion && local.m.status == "migrated") {
				local.targetVersion = local.m.version;
				break;
			}
		}
		if (arguments.context.currentVersion == "0") {
			local.rv.message = "Database is at version 0; nothing to roll back.";
		} else {
			local.rv.message = arguments.context.migrator.migrateTo(local.targetVersion);
		}
		return local.rv;
	}

	public struct function renameSystemTables(required struct context, required struct params) {
		// F15 Phase 2: opt-in rename of legacy c_o_r_e_* system tables.
		local.rv = {};
		local.dryRun = (StructKeyExists(arguments.params, "dryRun") && arguments.params.dryRun == "true");
		local.rv.renameResult = arguments.context.migrator.renameSystemTables(dryRun = local.dryRun);
		local.rv.success = local.rv.renameResult.success;
		if (Len(local.rv.renameResult.skipped)) {
			local.rv.message = local.rv.renameResult.skipped;
		} else if (ArrayLen(local.rv.renameResult.renamed)) {
			local.rv.message = "Renamed: " & ArrayToList(local.rv.renameResult.renamed, "; ");
		} else if (local.dryRun && ArrayLen(local.rv.renameResult.sql)) {
			local.rv.message = "Dry run — SQL that would execute:" & Chr(10) & ArrayToList(local.rv.renameResult.sql, ";" & Chr(10)) & ";";
		}
		return local.rv;
	}

	public struct function diff(required struct context, required struct params) {
		local.rv = {};
		try {
			local.autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
			local.options = {};

			// Parse hints from URL: hints={"renames":{"old":"new"}} as JSON.
			if (StructKeyExists(arguments.params, "hints") && Len(arguments.params.hints)) {
				local.decodedHints = DeserializeJSON(arguments.params.hints);
				if (IsStruct(local.decodedHints)) {
					StructAppend(local.options, local.decodedHints, true);
				}
			}
			if (StructKeyExists(arguments.params, "threshold") && Len(arguments.params.threshold) && IsNumeric(arguments.params.threshold)) {
				local.options.heuristicThreshold = arguments.params.threshold;
			}

			if (StructKeyExists(arguments.params, "modelName") && Len(arguments.params.modelName)) {
				local.diffResult = local.autoMigrator.diff(arguments.params.modelName, local.options);

				// Optionally write the migration file.
				local.migrationWritten = "";
				if (StructKeyExists(arguments.params, "write") && arguments.params.write == "true") {
					local.migName = StructKeyExists(arguments.params, "name") && Len(arguments.params.name) ? arguments.params.name : "";
					local.autoMigrator.writeMigration(local.diffResult, local.migName);
					local.migrationWritten = "written";
				}

				local.rv.success = true;
				local.rv.model = local.diffResult;
				local.rv.migrationWritten = local.migrationWritten;
			} else {
				// diffAll path
				local.diffAllResult = local.autoMigrator.diffAll(local.options);

				local.written = [];
				if (StructKeyExists(arguments.params, "write") && arguments.params.write == "true") {
					for (local.m in local.diffAllResult) {
						local.autoMigrator.writeMigration(local.diffAllResult[local.m], "");
						ArrayAppend(local.written, local.m);
					}
				}

				local.rv.success = true;
				local.rv.models = local.diffAllResult;
				local.rv.migrationsWritten = local.written;
			}
		} catch (any e) {
			local.rv.success = false;
			local.rv.error = e.type;
			local.rv.message = e.message;
		}
		return local.rv;
	}

	public struct function redoMigration(required struct context, required struct params) {
		local.rv = {};
		if (StructKeyExists(arguments.params, "version")) {
			local.redoVersion = arguments.params.version;
		} else {
			local.redoVersion = arguments.context.lastVersion;
		}
		local.rv.message = arguments.context.migrator.redoMigration(local.redoVersion);
		return local.rv;
	}

	public struct function info(required struct context, required struct params) {
		// Build a human-readable status block; the migrations list is rendered
		// by Migrator.$buildInfoOutput() so the logic is unit-testable.
		local.rv = {};
		local.lines = [];
		ArrayAppend(local.lines, "Datasource: " & arguments.context.datasource);
		ArrayAppend(local.lines, "Database type: " & arguments.context.databaseType);
		for (local.line in arguments.context.migrator.$buildInfoOutput()) {
			ArrayAppend(local.lines, local.line);
		}
		local.rv.message = ArrayToList(local.lines, Chr(10));
		return local.rv;
	}

	public struct function doctor(required struct context, required struct params) {
		// Comprehensive migrator health diagnostic (#2780).
		local.rv = {};
		local.report = arguments.context.migrator.doctor();
		local.rv.healthy = local.report.healthy;
		local.rv.currentVersion = local.report.currentVersion;
		local.rv.orphans = local.report.orphans;
		local.rv.orphansWithMeta = local.report.orphansWithMeta;
		local.rv.pending = local.report.pending;
		local.rv.summary = local.report.summary;
		local.docLines = [];
		ArrayAppend(local.docLines, local.report.message);
		ArrayAppend(local.docLines, "");
		ArrayAppend(local.docLines, "  Datasource: " & arguments.context.datasource);
		ArrayAppend(local.docLines, "  Database type: " & arguments.context.databaseType);
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
		local.rv.message = ArrayToList(local.docLines, Chr(10));
		return local.rv;
	}

	public struct function forgetVersion(required struct context, required struct params) {
		// Remove a row from wheels_migrator_versions without running down().
		local.rv = {};
		local.versionArg = arguments.params.version ?: "";
		if (!Len(local.versionArg)) {
			local.rv.success = false;
			local.rv.message = "Missing required argument: version. Usage: wheels migrate forget <version>";
			return local.rv;
		}
		local.forgetResult = arguments.context.migrator.forgetVersion(local.versionArg);
		local.rv.success = local.forgetResult.success;
		local.rv.removed = local.forgetResult.removed;
		local.rv.message = local.forgetResult.message;
		return local.rv;
	}

	public struct function pretendVersion(required struct context, required struct params) {
		// Record a version as applied without running up().
		local.rv = {};
		local.pretendArg = arguments.params.version ?: "";
		if (!Len(local.pretendArg)) {
			local.rv.success = false;
			local.rv.message = "Missing required argument: version. Usage: wheels migrate pretend <version>";
			return local.rv;
		}
		local.pretendResult = arguments.context.migrator.pretendVersion(local.pretendArg);
		local.rv.success = local.pretendResult.success;
		local.rv.recorded = local.pretendResult.recorded;
		local.rv.message = local.pretendResult.message;
		return local.rv;
	}

	// ── Database commands ───────────────────────────────────────────────

	public struct function dbStatus(required struct context, required struct params) {
		// Return migration status straight from the migrator's own status field.
		local.rv = {};
		local.statusReport = arguments.context.host.$cliFormatMigrationStatus(arguments.context.migrations);
		local.rv.success = true;
		local.rv.migrations = local.statusReport.migrations;
		local.rv.summary = local.statusReport.summary;
		return local.rv;
	}

	public struct function dbVersion(required struct context, required struct params) {
		return {
			success = true,
			version = arguments.context.currentVersion,
			message = "Current database version: " & arguments.context.currentVersion
		};
	}

	public struct function dbRollback(required struct context, required struct params) {
		local.rv = {};
		local.steps = structKeyExists(arguments.params, "steps") ? arguments.params.steps : 1;
		local.targetVersion = "";

		// Filter on tracked status, not version <= current (shared dev DB; #2947/#2977).
		local.appliedMigrations = [];
		for (local.migration in arguments.context.migrations) {
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
			local.rv.message = arguments.context.migrator.migrateTo(local.targetVersion);
			local.rv.success = true;
		} else {
			local.rv.success = false;
			local.rv.message = "No migrations to rollback";
		}
		return local.rv;
	}

	public struct function dbSchema(required struct context, required struct params) {
		local.rv = {success = true, schema = {}};

		try {
			local.adapter = application.wheels.dataAdapter;
			local.rv.schema.databaseType = arguments.context.databaseType;
			local.rv.schema.tables = [];

			// Get all tables
			local.tables = [];
			if (arguments.context.databaseType == "H2") {
				local.tablesQuery = new Query();
				local.tablesQuery.setDatasource(application.wheels.dataSourceName);
				local.tablesQuery.setSQL("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'TABLE' AND TABLE_SCHEMA = 'PUBLIC'");
				local.tables = local.tablesQuery.execute().getResult();
			} else {
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

				local.columns = new Query();
				local.columns.setDatasource(application.wheels.dataSourceName);
				if (arguments.context.databaseType == "H2") {
					local.columns.setSQL("SELECT COLUMN_NAME, TYPE_NAME as DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = :tableName AND TABLE_SCHEMA = 'PUBLIC'");
				} else {
					local.columns.setSQL("SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = :tableName");
				}
				local.columns.addParam(name = "tableName", value = local.table.TABLE_NAME, cfsqltype = "cf_sql_varchar");
				local.columnResult = local.columns.execute().getResult();

				for (local.column in local.columnResult) {
					arrayAppend(local.tableInfo.columns, {
						name = local.column.COLUMN_NAME,
						type = local.column.DATA_TYPE,
						nullable = local.column.IS_NULLABLE,
						default = local.column.COLUMN_DEFAULT ?: ""
					});
				}

				arrayAppend(local.rv.schema.tables, local.tableInfo);
			}
		} catch (any e) {
			local.rv.success = false;
			local.rv.message = "Error retrieving schema: " & e.message;
		}
		return local.rv;
	}

	public struct function introspect(required struct context, required struct params) {
		local.rv = {success = false};
		if (!structKeyExists(arguments.params, "model") || !len(arguments.params.model)) {
			local.rv.message = "Missing required parameter: model";
			return local.rv;
		}

		try {
			local.modelName = arguments.params.model;
			local.modelInstance = arguments.context.host.model(local.modelName);
			local.classData = local.modelInstance.$classData();

			local.rv.model = local.modelName;
			local.rv.tableName = local.classData.tableName ?: lCase(local.modelName) & "s";
			local.rv.primaryKey = local.classData.keys ?: "id";

			local.rv.columns = [];
			if (structKeyExists(local.classData, "properties")) {
				for (local.propName in local.classData.properties) {
					local.prop = local.classData.properties[local.propName];
					local.colInfo = {
						name: local.propName,
						type: local.prop.type ?: "string",
						primaryKey: listFindNoCase(local.rv.primaryKey, local.propName) > 0
					};
					if (structKeyExists(local.prop, "maxLength") && val(local.prop.maxLength) > 0) {
						local.colInfo.maxLength = local.prop.maxLength;
					}
					if (right(local.propName, 2) == "Id" && len(local.propName) > 2) {
						local.colInfo.foreignKey = true;
						local.refName = left(local.propName, len(local.propName) - 2);
						local.colInfo.referencedModel = uCase(left(local.refName, 1)) & mid(local.refName, 2, len(local.refName) - 1);
					}
					arrayAppend(local.rv.columns, local.colInfo);
				}
			}

			local.rv.associations = [];
			if (structKeyExists(local.classData, "associations")) {
				for (local.assocName in local.classData.associations) {
					local.assoc = local.classData.associations[local.assocName];
					local.assocModelName = local.assoc.modelName ?: local.assocName;
					local.assocModelName = uCase(left(local.assocModelName, 1)) & mid(local.assocModelName, 2, len(local.assocModelName) - 1);
					arrayAppend(local.rv.associations, {
						type: local.assoc.type ?: "belongsTo",
						name: local.assocName,
						modelName: local.assocModelName
					});
				}
			}

			local.rv.success = true;
			local.rv.message = "Model introspected successfully";
		} catch (any e) {
			local.rv.message = "Error introspecting model: " & e.message;
		}
		return local.rv;
	}

	public struct function dbSeed(required struct context, required struct params) {
		// Seed orchestration; `dbSetup` composes through the same private
		// helper instead of re-entering the dispatcher (issue #2959).
		return $runDbSeed(params = arguments.params, context = arguments.context);
	}

	public struct function routes(required struct context, required struct params) {
		// Routes live at application.wheels.routes.
		local.rv = {success = true, routes = []};
		if (structKeyExists(application, "wheels") && structKeyExists(application.wheels, "routes")) {
			for (local.route in application.wheels.routes) {
				local.routeInfo = {
					name = structKeyExists(local.route, "name") ? local.route.name : "",
					pattern = structKeyExists(local.route, "pattern") ? local.route.pattern : "",
					controller = structKeyExists(local.route, "controller") ? local.route.controller : "",
					action = structKeyExists(local.route, "action") ? local.route.action : "",
					methods = structKeyExists(local.route, "methods") ? local.route.methods : "GET"
				};
				arrayAppend(local.rv.routes, local.routeInfo);
			}
		}
		return local.rv;
	}

	public struct function dbCreate(required struct context, required struct params) {
		local.rv = {success = false};

		// For H2, we can provide helpful info and ensure schema table exists.
		if (arguments.context.databaseType == "H2") {
			try {
				local.checkQuery = new Query();
				local.checkQuery.setDatasource(application.wheels.dataSourceName);
				local.checkQuery.setSQL("SELECT COUNT(*) as cnt FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SCHEMAINFO'");
				local.checkResult = local.checkQuery.execute().getResult();

				if (local.checkResult.cnt == 0) {
					local.createQuery = new Query();
					local.createQuery.setDatasource(application.wheels.dataSourceName);
					local.createQuery.setSQL("CREATE TABLE IF NOT EXISTS schemainfo (version VARCHAR(25) DEFAULT '0')");
					local.createQuery.execute();

					local.insertQuery = new Query();
					local.insertQuery.setDatasource(application.wheels.dataSourceName);
					local.insertQuery.setSQL("INSERT INTO schemainfo (version) VALUES ('0')");
					local.insertQuery.execute();

					local.rv.message = "H2 database initialized successfully with schema tracking table.";
				} else {
					local.rv.message = "H2 database already exists and is properly configured.";
				}
				local.rv.success = true;
			} catch (any e) {
				local.rv.message = "H2 database exists but error checking schema: " & e.message;
				local.rv.success = true; // Still mark as success since H2 auto-creates
			}
		} else {
			local.rv.message = "Database creation must be done through your database management system or hosting control panel.";

			switch (arguments.context.databaseType) {
				case "MySQL":
					local.rv.message &= chr(10) & chr(10) & "MySQL: CREATE DATABASE dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;";
					break;
				case "PostgreSQL":
					local.rv.message &= chr(10) & chr(10) & "PostgreSQL: CREATE DATABASE dbname WITH ENCODING='UTF8';";
					break;
				case "SQLServer":
					local.rv.message &= chr(10) & chr(10) & "SQL Server: CREATE DATABASE dbname;";
					break;
			}
		}
		return local.rv;
	}

	public struct function dbDrop(required struct context, required struct params) {
		return {
			success = false,
			message = "Database dropping must be done through your database management system or hosting control panel for safety reasons."
		};
	}

	public struct function dbReset(required struct context, required struct params) {
		local.rv = {};
		try {
			// Get all tables
			local.tables = [];
			if (arguments.context.databaseType == "H2") {
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

			local.rv.success = true;
			local.rv.message = "Database reset successfully. All tables dropped and migration version reset to 0.";
		} catch (any e) {
			local.rv.success = false;
			local.rv.message = "Error resetting database: " & e.message;
		}
		return local.rv;
	}

	public struct function dbSetup(required struct context, required struct params) {
		// Setup database (migrate + optional seed). Composes seeding through a
		// direct helper call — never by re-entering the dispatcher (issue #2959).
		local.rv = {success = true, message = "Database setup: "};

		try {
			local.migrateResult = arguments.context.migrator.migrateToLatest();
			local.rv.message &= "Migrations completed. ";

			if (structKeyExists(arguments.params, "seed") && arguments.params.seed) {
				local.seedParams = Duplicate(arguments.params);
				local.seedParams.count = StructKeyExists(arguments.params, "seedCount")
					? val(arguments.params.seedCount) : 10;
				local.seedResult = $runDbSeed(params = local.seedParams, context = arguments.context);
				local.setupMessage = local.rv.message;
				StructAppend(local.rv, local.seedResult, true);
				local.rv.message = local.setupMessage & local.seedResult.message;
				if (!local.seedResult.success) {
					local.rv.success = false;
				}
			}
		} catch (any e) {
			local.rv.success = false;
			local.rv.message &= "Migration failed: " & e.message & ". ";
		}
		return local.rv;
	}

	public struct function dbDump(required struct context, required struct params) {
		local.rv = {success = false, dump = ""};

		// For H2, generate a dump directly.
		if (arguments.context.databaseType == "H2") {
			try {
				local.dumpQuery = new Query();
				local.dumpQuery.setDatasource(application.wheels.dataSourceName);
				local.dumpQuery.setSQL("SCRIPT SIMPLE");
				local.dumpResult = local.dumpQuery.execute().getResult();

				local.sqlDump = "";
				for (local.row in local.dumpResult) {
					local.sqlDump &= local.row.SCRIPT & ";" & chr(10);
				}

				local.rv.success = true;
				local.rv.dump = local.sqlDump;
				local.rv.message = "Database dump generated successfully. Use --output parameter to save to file.";

				// If output file specified, save it. The path is canonicalized
				// and confined to the application root (SEC-5).
				if (structKeyExists(arguments.params, "output")) {
					local.outputFile = arguments.context.host.$cliResolveDumpPath(arguments.params.output);
					if (Len(local.outputFile)) {
						fileWrite(local.outputFile, local.sqlDump);
						local.rv.message = "Database dump saved to: " & arguments.params.output;
					} else {
						local.rv.success = false;
						local.rv.message = "Invalid output path: the dump file must resolve inside the application root.";
					}
				}
			} catch (any e) {
				local.rv.message = "Error generating dump: " & e.message;
			}
		} else {
			local.rv.message = "Database dump functionality requires command-line tools specific to your database system.";
			switch (arguments.context.databaseType) {
				case "MySQL":
					local.rv.message &= " Use: mysqldump -u [username] -p [database] > backup.sql";
					break;
				case "PostgreSQL":
					local.rv.message &= " Use: pg_dump -U [username] [database] > backup.sql";
					break;
				case "SQLServer":
					local.rv.message &= " Use SQL Server Management Studio or: sqlcmd -S [server] -d [database] -Q 'BACKUP DATABASE...'";
					break;
			}
		}
		return local.rv;
	}

	public struct function dbRestore(required struct context, required struct params) {
		local.rv = {
			success = false,
			message = "Database restore functionality requires command-line tools specific to your database system."
		};

		switch (arguments.context.databaseType) {
			case "MySQL":
				local.rv.message &= " Use: mysql -u [username] -p [database] < backup.sql";
				break;
			case "PostgreSQL":
				local.rv.message &= " Use: psql -U [username] [database] < backup.sql";
				break;
			case "SQLServer":
				local.rv.message &= " Use SQL Server Management Studio or: sqlcmd -S [server] -d [database] -i backup.sql";
				break;
			case "H2":
				local.rv.message &= " Use: RUNSCRIPT FROM 'backup.sql' in H2 console";
				break;
		}
		return local.rv;
	}

	public struct function dbShell(required struct context, required struct params) {
		local.rv = {success = false};

		// For H2, provide specific information about accessing the console.
		if (arguments.context.databaseType == "H2") {
			local.rv.message = "H2 Database Console Access:" & chr(10);
			local.rv.message &= chr(10) & "Option 1: Web Console" & chr(10);
			local.rv.message &= "The H2 web console may be available at the /h2-console path of your application." & chr(10);
			local.rv.message &= "URL: http://localhost:[your-port]/h2-console" & chr(10);
			local.rv.message &= "JDBC URL: " & application.wheels.dataSourceName & chr(10);

			try {
				local.dbinfo = new Query();
				local.dbinfo.setDatasource(application.wheels.dataSourceName);
				local.dbinfo.setSQL("SELECT DATABASE() as dbname, USER() as dbuser");
				local.dbResult = local.dbinfo.execute().getResult();
				if (local.dbResult.recordCount) {
					local.rv.message &= "Database: " & local.dbResult.dbname & chr(10);
					local.rv.message &= "User: " & local.dbResult.dbuser & chr(10);
				}
			} catch (any e) {
				// Ignore errors getting extra info
			}

			local.rv.message &= chr(10) & "Option 2: Command Line" & chr(10);
			local.rv.message &= "java -cp [path-to-h2.jar] org.h2.tools.Shell" & chr(10);
		} else {
			local.rv.message = "Database shell access requires command-line tools. ";
			switch (arguments.context.databaseType) {
				case "MySQL":
					local.rv.message &= "Use: mysql -u [username] -p [database]";
					break;
				case "PostgreSQL":
					local.rv.message &= "Use: psql -U [username] [database]";
					break;
				case "SQLServer":
					local.rv.message &= "Use: sqlcmd -S [server] -d [database] -U [username]";
					break;
			}
		}
		return local.rv;
	}

	// ── Job worker commands ─────────────────────────────────────────────

	public struct function jobsProcessNext(required struct context, required struct params) {
		local.rv = {};
		try {
			local.worker = new wheels.JobWorker();
			local.jobQueues = structKeyExists(arguments.params, "queues") ? arguments.params.queues : "";
			local.jobTimeout = structKeyExists(arguments.params, "timeout") ? val(arguments.params.timeout) : 300;
			local.jobResult = local.worker.processNext(queues = local.jobQueues, timeout = local.jobTimeout);
			local.rv.success = true;
			local.rv.jobResult = local.jobResult;
			local.rv.message = local.jobResult.skipped ? "No jobs available" : "Processed job #local.jobResult.jobId#";
		} catch (any e) {
			local.rv.success = false;
			local.rv.message = "Error processing job: " & e.message;
		}
		return local.rv;
	}

	public struct function jobsStatus(required struct context, required struct params) {
		local.rv = {};
		try {
			local.worker = new wheels.JobWorker();
			local.jobQueue = structKeyExists(arguments.params, "queue") ? arguments.params.queue : "";
			local.rv.success = true;
			local.rv.stats = local.worker.getStats(queue = local.jobQueue);
			local.rv.message = "Queue statistics retrieved";
		} catch (any e) {
			local.rv.success = false;
			local.rv.message = "Error getting status: " & e.message;
		}
		return local.rv;
	}

	public struct function jobsRetry(required struct context, required struct params) {
		local.rv = {};
		try {
			local.worker = new wheels.JobWorker();
			local.jobQueue = structKeyExists(arguments.params, "queue") ? arguments.params.queue : "";
			local.jobLimit = structKeyExists(arguments.params, "limit") ? val(arguments.params.limit) : 0;
			local.retryCount = local.worker.retryFailed(queue = local.jobQueue, limit = local.jobLimit);
			local.rv.success = true;
			local.rv.retried = local.retryCount;
			local.rv.message = "Retried #local.retryCount# failed job(s)";
		} catch (any e) {
			local.rv.success = false;
			local.rv.message = "Error retrying jobs: " & e.message;
		}
		return local.rv;
	}

	public struct function jobsPurge(required struct context, required struct params) {
		local.rv = {};
		try {
			local.worker = new wheels.JobWorker();
			local.jobQueue = structKeyExists(arguments.params, "queue") ? arguments.params.queue : "";
			local.purgeStatus = structKeyExists(arguments.params, "status") ? arguments.params.status : "completed";
			local.purgeDays = structKeyExists(arguments.params, "days") ? val(arguments.params.days) : 7;
			local.purgeCount = local.worker.purge(status = local.purgeStatus, days = local.purgeDays, queue = local.jobQueue);
			local.rv.success = true;
			local.rv.purged = local.purgeCount;
			local.rv.message = "Purged #local.purgeCount# #local.purgeStatus# job(s)";
		} catch (any e) {
			local.rv.success = false;
			local.rv.message = "Error purging jobs: " & e.message;
		}
		return local.rv;
	}

	public struct function jobsMonitor(required struct context, required struct params) {
		local.rv = {};
		try {
			local.worker = new wheels.JobWorker();
			local.jobQueue = structKeyExists(arguments.params, "queue") ? arguments.params.queue : "";
			local.minutes = structKeyExists(arguments.params, "minutes") ? val(arguments.params.minutes) : 60;
			local.rv.success = true;
			local.rv.monitor = local.worker.getMonitorData(queue = local.jobQueue, minutes = local.minutes);
			local.rv.stats = local.worker.getStats(queue = local.jobQueue);
			local.timeouts = local.worker.checkTimeouts();
			if (local.timeouts > 0) {
				local.rv.timeoutsRecovered = local.timeouts;
			}
			local.rv.message = "Monitor data retrieved";
		} catch (any e) {
			local.rv.success = false;
			local.rv.message = "Error getting monitor data: " & e.message;
		}
		return local.rv;
	}

	// ── Internal ────────────────────────────────────────────────────────

	/**
	 * Seed orchestration, shared by `dbSeed` and `dbSetup`. Returns a struct
	 * with {success, mode, message, ...mode-specific fields} merged into the
	 * response envelope by the caller.
	 */
	private struct function $runDbSeed(required struct params, required struct context) {
		var result = {success = true, mode = "auto", message = ""};
		var sp = arguments.params;
		var requestedMode = structKeyExists(sp, "mode") ? sp.mode : "auto";
		var environment = structKeyExists(sp, "environment") ? sp.environment : arguments.context.host.get("environment");
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
				// Generate mode delegates to Seeder.generateSeeds() (#3082).
				var count = structKeyExists(sp, "count") ? val(sp.count) : 10;
				var modelsArg = structKeyExists(sp, "models") ? sp.models : "";
				var generateSeeder = structKeyExists(application.wheels, "seeder")
					? application.wheels.seeder
					: CreateObject("component", "wheels.Seeder").init();
				var generateResult = generateSeeder.generateSeeds(models = modelsArg, count = count);
				StructAppend(result, generateResult, true);
			}
		} catch (any e) {
			result.success = false;
			result.message = "Error during database seeding: " & e.message;
		}

		return result;
	}

}
