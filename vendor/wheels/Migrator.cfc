component output="false" extends="wheels.Global"{

	/**
	 * Configure and return migrator object. Now uses /app mapping
	 */
	public struct function init(
		string migratePath = "/app/migrator/migrations/",
		string sqlPath = "/app/migrator/sql/",
		string templatePath = "/app/snippets/dbmigrate/"
	) {
		this.paths.migrate = ExpandPath(arguments.migratePath);
		this.paths.sql = ExpandPath(arguments.sqlPath);
		this.paths.templates = ExpandPath(arguments.templatePath);
		this.paths.migrateComponents = ArrayToList(ListToArray(arguments.migratePath, "/"), ".");
		return this;
	}

	/**
	 * Migrates database to a specified version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 *
	 * @version The Database schema version to migrate to
	 * @missingMigFlag Flag for any available missing migrations
	 */
	public string function migrateTo(string version = "", boolean missingMigFlag = false) {
		local.rv = "";
		local.currentVersion = getCurrentMigrationVersion();
		local.appKey = $appKey();

		// Load migrations early to detect unapplied "gap" migrations before short-circuiting
		local.migrations = getAvailableMigrations();
		local.hasPendingMigrations = false;
		for (local.m in local.migrations) {
			if (local.m.status != "migrated" && local.m.version <= arguments.version) {
				local.hasPendingMigrations = true;
				break;
			}
		}

		// Issue #2780: detect orphan versions (DB rows whose timestamp has no
		// matching local file). Common in shared dev DBs when a peer applied
		// a migration whose file isn't yet in this branch. Without this
		// check, the directional logic below silently took the "down" branch
		// and emitted a misleading "Migrating from X down to Y" output.
		local.orphans = $getOrphanVersions();
		local.orphansAboveTarget = [];
		for (local.v in local.orphans) {
			if (local.v > arguments.version) {
				ArrayAppend(local.orphansAboveTarget, local.v);
			}
		}
		local.isOrphanAtTop = (
			local.currentVersion > arguments.version
			&& ArrayLen(local.orphansAboveTarget)
			&& !arguments.missingMigFlag
		);
		if (local.isOrphanAtTop) {
			// Check whether EVERY DB version above target is an orphan. If
			// some have local files, the down branch is legitimate (the user
			// has files to run down() on) — we still emit a warning naming
			// the orphans but otherwise proceed as before.
			local.dbVersionsAboveTarget = [];
			for (local.v in ListToArray($getVersionsPreviouslyMigrated())) {
				if (Len(local.v) && local.v != "0" && local.v > arguments.version) {
					ArrayAppend(local.dbVersionsAboveTarget, local.v);
				}
			}
			local.allOrphans = ArrayLen(local.dbVersionsAboveTarget) == ArrayLen(local.orphansAboveTarget);
			if (local.allOrphans) {
				local.rv = "Note: database tracks version(s) "
					& ArrayToList(local.orphansAboveTarget, ", ")
					& " with no matching file in app/migrator/migrations/. "
					& "This usually means a peer applied a migration whose "
					& "file isn't yet in your branch.#Chr(13) & Chr(10)#";
				if (!local.hasPendingMigrations) {
					local.rv &= "Nothing to do. Your target version ("
						& arguments.version
						& ") is below the database's current version ("
						& local.currentVersion & ").#Chr(13) & Chr(10)#";
					return local.rv;
				}
				// Suppress the down branch: rewrite currentVersion so the
				// outer conditional falls through to the up branch, which
				// applies any actually-pending local migrations.
				local.currentVersion = arguments.version;
			} else {
				// Mixed case: some legitimate down candidates, some orphans.
				// Warn but let the existing down branch handle the rest;
				// orphan rows are skipped naturally because the loop only
				// iterates local files.
				local.rv = "Note: database tracks version(s) "
					& ArrayToList(local.orphansAboveTarget, ", ")
					& " with no matching file. These will be skipped during rollback.#Chr(13) & Chr(10)#";
			}
		}

		if (local.currentVersion == arguments.version && !local.hasPendingMigrations) {
			local.rv &= "Database is currently at version #arguments.version#. No migration required.#Chr(13) & Chr(10)#";
		} else {
			if (!DirectoryExists(this.paths.sql) && application[local.appKey].writeMigratorSQLFiles) {
				DirectoryCreate(this.paths.sql);
			}
			if (local.currentVersion > arguments.version && arguments.missingMigFlag == false) {
				local.rv &= "Migrating from #local.currentVersion# down to #arguments.version#.#Chr(13) & Chr(10)#";
				for (local.i = ArrayLen(local.migrations); local.i >= 1; local.i--) {
					local.migration = local.migrations[local.i];
					if (local.migration.version <= arguments.version) {
						break;
					}
					if (local.migration.status == "migrated" && application[local.appKey].allowMigrationDown) {
						transaction action="begin" {
							try {
								// Test query to establish datasource for BoxLang compatibility
								if (structKeyExists(server, "boxlang")) {
									$query(datasource = application[local.appKey].dataSourceName, sql = "SELECT 1 as test");
								}
								local.rv = local.rv & "#Chr(13) & Chr(10)#------- " & local.migration.cfcfile & " #RepeatString("-", Max(5, 50 - Len(local.migration.cfcfile)))##Chr(13) & Chr(10)#";
								request.$wheelsMigrationOutput = "";
								request.$wheelsMigrationSQLFile = "#this.paths.sql#/#local.migration.cfcfile#_down.sql";
								if (application[local.appKey].writeMigratorSQLFiles) {
									$writeMigrationFile(request.$wheelsMigrationSQLFile, "");
								}
								local.migration.cfc.down();
								local.rv = local.rv & request.$wheelsMigrationOutput;
								$removeVersionAsMigrated(local.migration.version);
							} catch (any e) {
								local.rv = local.rv & "Error migrating to #local.migration.version#.#Chr(13) & Chr(10)##e.message##Chr(13) & Chr(10)##e.detail##Chr(13) & Chr(10)#";
								transaction action="rollback";
								break;
							}
							transaction action="commit";
						}
					}
				}
			} else {
				if(arguments.missingMigFlag){
					local.rv &= "Migrating remaining migrations till #arguments.version#.#Chr(13) & Chr(10)#";
					$removeVersionAsMigrated(local.currentVersion);
				} else if (local.currentVersion gte arguments.version && local.hasPendingMigrations) {
					// Out-of-order pending migrations: a migration with a
					// timestamp earlier than currentVersion is still pending
					// (e.g. tutorial chapter 5 hardcodes 20260419130000 while
					// the user's chapter 2 posts migration sits at the
					// generator's current-day timestamp). The "from N up to N"
					// framing reads as a no-op even though new migrations are
					// about to run, so emit a clearer message. Onboarding F16.
					local.rv &= "Applying pending migration(s) up to #arguments.version#.#Chr(13) & Chr(10)#";
				} else {
					local.rv &= "Migrating from #local.currentVersion# up to #arguments.version#.#Chr(13) & Chr(10)#";
				}
				for (local.migration in local.migrations) {
					if (local.migration.version <= arguments.version && local.migration.status != "migrated") {
						transaction {
							try {
								// Test query to establish datasource for BoxLang compatibility
								if (structKeyExists(server, "boxlang")) {
									$query(datasource = application[local.appKey].dataSourceName, sql = "SELECT 1 as test");
								}
								local.rv = local.rv & "#Chr(13) & Chr(10)#-------- " & local.migration.cfcfile & " #RepeatString("-", Max(5, 50 - Len(local.migration.cfcfile)))##Chr(13) & Chr(10)#";
								request.$wheelsMigrationOutput = "";
								request.$wheelsMigrationSQLFile = "#this.paths.sql#/#local.migration.cfcfile#_up.sql";
								if (application[local.appKey].writeMigratorSQLFiles) {
									$writeMigrationFile(request.$wheelsMigrationSQLFile, "");
								}
								local.migration.cfc.up();
								local.rv = local.rv & request.$wheelsMigrationOutput;
								$setVersionAsMigrated(local.migration.version, local.migration.name);
							} catch (any e) {
								local.rv = local.rv & "Error migrating to #local.migration.version#.#Chr(13) & Chr(10)##e.message##Chr(13) & Chr(10)##e.detail##Chr(13) & Chr(10)#";
								transaction action="rollback";
								break;
							}
							transaction action="commit";
						}
					} else if (local.migration.version > arguments.version) {
						break;
					}
				};
				if(arguments.missingMigFlag){
					$setVersionAsMigrated(local.currentVersion);
				}
			}
		}
		return local.rv;
	}

	/**
	 * Runs a single specific migration's up() regardless of sequence order.
	 * Used for out-of-sequence migrations that were created by other developers
	 * and need to be applied individually without affecting the current version pointer.
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 *
	 * @version The version number of the specific migration to run
	 */
	public string function migrateIndividual(required string version) {
		local.rv = "";
		local.appKey = $appKey();
		local.migrations = getAvailableMigrations();
		local.migrationArray = ArrayFilter(local.migrations, function(i) {
			return i.version == version;
		});
		if (!ArrayLen(local.migrationArray)) {
			return "Error: Migration version #arguments.version# was not found.#Chr(13) & Chr(10)#";
		}
		local.migration = local.migrationArray[1];
		if (local.migration.status == "migrated") {
			return "Migration #arguments.version# has already been applied.#Chr(13) & Chr(10)#";
		}
		if (!DirectoryExists(this.paths.sql) && application[local.appKey].writeMigratorSQLFiles) {
			DirectoryCreate(this.paths.sql);
		}
		local.rv = "Running individual migration #arguments.version#.#Chr(13) & Chr(10)#";
		transaction {
			try {
				if (structKeyExists(server, "boxlang")) {
					$query(datasource = application[local.appKey].dataSourceName, sql = "SELECT 1 as test");
				}
				local.rv = local.rv & "#Chr(13) & Chr(10)#-------- " & local.migration.cfcfile & " #RepeatString("-", Max(5, 50 - Len(local.migration.cfcfile)))##Chr(13) & Chr(10)#";
				request.$wheelsMigrationOutput = "";
				request.$wheelsMigrationSQLFile = "#this.paths.sql#/#local.migration.cfcfile#_up.sql";
				if (application[local.appKey].writeMigratorSQLFiles) {
					$writeMigrationFile(request.$wheelsMigrationSQLFile, "");
				}
				local.migration.cfc.up();
				local.rv = local.rv & request.$wheelsMigrationOutput;
				$setVersionAsMigrated(local.migration.version, local.migration.name);
			} catch (any e) {
				local.rv = local.rv & "Error migrating #local.migration.version#.#Chr(13) & Chr(10)##e.message##Chr(13) & Chr(10)##e.detail##Chr(13) & Chr(10)#";
				transaction action="rollback";
			}
			transaction action="commit";
		}
		return local.rv;
	}

	/**
	 * Shortcut function to migrate to the latest version
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public string function migrateToLatest() {
		local.migrations = getAvailableMigrations();
		if (ArrayLen(local.migrations)) {
			local.latest = local.migrations[ArrayLen(local.migrations)].version;
		} else {
			local.latest = 0;
		}
		return migrateTo(local.latest);
	}

	/**
	 * Returns current database version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public string function getCurrentMigrationVersion() {
		return ListLast($getVersionsPreviouslyMigrated());
	}

	/**
	 * Creates a migration file. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public string function createMigration(
		required string migrationName,
		string templateName = "",
		string migrationPrefix = "timestamp"
	) {
		if (Len(Trim(arguments.migrationName))) {
			return $copyTemplateMigrationAndRename(argumentCollection = arguments);
		} else {
			return "You must supply a migration name (e.g. 'creates member table')";
		}
	}

	/**
	 * Searches db/migrate folder for migrations. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 *
	 * @path Path to Migration Files: defaults to /app/migrator/migrations/
	 */
	public array function getAvailableMigrations(string path = this.paths.migrate) {
		local.rv = [];
		local.previousMigrationList = $getVersionsPreviouslyMigrated();
		local.migrationRE = "^([\d]{3,14})_([^\.]*)\.cfc$";
		if (!DirectoryExists(this.paths.migrate)) {
			DirectoryCreate(this.paths.migrate);
		}
		local.files = DirectoryList(this.paths.migrate, false, "query", "*.cfc", "name");
		for (local.row in local.files) {
			if (ReFind(local.migrationRE, local.row.name)) {
				local.migration = {};
				local.migration.version = ReReplace(local.row.name, local.migrationRE, "\1");
				local.migration.name = ReReplace(local.row.name, local.migrationRE, "\2");
				local.migration.cfcfile = ReReplace(local.row.name, local.migrationRE, "\1_\2");
				local.migration.loadError = "";
				local.migration.details = "description unavailable";
				local.migration.status = "";
				try {
					local.migration.cfc = $createObjectFromRoot(
						path = this.paths.migrateComponents,
						fileName = local.migration.cfcfile,
						method = "init"
					);
					local.metaData = GetMetadata(local.migration.cfc);
					if (StructKeyExists(local.metaData, "hint")) {
						local.migration.details = local.metaData.hint;
					}
					if (ListFind(local.previousMigrationList, local.migration.version)) {
						local.migration.status = "migrated";
					}
				} catch (any e) {
					local.migration.loadError = e.message;
				}
				ArrayAppend(local.rv, local.migration);
			}
		};
		ArraySort(local.rv, function(a, b) {
			return Compare(a.version, b.version);
		});
		return local.rv;
	}

	/**
	 * Reruns the specified migration version. Whilst you can use this in your application, the recommended usage is via either the CLI or the provided GUI interface
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 *
	 * @version The Database schema version to rerun
	 */
	public string function redoMigration(string version = "") {
		local.currentVersion = getCurrentMigrationVersion();
		local.appKey = $appKey();
		if (Len(arguments.version)) {
			currentVersion = arguments.version;
		}
		local.migrationArray = ArrayFilter(getAvailableMigrations(), function(i) {
			return i.version == currentVersion;
		});
		if (!ArrayLen(local.migrationArray)) {
			return "Error re-running #arguments.version#.#Chr(13) & Chr(10)#This version was not found#Chr(13) & Chr(10)#";
		}

		local.migration = local.migrationArray[1];
		local.rv = "";
		try {
			local.rv = local.rv & "#Chr(13) & Chr(10)#------- " & local.migration.cfcfile & " #RepeatString("-", Max(5, 50 - Len(local.migration.cfcfile)))##Chr(13) & Chr(10)#";
			request.$wheelsMigrationOutput = "";
			request.$wheelsMigrationSQLFile = "#this.paths.sql#/#local.migration.cfcfile#_redo.sql";
			if (application[local.appKey].writeMigratorSQLFiles) {
				$writeMigrationFile(request.$wheelsMigrationSQLFile, "");
			}
			if (application[local.appKey].allowMigrationDown) {
				local.migration.cfc.down();
			}
			local.migration.cfc.up();
			local.rv = local.rv & request.$wheelsMigrationOutput;
		} catch (any e) {
			local.rv = local.rv & "Error re-running #local.migration.version#.#Chr(13) & Chr(10)##e.message##Chr(13) & Chr(10)##e.detail##Chr(13) & Chr(10)#";
		}
		return local.rv;
	}

	/**
	 * Inserts a record to flag a version as migrated. When the enriched
	 * tracking schema is in use (name + applied_at columns present, signaled
	 * by application[appKey].$trackingColumnsEnsured), populates name with
	 * the supplied migrationName and applied_at with NOW() (for SQLite,
	 * which can't default a TIMESTAMP column on ADD; other engines use
	 * their column DEFAULT and we omit applied_at from the INSERT).
	 *
	 * @migrationName Human-readable name of the migration (e.g. "create_users").
	 *   Optional — when empty or when the enriched columns aren't present,
	 *   only version + core_level are written, matching legacy behavior.
	 */
	private void function $setVersionAsMigrated(required string version, string migrationName = "") {
		local.appKey = $appKey();
		if (StructKeyExists(request, "$wheelsDebugSQL")) {
			return;
		}
		local.cleanVersion = $sanitiseVersion(arguments.version);
		local.cols = "version, core_level";
		local.vals = "'#local.cleanVersion#', #application[local.appKey].migrationLevel#";
		// Only write the enriched columns when they exist on this app's
		// schema. The $trackingColumnsEnsured flag is set by
		// $maybeEnsureTrackingColumns() after a successful ALTER (or after
		// it confirms the columns are already present).
		if (
			Len(arguments.migrationName)
			&& StructKeyExists(application[local.appKey], "$trackingColumnsEnsured")
		) {
			// Single-quote escape (CFML standard SQL string literal) to defend
			// against accidental quote chars in migration names. The names are
			// derived from filenames, which Wheels' generator only allows
			// alphanumeric + underscore in, but defending here costs nothing.
			local.escapedName = Replace(arguments.migrationName, "'", "''", "all");
			local.cols &= ", name";
			local.vals &= ", '#local.escapedName#'";
			// SQLite can't DEFAULT a TIMESTAMP on ADD COLUMN, so we set the
			// value explicitly. Other engines rely on the column's
			// CURRENT_TIMESTAMP default and we omit applied_at from the
			// INSERT to avoid engine-specific date-literal syntax issues.
			local.info = $dbinfo(
				type = "version",
				datasource = application[local.appKey].dataSourceName,
				username = application.wheels.dataSourceUserName,
				password = application.wheels.dataSourcePassword
			);
			if (FindNoCase("SQLite", local.info.database_productname)) {
				local.cols &= ", applied_at";
				local.vals &= ", '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#'";
			}
		}
		$query(
			datasource = application[local.appKey].dataSourceName,
			sql = "INSERT INTO #application[local.appKey].migratorTableName# (#local.cols#) VALUES (#local.vals#)"
		);
	}

	/**
	 * Deletes a record to flag a version as not migrated.
	 */
	private void function $removeVersionAsMigrated(required string version) {
		local.appKey = $appKey();
		if (!StructKeyExists(request, "$wheelsDebugSQL"))
			$query(
				datasource = application[local.appKey].dataSourceName,
				sql = "DELETE FROM #application[local.appKey].migratorTableName# WHERE version = '#$sanitiseVersion(arguments.version)#'"
			);
	}

	/**
	 * Returns the next migration.
	 */
	public string function $getNextMigrationNumber(string migrationPrefix = "") {
		local.migrationNumber = DateFormat(Now(), 'yyyymmdd') & TimeFormat(Now(), 'HHMMSS');
		if (arguments.migrationPrefix != "timestamp") {
			local.migrations = getAvailableMigrations();
			if (!ArrayLen(local.migrations)) {
				if (arguments.migrationPrefix == "numeric") {
					local.migrationNumber = "001";
				}
			} else {
				// Determine current numbering system.
				local.lastMigration = local.migrations[ArrayLen(local.migrations)];
				if (Len(local.lastMigration.version) == 3) {
					// Use numeric numbering.
					local.migrationNumber = NumberFormat(Val(local.lastMigration.version) + 1, "009");
				}
			}
		}
		return local.migrationNumber;
	}

	/**
	 * Creates a migration file based on a template.
	 */
	private string function $copyTemplateMigrationAndRename(
		required string migrationName,
		required string templateName,
		string migrationPrefix = ""
	) {
		local.templateFile = this.paths.templates & "/" & arguments.templateName & ".txt";
		local.extendsPath = "wheels.migrator.Migration";
		if (!FileExists(local.templateFile)) {
			return "Template #arguments.templateName# could not be found. <br/> To resolve this, generate the necessary template files by running `wheels g snippets` from the root of your application";
		}
		if (!DirectoryExists(this.paths.migrate)) {
			DirectoryCreate(this.paths.migrate);
		}
		try {
			local.appKey = $appKey();
			local.templateContent = FileRead(local.templateFile);
			if (Len(Trim(application[local.appKey].rootcomponentpath))) {
				local.extendsPath = application[local.appKey].rootcomponentpath & ".wheels.migrator.Migration";
			}
			local.templateContent = Replace(local.templateContent, "|DBMigrateExtends|", local.extendsPath);
			local.templateContent = Replace(
				local.templateContent,
				"|DBMigrateDescription|",
				Replace(arguments.migrationName, """", "&quot;", "all")
			);
			local.migrationFile = ReReplace(arguments.migrationName, "[^A-z0-9]+", " ", "all");
			local.migrationFile = ReReplace(Trim(local.migrationFile), "[\s]+", "_", "all");
			local.migrationFile = $getNextMigrationNumber(arguments.migrationPrefix) & "_#local.migrationFile#.cfc";
			$writeMigrationFile("#this.paths.migrate#/#local.migrationFile#", local.templateContent);
		} catch (any e) {
			return "There was an error when creating the migration: #e.message#";
		}
		return "The migration #local.migrationFile# file was created";
	}

	/**
	 * Returns previously migrated versions as a list.
	 */
	private string function $getVersionsPreviouslyMigrated() {
		local.appKey = $appKey();

		// F15 Phase 1: detect whether this app's system tables already exist
		// under the legacy `c_o_r_e_*` names; if so, flip the configured names
		// back so subsequent SQL targets the existing tables. New installs
		// keep the `wheels_*` defaults from onapplicationstart.cfc.
		$detectSystemTables(appKey = local.appKey);

		/* Choose appropriate SQL syntax for LIMIT based on database engine */
		local.info = $dbinfo(
			type = "version",
			datasource = application.wheels.dataSourceName,
			username = application.wheels.dataSourceUserName,
			password = application.wheels.dataSourcePassword
		);
		local.levelsTable = application[local.appKey].levelsTableName;
		if(FindNoCase("SQLServer", local.info.database_productname) || FindNoCase("SQL Server", local.info.database_productname)){
			local.sql = "SELECT TOP 1 * FROM #local.levelsTable#";
		} else if(FindNoCase("Oracle", local.info.database_productname)){
			local.sql = "SELECT * FROM #local.levelsTable# FETCH FIRST 1 ROWS ONLY";
		} else{
			local.sql = "SELECT * FROM #local.levelsTable# LIMIT 1";
		}

		try {
			local.levelsCheck = $query(
				datasource = application[local.appKey].dataSourceName,
				sql = local.sql
			);
		} catch (any e) {
			if (application[local.appKey].createMigratorTable) {
				$query(
					datasource = application[local.appKey].dataSourceName,
					sql = "CREATE TABLE #local.levelsTable# (id INT PRIMARY KEY, name VARCHAR(50) NOT NULL, description VARCHAR(255))"
				);
				$query(
					datasource = application[local.appKey].dataSourceName,
					sql = "INSERT INTO #local.levelsTable# (id, name, description) VALUES (1, 'App', 'Application level migrations')"
				);
				$query(
					datasource = application[local.appKey].dataSourceName,
					sql = "INSERT INTO #local.levelsTable# (id, name, description) VALUES (2, 'Test', 'Test level migrations')"
				);
			}
		}
		try {
			local.migratedVersions = $query(
				datasource = application[local.appKey].dataSourceName,
				sql = "SELECT version FROM #application[local.appKey].migratorTableName# WHERE core_level = #application[local.appKey].migrationLevel# ORDER BY version ASC"
			);
			// Table exists — ensure the enriched name + applied_at columns are
			// present. Cached on app scope so this fires once per app process,
			// not on every migrator call. See issue #2780 / Plan 3.
			$maybeEnsureTrackingColumns(local.appKey);
			if (!local.migratedVersions.recordcount) {
				return 0;
			} else {
				return ValueList(local.migratedVersions.version);
			}
		} catch (any e) {
			if (application[local.appKey].createMigratorTable) {
				local.dbType = local.info.database_productname;
				local.tableName = application[local.appKey].migratorTableName;
				// FK constraint name follows the levels-table prefix so a
				// fresh install gets `fk_wheels_level` and a legacy install
				// keeps `fk_core_level`. Constraint names are scoped to
				// their tables, so this only matters for new bootstraps.
				local.fkName = (local.levelsTable == "c_o_r_e_levels") ? "fk_core_level" : "fk_wheels_level";

				// SQLite: skip rename / ALTER, create table with constraint in one query
				if (FindNoCase("SQLite", local.dbType)) {
					local.createSQL = "
						CREATE TABLE #local.tableName# (
							version VARCHAR(25),
							core_level INT NOT NULL DEFAULT 1,
							CONSTRAINT #local.fkName# FOREIGN KEY (core_level) REFERENCES #local.levelsTable#(id)
						)
					";
					$query(
						datasource = application[local.appKey].dataSourceName,
						sql = local.createSQL
					);
				} else {
					if (FindNoCase("SQLServer", local.dbType) || FindNoCase("SQL Server", local.dbType)) {
						local.renameSQL = "EXEC sp_rename 'migratorversions', '#local.tableName#'";
						local.createSQL = "CREATE TABLE #local.tableName# (version VARCHAR(25), core_level INT NOT NULL DEFAULT 1)";
						local.addColumnSQL = "ALTER TABLE #local.tableName# ADD core_level INT NOT NULL DEFAULT 1";
					} else if (FindNoCase("Oracle", local.dbType)) {
						local.renameSQL = "RENAME migratorversions TO #local.tableName#";
						local.createSQL = "CREATE TABLE #local.tableName# (version VARCHAR2(25), core_level NUMBER DEFAULT 1 NOT NULL)";
						local.addColumnSQL = "ALTER TABLE #local.tableName# ADD core_level NUMBER DEFAULT 1 NOT NULL";
					} else {
						// Fallback: Postgres, MySQL and H2
						local.renameSQL = "ALTER TABLE migratorversions RENAME TO #local.tableName#";
						local.createSQL = "CREATE TABLE #local.tableName# (version VARCHAR(25), core_level INT NOT NULL DEFAULT 1)";
						local.addColumnSQL = "ALTER TABLE #local.tableName# ADD core_level INT NOT NULL DEFAULT 1";
					}

					try {
						$query(
							datasource=application[local.appKey].dataSourceName,
							sql="SELECT version FROM migratorversions"
						);
						$query(
							datasource=application[local.appKey].dataSourceName,
							sql=local.renameSQL
						);
						$query(
							datasource=application[local.appKey].dataSourceName,
							sql=local.addColumnSQL
						);
						$query(
							datasource=application[local.appKey].dataSourceName,
							sql="ALTER TABLE #local.tableName# ADD CONSTRAINT #local.fkName# FOREIGN KEY (core_level) REFERENCES #local.levelsTable#(id)"
						);
					} catch (any e) {
						// If rename fails, create table instead
						$query(
							datasource=application[local.appKey].dataSourceName,
							sql=local.createSQL
						);
						$query(
							datasource=application[local.appKey].dataSourceName,
							sql="ALTER TABLE #local.tableName# ADD CONSTRAINT #local.fkName# FOREIGN KEY (core_level) REFERENCES #local.levelsTable#(id)"
						);
					}
				}
			}
			// Tracking table was just bootstrapped — add the enriched
			// columns now so subsequent $setVersionAsMigrated calls can
			// write the migration name + applied timestamp.
			$maybeEnsureTrackingColumns(local.appKey);
			return 0;
		}
	}

	/**
	 * App-scope-cached wrapper around $ensureTrackingColumns(). Runs the
	 * ALTER once per app process. The probe inside $ensureTrackingColumns()
	 * is a cheap column listing, but caching avoids it on every migrator
	 * call. Non-fatal: if the ALTER fails, we just don't set the flag and
	 * the legacy schema continues to work.
	 */
	private void function $maybeEnsureTrackingColumns(required string appKey) {
		if (StructKeyExists(application[arguments.appKey], "$trackingColumnsEnsured")) {
			return;
		}
		try {
			$ensureTrackingColumns();
			application[arguments.appKey].$trackingColumnsEnsured = true;
		} catch (any e) {
			// Stays uncached so a future call retries — but the legacy
			// schema still works, so the migrator is not blocked.
		}
	}

	/**
	 * Returns versions recorded in the tracking table that have no matching
	 * migration file in the current checkout. Used to detect the "shared dev
	 * database" case where a peer has applied a migration whose file isn't
	 * yet in the local branch. See issue #2780.
	 *
	 * Result is sorted ascending. The sentinel "0" returned by
	 * $getVersionsPreviouslyMigrated() on an empty tracking table is excluded.
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public array function $getOrphanVersions() {
		local.appliedList = ListToArray($getVersionsPreviouslyMigrated());
		local.fileVersions = [];
		for (local.m in getAvailableMigrations()) {
			ArrayAppend(local.fileVersions, local.m.version);
		}
		local.orphans = [];
		for (local.v in local.appliedList) {
			if (Len(local.v) && local.v != "0" && !ArrayFind(local.fileVersions, local.v)) {
				ArrayAppend(local.orphans, local.v);
			}
		}
		ArraySort(local.orphans, function(a, b) {
			return Compare(a, b);
		});
		return local.orphans;
	}

	/**
	 * Returns orphan versions enriched with the `name` and `applied_at`
	 * columns from the tracking table — when those columns exist (the
	 * Plan 3 schema enrichment). Falls back to bare-version structs when
	 * the columns aren't present yet (older installs that haven't bootstrapped
	 * via $maybeEnsureTrackingColumns).
	 *
	 * Each row: {version, name, appliedAt} where name and appliedAt are
	 * empty strings for legacy rows that pre-date the schema enrichment.
	 *
	 * Result is sorted ascending by version, matching $getOrphanVersions().
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public array function $getOrphanVersionsWithMeta() {
		local.bareOrphans = $getOrphanVersions();
		local.rv = [];
		if (!ArrayLen(local.bareOrphans)) {
			return local.rv;
		}
		local.appKey = $appKey();
		local.hasEnrichedColumns = StructKeyExists(application[local.appKey], "$trackingColumnsEnsured");
		if (!local.hasEnrichedColumns) {
			// Schema enrichment not active — return bare structs so callers
			// can render version-only.
			for (local.v in local.bareOrphans) {
				ArrayAppend(local.rv, {version: local.v, name: "", appliedAt: ""});
			}
			return local.rv;
		}
		// Pull name + applied_at for the orphan versions in one query.
		try {
			local.versionsQuoted = "'" & ArrayToList(local.bareOrphans, "','") & "'";
			local.rows = $query(
				datasource = application[local.appKey].dataSourceName,
				sql = "SELECT version, name, applied_at FROM #application[local.appKey].migratorTableName# "
					& "WHERE version IN (#local.versionsQuoted#) "
					& "AND core_level = #application[local.appKey].migrationLevel# "
					& "ORDER BY version ASC"
			);
			local.metaByVersion = {};
			for (local.row in local.rows) {
				local.metaByVersion[local.row.version] = {
					name: local.row.name ?: "",
					appliedAt: IsDate(local.row.applied_at ?: "") ? DateTimeFormat(local.row.applied_at, "yyyy-mm-dd HH:nn:ss") : ""
				};
			}
			for (local.v in local.bareOrphans) {
				local.meta = local.metaByVersion[local.v] ?: {name: "", appliedAt: ""};
				ArrayAppend(local.rv, {
					version: local.v,
					name: local.meta.name,
					appliedAt: local.meta.appliedAt
				});
			}
		} catch (any e) {
			// If the enriched query fails (e.g. columns not yet committed on
			// a different connection), fall back to bare structs.
			for (local.v in local.bareOrphans) {
				ArrayAppend(local.rv, {version: local.v, name: "", appliedAt: ""});
			}
		}
		return local.rv;
	}

	/**
	 * Builds the human-readable info output for `wheels migrate info`.
	 * Returns an array of lines (caller joins with newlines). Extracted
	 * from cli.cfm's info handler so the rendering can be unit-tested
	 * without exercising the HTTP dispatcher. Orphan rows (DB versions
	 * with no matching local file — see issue #2780) are marked with
	 * [?] and the literal "********** NO FILE **********", Rails-style.
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public array function $buildInfoOutput() {
		local.lines = [];
		local.migrations = getAvailableMigrations();
		local.currentVersion = getCurrentMigrationVersion();
		local.orphansWithMeta = $getOrphanVersionsWithMeta();
		local.applied = 0;
		local.pending = 0;
		for (local.m in local.migrations) {
			if (local.m.status == "migrated") {
				local.applied++;
			} else {
				local.pending++;
			}
		}
		ArrayAppend(local.lines, "Current version: " & (Len(local.currentVersion) ? local.currentVersion : "0"));
		ArrayAppend(local.lines, "Total migrations: " & ArrayLen(local.migrations));
		if (ArrayLen(local.migrations) || ArrayLen(local.orphansWithMeta)) {
			ArrayAppend(local.lines, "  applied: " & local.applied);
			ArrayAppend(local.lines, "  pending: " & local.pending);
			if (ArrayLen(local.orphansWithMeta)) {
				ArrayAppend(local.lines, "  orphan: " & ArrayLen(local.orphansWithMeta));
			}
			ArrayAppend(local.lines, "");
			ArrayAppend(local.lines, "Migrations (newest last):");
			// Merge file rows + orphan rows into one chronological list so
			// orphans appear in the right position relative to local files.
			// Orphans with enriched metadata (Plan 3) show the peer's
			// migration name + apply timestamp; legacy orphans (no name
			// column) fall back to the literal NO FILE marker.
			local.combined = [];
			for (local.m in local.migrations) {
				ArrayAppend(local.combined, {
					version: local.m.version,
					name: local.m.name,
					appliedAt: "",
					marker: local.m.status == "migrated" ? "[x]" : "[ ]"
				});
			}
			for (local.o in local.orphansWithMeta) {
				ArrayAppend(local.combined, {
					version: local.o.version,
					name: Len(local.o.name) ? local.o.name : "********** NO FILE **********",
					appliedAt: local.o.appliedAt,
					marker: "[?]"
				});
			}
			ArraySort(local.combined, function(a, b) {
				return Compare(a.version, b.version);
			});
			for (local.row in local.combined) {
				local.line = "  " & local.row.marker & " " & local.row.version & " " & local.row.name;
				if (Len(local.row.appliedAt)) {
					local.line &= " (applied " & local.row.appliedAt & ")";
				}
				ArrayAppend(local.lines, local.line);
			}
			if (ArrayLen(local.orphansWithMeta)) {
				ArrayAppend(local.lines, "");
				ArrayAppend(local.lines, "Orphan versions are recorded in the database but have no");
				ArrayAppend(local.lines, "matching file in app/migrator/migrations/. This usually means");
				ArrayAppend(local.lines, "a peer applied a migration whose file isn't yet in your branch.");
			}
		}
		return local.lines;
	}

	/**
	 * Returns a comprehensive health report on the migrator state. Pure
	 * read — no mutation. Used by `wheels migrate doctor` to surface
	 * orphans, gaps, and pending migrations in one pass.
	 *
	 * Result struct:
	 *   - healthy: boolean — true iff no orphans AND no pending
	 *   - currentVersion: string — highest applied version (may be orphan)
	 *   - orphans: array — DB versions with no matching file
	 *   - pending: array — local files not yet applied
	 *   - summary: struct with .total, .applied, .pending, .orphan counts
	 *   - message: human-readable one-paragraph summary
	 *
	 * See issue #2780 / PR #2798 for the orphan detection foundation.
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public struct function doctor() {
		local.migrations = getAvailableMigrations();
		local.orphans = $getOrphanVersions();
		local.orphansWithMeta = $getOrphanVersionsWithMeta();
		local.currentVersion = getCurrentMigrationVersion();
		local.pending = [];
		local.applied = 0;
		for (local.m in local.migrations) {
			if (local.m.status == "migrated") {
				local.applied++;
			} else {
				ArrayAppend(local.pending, local.m.version);
			}
		}
		local.healthy = ArrayLen(local.orphans) == 0 && ArrayLen(local.pending) == 0;
		local.rv = {
			healthy: local.healthy,
			currentVersion: local.currentVersion,
			orphans: local.orphans,
			orphansWithMeta: local.orphansWithMeta,
			pending: local.pending,
			summary: {
				total: ArrayLen(local.migrations),
				applied: local.applied,
				pending: ArrayLen(local.pending),
				orphan: ArrayLen(local.orphans)
			}
		};
		if (local.healthy) {
			local.rv.message = "Migrator is healthy. " & local.applied & " migration(s) applied, none pending.";
		} else {
			local.parts = [];
			if (ArrayLen(local.pending)) {
				ArrayAppend(local.parts, ArrayLen(local.pending) & " pending");
			}
			if (ArrayLen(local.orphans)) {
				ArrayAppend(local.parts, ArrayLen(local.orphans) & " orphan");
			}
			local.rv.message = "Migrator needs attention: " & ArrayToList(local.parts, ", ") & ".";
		}
		return local.rv;
	}

	/**
	 * Removes a row from `wheels_migrator_versions` without running
	 * down(). Only orphan versions (those with no matching local file)
	 * can be forgotten — for legitimate rollbacks, use `migrate down`.
	 *
	 * Returns: {success, removed, message}
	 *
	 * @version The version string to forget (digits only after sanitisation).
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public struct function forgetVersion(required string version) {
		local.rv = {success: false, removed: "", message: ""};
		local.cleanVersion = $sanitiseVersion(arguments.version);
		if (!Len(local.cleanVersion)) {
			local.rv.message = "Invalid version: must contain at least one digit.";
			return local.rv;
		}
		local.appliedList = ListToArray($getVersionsPreviouslyMigrated());
		if (!ArrayFind(local.appliedList, local.cleanVersion)) {
			local.rv.message = "Version " & local.cleanVersion & " was not found in the tracking table.";
			return local.rv;
		}
		// Refuse to forget a version that has a matching local file. The
		// user almost certainly wants `migrate down` instead; forgetting
		// would leave the schema mutated but the row gone, hiding state.
		for (local.m in getAvailableMigrations()) {
			if (local.m.version == local.cleanVersion) {
				local.rv.message = "Refusing to forget version " & local.cleanVersion
					& " because a matching local file exists "
					& "(app/migrator/migrations/" & local.m.cfcfile & ".cfc). "
					& "Use `wheels migrate down` to roll it back properly.";
				return local.rv;
			}
		}
		// Delegate the actual delete to the existing private helper so
		// the request.$wheelsDebugSQL guard fires uniformly — matches
		// what pretendVersion() does via $setVersionAsMigrated().
		$removeVersionAsMigrated(local.cleanVersion);
		local.rv.success = true;
		local.rv.removed = local.cleanVersion;
		local.rv.message = "Removed version " & local.cleanVersion & " from the tracking table.";
		return local.rv;
	}

	/**
	 * Records a version as applied in `wheels_migrator_versions` without
	 * running its up() method. Useful when a peer applied the migration
	 * via direct SQL or a different tool and you need the tracking
	 * table to reflect that. Refuses if the version is already applied,
	 * or if no local file matches (only known versions can be pretended).
	 *
	 * Returns: {success, recorded, message}
	 *
	 * @version The version string to record (digits only after sanitisation).
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public struct function pretendVersion(required string version) {
		local.rv = {success: false, recorded: "", message: ""};
		local.cleanVersion = $sanitiseVersion(arguments.version);
		if (!Len(local.cleanVersion)) {
			local.rv.message = "Invalid version: must contain at least one digit.";
			return local.rv;
		}
		local.appliedList = ListToArray($getVersionsPreviouslyMigrated());
		if (ArrayFind(local.appliedList, local.cleanVersion)) {
			local.rv.message = "Version " & local.cleanVersion & " is already applied. "
				& "Use `wheels migrate forget` if you need to remove the tracking row.";
			return local.rv;
		}
		local.fileExists = false;
		local.matchedName = "";
		for (local.m in getAvailableMigrations()) {
			if (local.m.version == local.cleanVersion) {
				local.fileExists = true;
				local.matchedName = local.m.name;
				break;
			}
		}
		if (!local.fileExists) {
			local.rv.message = "Refusing to pretend version " & local.cleanVersion
				& " — no matching file in app/migrator/migrations/. "
				& "Create the migration file first, then pretend if it has already been applied externally.";
			return local.rv;
		}
		$setVersionAsMigrated(local.cleanVersion, local.matchedName);
		local.rv.success = true;
		local.rv.recorded = local.cleanVersion;
		local.rv.message = "Recorded version " & local.cleanVersion & " as applied (up() was not run).";
		return local.rv;
	}

	/**
	 * F15 Phase 1: detect which system-table naming family this app's database
	 * already uses, and flip the configured names if needed.
	 *
	 * Decision tree:
	 *   1. If `wheels_levels` exists, keep the new defaults (no-op).
	 *   2. Else if `c_o_r_e_levels` exists, override application settings to
	 *      point at the legacy names AND log a one-time deprecation warning.
	 *   3. Else (neither exists, fresh DB), keep the new defaults — the
	 *      bootstrap below will create `wheels_*` tables.
	 *
	 * Step 2 is the migration-friendly path: existing 4.0-SNAPSHOT apps that
	 * already have `c_o_r_e_*` tables continue to read/write them without
	 * any code or data changes. Phase 2 will ship a CLI command to do the
	 * rename when the user is ready.
	 *
	 * Idempotent and stateless — re-runs every call. The probe is two cheap
	 * SELECTs each returning 0 rows; per-request caching breaks test isolation
	 * (the spec suite shares a request scope across tests) so we just don't.
	 */
	private void function $detectSystemTables(required string appKey) {
		// Cache the datasource locally — the inline closure below uses its
		// own `arguments` scope (CFML closures don't inherit the parent's
		// `arguments` struct), so we need to pull the value out by reference
		// before the closure sees it.
		var dsn = application[arguments.appKey].dataSourceName;

		// Always probe with a no-rows query so we don't load data unnecessarily.
		// `WHERE 1=0` is portable across every adapter we support.
		var probe = function(tableName) {
			try {
				$query(
					datasource = dsn,
					sql = "SELECT 1 FROM #arguments.tableName# WHERE 1=0"
				);
				return true;
			} catch (any e) {
				return false;
			}
		};

		if (probe(application[arguments.appKey].levelsTableName)) {
			// Configured name exists — nothing to do.
			return;
		}

		if (probe("c_o_r_e_levels")) {
			// Legacy install. Override settings to match what's actually on disk.
			application[arguments.appKey].levelsTableName = "c_o_r_e_levels";
			application[arguments.appKey].migratorTableName = "c_o_r_e_migrator_versions";
			// Quiet stderr warning — fires once per migrator run, not per request.
			if (StructKeyExists(server, "system") && StructKeyExists(server.system, "out")) {
				server.system.out.println(
					"[wheels] Legacy c_o_r_e_* migration tables detected. "
					& "These will be renamed to wheels_* in a future Wheels release; "
					& "see the upgrade guide for the rename procedure."
				);
			}
		}

		// If neither exists, we leave the configured `wheels_*` defaults in
		// place; the bootstrap path below will create them.
	}

	/**
	 * F15 Phase 2: rename legacy `c_o_r_e_*` system tables to `wheels_*`.
	 *
	 * Public API for the `wheels migrate rename-system-tables` CLI command.
	 * Reads the current schema, generates per-adapter rename SQL, and
	 * (unless `dryRun` is true) executes it inside a transaction. After
	 * a successful rename, updates `application.wheels.{levelsTableName,
	 * migratorTableName}` to the new names so the running app picks them
	 * up without a restart.
	 *
	 * Result struct:
	 *   - success: boolean
	 *   - renamed: array of "old -> new" strings (empty if no-op)
	 *   - skipped: human message when there's nothing to do
	 *   - errors: array of error messages (when success=false)
	 *   - sql: array of SQL statements that would run / did run
	 *
	 * Refuses to run (returns success=false) when both `c_o_r_e_*` AND
	 * `wheels_*` versions of either table coexist — that's a partial-
	 * rename state which warrants manual cleanup, not silent destruction.
	 *
	 * @dryRun When true, returns the SQL that would run without executing.
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public struct function renameSystemTables(boolean dryRun = false) {
		var rv = {
			success: true,
			renamed: [],
			skipped: "",
			errors: [],
			sql: []
		};
		var appKey = $appKey();
		var dsn = application[appKey].dataSourceName;

		// Inline probe (CFML closures don't inherit parent `arguments`, so
		// `dsn` is captured via lexical scope — see $detectSystemTables for
		// the same pattern).
		var probe = function(tableName) {
			try {
				$query(datasource = dsn, sql = "SELECT 1 FROM #arguments.tableName# WHERE 1=0");
				return true;
			} catch (any e) {
				return false;
			}
		};

		var hasLegacyLevels   = probe("c_o_r_e_levels");
		var hasLegacyVersions = probe("c_o_r_e_migrator_versions");
		var hasNewLevels      = probe("wheels_levels");
		var hasNewVersions    = probe("wheels_migrator_versions");

		// Nothing to rename — already on `wheels_*` or fresh DB.
		if (!hasLegacyLevels && !hasLegacyVersions) {
			rv.skipped = "Nothing to rename. Legacy c_o_r_e_* tables are not present.";
			return rv;
		}

		// Refuse on partial-rename state. Renaming `c_o_r_e_levels` →
		// `wheels_levels` when `wheels_levels` already exists would either
		// fail with a "table exists" error mid-transaction or silently
		// corrupt one of them depending on adapter. Better to stop and let
		// the user reconcile manually.
		if (
			(hasLegacyLevels && hasNewLevels)
			|| (hasLegacyVersions && hasNewVersions)
		) {
			rv.success = false;
			ArrayAppend(
				rv.errors,
				"Both legacy c_o_r_e_* and new wheels_* system tables exist. "
				& "Manual cleanup required to avoid data loss — drop whichever set is empty before re-running."
			);
			return rv;
		}

		// Build per-adapter rename SQL. The migrator-versions table is
		// renamed first so any FK constraint pointing at c_o_r_e_levels
		// follows naturally when levels is renamed last (every supported
		// engine auto-updates FK references on table rename).
		var info = $dbinfo(
			type = "version",
			datasource = dsn,
			username = application.wheels.dataSourceUserName,
			password = application.wheels.dataSourcePassword
		);
		var dbType = info.database_productname;

		if (FindNoCase("MySQL", dbType)) {
			// MySQL atomic multi-rename — both pairs in one statement.
			var pairs = [];
			if (hasLegacyVersions) ArrayAppend(pairs, "c_o_r_e_migrator_versions TO wheels_migrator_versions");
			if (hasLegacyLevels)   ArrayAppend(pairs, "c_o_r_e_levels TO wheels_levels");
			ArrayAppend(rv.sql, "RENAME TABLE " & ArrayToList(pairs, ", "));
		} else if (FindNoCase("SQLServer", dbType) || FindNoCase("SQL Server", dbType)) {
			if (hasLegacyVersions) ArrayAppend(rv.sql, "EXEC sp_rename 'c_o_r_e_migrator_versions', 'wheels_migrator_versions'");
			if (hasLegacyLevels)   ArrayAppend(rv.sql, "EXEC sp_rename 'c_o_r_e_levels', 'wheels_levels'");
		} else if (FindNoCase("Oracle", dbType)) {
			if (hasLegacyVersions) ArrayAppend(rv.sql, "RENAME c_o_r_e_migrator_versions TO wheels_migrator_versions");
			if (hasLegacyLevels)   ArrayAppend(rv.sql, "RENAME c_o_r_e_levels TO wheels_levels");
		} else {
			// SQLite, PostgreSQL, H2, CockroachDB
			if (hasLegacyVersions) ArrayAppend(rv.sql, "ALTER TABLE c_o_r_e_migrator_versions RENAME TO wheels_migrator_versions");
			if (hasLegacyLevels)   ArrayAppend(rv.sql, "ALTER TABLE c_o_r_e_levels RENAME TO wheels_levels");
		}

		// Dry-run returns the plan without executing.
		if (arguments.dryRun) {
			return rv;
		}

		// Execute. Wrap in a transaction so a partial failure rolls back
		// rather than leaving a half-renamed schema. Postgres and SQLite
		// (via SAVEPOINT) honor the wrapper and roll back DDL on error.
		// MySQL DDL also implicitly commits (the wrapper is a no-op there),
		// but MySQL's multi-pair `RENAME TABLE a TO a', b TO b'` is itself
		// a single atomic statement, so no partial-rename arises. MSSQL has
		// adapter-specific behavior. On Oracle the implicit DDL commit
		// closes the JDBC statement, so a subsequent
		// `transaction action="commit"` reports "Closed statement" — run
		// the DDL bare on Oracle. There is no rollback to forfeit.
		try {
			if (FindNoCase("Oracle", dbType)) {
				for (var sql in rv.sql) {
					$query(datasource = dsn, sql = sql);
				}
			} else {
				transaction action="begin" {
					try {
						for (var sql in rv.sql) {
							$query(datasource = dsn, sql = sql);
						}
						transaction action="commit";
					} catch (any e) {
						transaction action="rollback";
						rethrow;
					}
				}
			}

			if (hasLegacyLevels)   ArrayAppend(rv.renamed, "c_o_r_e_levels -> wheels_levels");
			if (hasLegacyVersions) ArrayAppend(rv.renamed, "c_o_r_e_migrator_versions -> wheels_migrator_versions");

			// Update in-memory settings so the running app uses the new names
			// without a restart. (Settings are reloaded from
			// onapplicationstart on next reload anyway.)
			application[appKey].levelsTableName    = "wheels_levels";
			application[appKey].migratorTableName  = "wheels_migrator_versions";
		} catch (any e) {
			rv.success = false;
			ArrayAppend(rv.errors, e.message);
		}

		return rv;
	}

	/**
	 * Adds `name` (VARCHAR(255) NULL) and `applied_at` (TIMESTAMP NULL DEFAULT
	 * CURRENT_TIMESTAMP) columns to `wheels_migrator_versions` if they don't
	 * already exist. Enables `wheels migrate info` and `wheels migrate doctor`
	 * to show the migration name and apply timestamp for each tracked version
	 * — including orphan rows where the file isn't in the local checkout.
	 *
	 * Idempotent: skips ALTER when columns are already present. Cached on
	 * `application[appKey].$trackingColumnsEnsured` to avoid repeating the
	 * column probe on every migrator call within one app process.
	 *
	 * Per-engine SQL handled inline (matches the existing $detectSystemTables
	 * / renameSystemTables patterns). SQLite skips DEFAULT on applied_at —
	 * the column lands NULL and CFML writes Now() when $setVersionAsMigrated
	 * is called with a name. Other engines use CURRENT_TIMESTAMP default.
	 *
	 * Result: {hasName, hasAppliedAt, added: array of column names, errors: array}.
	 *
	 * [section: Migrator]
	 * [category: General Functions]
	 */
	public struct function $ensureTrackingColumns() {
		var rv = {hasName: false, hasAppliedAt: false, added: [], errors: []};
		var appKey = $appKey();
		var dsn = application[appKey].dataSourceName;
		var tableName = application[appKey].migratorTableName;

		try {
			var cols = $dbinfo(
				datasource = dsn,
				type = "columns",
				table = tableName
			);
		} catch (any e) {
			// Table doesn't exist yet; nothing to do. The columns will be
			// added the first time someone calls migrateTo() and the bootstrap
			// path creates the table.
			ArrayAppend(rv.errors, "Could not probe columns on " & tableName & ": " & e.message);
			return rv;
		}

		var existingCols = ValueList(cols.column_name);
		rv.hasName = ListFindNoCase(existingCols, "name") > 0;
		rv.hasAppliedAt = ListFindNoCase(existingCols, "applied_at") > 0;

		if (rv.hasName && rv.hasAppliedAt) {
			return rv;
		}

		var info = $dbinfo(
			type = "version",
			datasource = dsn,
			username = application.wheels.dataSourceUserName,
			password = application.wheels.dataSourcePassword
		);
		var dbType = info.database_productname;

		// Build per-engine ALTER statements for the missing columns.
		// Each ALTER is its own statement so a partial-add state still
		// completes on re-run (e.g. name added, applied_at failed → retry
		// adds only applied_at).
		var statements = [];
		if (!rv.hasName) {
			if (FindNoCase("Oracle", dbType)) {
				ArrayAppend(statements, {col: "name", sql: "ALTER TABLE #tableName# ADD (name VARCHAR2(255))"});
			} else if (FindNoCase("SQLServer", dbType) || FindNoCase("SQL Server", dbType)) {
				ArrayAppend(statements, {col: "name", sql: "ALTER TABLE #tableName# ADD name VARCHAR(255) NULL"});
			} else {
				// MySQL, PostgreSQL, SQLite, H2, CockroachDB
				ArrayAppend(statements, {col: "name", sql: "ALTER TABLE #tableName# ADD COLUMN name VARCHAR(255) NULL"});
			}
		}
		if (!rv.hasAppliedAt) {
			if (FindNoCase("Oracle", dbType)) {
				ArrayAppend(statements, {col: "applied_at", sql: "ALTER TABLE #tableName# ADD (applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"});
			} else if (FindNoCase("SQLServer", dbType) || FindNoCase("SQL Server", dbType)) {
				ArrayAppend(statements, {col: "applied_at", sql: "ALTER TABLE #tableName# ADD applied_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP"});
			} else if (FindNoCase("MySQL", dbType)) {
				ArrayAppend(statements, {col: "applied_at", sql: "ALTER TABLE #tableName# ADD COLUMN applied_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP"});
			} else if (FindNoCase("SQLite", dbType)) {
				// SQLite cannot DEFAULT a TIMESTAMP on existing-table ADD COLUMN
				// (only on CREATE TABLE). The column lands NULL; CFML supplies
				// Now() at $setVersionAsMigrated time.
				ArrayAppend(statements, {col: "applied_at", sql: "ALTER TABLE #tableName# ADD COLUMN applied_at TEXT"});
			} else {
				// PostgreSQL, H2, CockroachDB
				ArrayAppend(statements, {col: "applied_at", sql: "ALTER TABLE #tableName# ADD COLUMN applied_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP"});
			}
		}

		for (var stmt in statements) {
			try {
				$query(datasource = dsn, sql = stmt.sql);
				ArrayAppend(rv.added, stmt.col);
				if (stmt.col == "name") rv.hasName = true;
				if (stmt.col == "applied_at") rv.hasAppliedAt = true;
			} catch (any e) {
				ArrayAppend(rv.errors, stmt.col & " ALTER failed: " & e.message);
			}
		}

		return rv;
	}

	/**
	 * Ensures a version as user input is numeric.
	 */
	private string function $sanitiseVersion(required string version) {
		return ReReplaceNoCase(arguments.version, "[^0-9]", "", "all");
	}

	/**
	 * Writes a migration file
	 */
	private void function $writeMigrationFile(required string filePath, required string data) {
		FileWrite(arguments.filePath, arguments.data);
		// this try/catch may be unnecessary, but is in place in case FileSetAccessMode throws an exception on non *nix OS
		try {
			FileSetAccessMode(arguments.filePath, "664");
		} catch (any e) {
			// move along
		}
	}

}
