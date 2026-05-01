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

		if (local.currentVersion == arguments.version && !local.hasPendingMigrations) {
			local.rv = "Database is currently at version #arguments.version#. No migration required.#Chr(13) & Chr(10)#";
		} else {
			if (!DirectoryExists(this.paths.sql) && application[local.appKey].writeMigratorSQLFiles) {
				DirectoryCreate(this.paths.sql);
			}
			if (local.currentVersion > arguments.version && arguments.missingMigFlag == false) {
				local.rv = "Migrating from #local.currentVersion# down to #arguments.version#.#Chr(13) & Chr(10)#";
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
					local.rv = "Migrating remaining migrations till #arguments.version#.#Chr(13) & Chr(10)#";
					$removeVersionAsMigrated(local.currentVersion);
				} else if (local.currentVersion gte arguments.version && local.hasPendingMigrations) {
					// Out-of-order pending migrations: a migration with a
					// timestamp earlier than currentVersion is still pending
					// (e.g. tutorial chapter 5 hardcodes 20260419130000 while
					// the user's chapter 2 posts migration sits at the
					// generator's current-day timestamp). The "from N up to N"
					// framing reads as a no-op even though new migrations are
					// about to run, so emit a clearer message. Onboarding F16.
					local.rv = "Applying pending migration(s) up to #arguments.version#.#Chr(13) & Chr(10)#";
				} else {
					local.rv = "Migrating from #local.currentVersion# up to #arguments.version#.#Chr(13) & Chr(10)#";
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
								$setVersionAsMigrated(local.migration.version);
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
				$setVersionAsMigrated(local.migration.version);
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
	 * Inserts a record to flag a version as migrated.
	 */
	private void function $setVersionAsMigrated(required string version) {
		local.appKey = $appKey();
		if (!StructKeyExists(request, "$wheelsDebugSQL"))
			$query(
				datasource = application[local.appKey].dataSourceName,
				sql = "INSERT INTO #application[local.appKey].migratorTableName# (version, core_level) VALUES ('#$sanitiseVersion(arguments.version)#', #application[local.appKey].migrationLevel#)"
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
			return 0;
		}
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
