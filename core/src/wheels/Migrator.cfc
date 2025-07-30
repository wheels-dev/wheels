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
		if (local.currentVersion == arguments.version) {
			local.rv = "Database is currently at version #arguments.version#. No migration required.#Chr(13)#";
		} else {
			if (!DirectoryExists(this.paths.sql) && application[local.appKey].writeMigratorSQLFiles) {
				DirectoryCreate(this.paths.sql);
			}
			local.migrations = getAvailableMigrations();
			if (local.currentVersion > arguments.version && arguments.missingMigFlag == false) {
				local.rv = "Migrating from #local.currentVersion# down to #arguments.version#.#Chr(13)#";
				for (local.i = ArrayLen(local.migrations); local.i >= 1; local.i--) {
					local.migration = local.migrations[local.i];
					if (local.migration.version <= arguments.version) {
						break;
					}
					if (local.migration.status == "migrated" && application[local.appKey].allowMigrationDown) {
						transaction action="begin" {
							try {
								// Test query to establish datasource for BoxLang compatibility
								$query(datasource = application[local.appKey].dataSourceName, sql = "SELECT 1 as test");
								local.rv = local.rv & "#Chr(13)#------- " & local.migration.cfcfile & " #RepeatString("-", Max(5, 50 - Len(local.migration.cfcfile)))##Chr(13)#";
								request.$wheelsMigrationOutput = "";
								request.$wheelsMigrationSQLFile = "#this.paths.sql#/#local.migration.cfcfile#_down.sql";
								if (application[local.appKey].writeMigratorSQLFiles) {
									$writeMigrationFile(request.$wheelsMigrationSQLFile, "");
								}
								local.migration.cfc.down();
								local.rv = local.rv & request.$wheelsMigrationOutput;
								$removeVersionAsMigrated(local.migration.version);
							} catch (any e) {
								local.rv = local.rv & "Error migrating to #local.migration.version#.#Chr(13)##e.message##Chr(13)##e.detail##Chr(13)#";
								transaction action="rollback";
								break;
							}
							transaction action="commit";
						}
					}
				}
			} else {
				if(arguments.missingMigFlag){
					local.rv = "Migrating remaining migrations till #arguments.version#.#Chr(13)#";
					$removeVersionAsMigrated(local.currentVersion);
				} else {
					local.rv = "Migrating from #local.currentVersion# up to #arguments.version#.#Chr(13)#";
				}
				for (local.migration in local.migrations) {
					if (local.migration.version <= arguments.version && local.migration.status != "migrated") {
						transaction {
							try {
								// Test query to establish datasource for BoxLang compatibility
								$query(datasource = application[local.appKey].dataSourceName, sql = "SELECT 1 as test");
								local.rv = local.rv & "#Chr(13)#-------- " & local.migration.cfcfile & " #RepeatString("-", Max(5, 50 - Len(local.migration.cfcfile)))##Chr(13)#";
								request.$wheelsMigrationOutput = "";
								request.$wheelsMigrationSQLFile = "#this.paths.sql#/#local.migration.cfcfile#_up.sql";
								if (application[local.appKey].writeMigratorSQLFiles) {
									$writeMigrationFile(request.$wheelsMigrationSQLFile, "");
								}
								local.migration.cfc.up();
								local.rv = local.rv & request.$wheelsMigrationOutput;
								$setVersionAsMigrated(local.migration.version);
							} catch (any e) {
								local.rv = local.rv & "Error migrating to #local.migration.version#.#Chr(13)##e.message##Chr(13)##e.detail##Chr(13)#";
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
			return "Error re-running #arguments.version#.#Chr(13)#This version was not found#Chr(13)#";
		}

		local.migration = local.migrationArray[1];
		local.rv = "";
		try {
			local.rv = local.rv & "#Chr(13)#------- " & local.migration.cfcfile & " #RepeatString("-", Max(5, 50 - Len(local.migration.cfcfile)))##Chr(13)#";
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
			local.rv = local.rv & "Error re-running #local.migration.version#.#Chr(13)##e.message##Chr(13)##e.detail##Chr(13)#";
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

		/* Choose appropriate SQL syntax for LIMIT based on database engine */
		local.info = $dbinfo(
			type = "version",
			datasource = application.wheels.dataSourceName,
			username = application.wheels.dataSourceUserName,
			password = application.wheels.dataSourcePassword
		);
		if(FindNoCase("SQLServer", local.info.database_productname) || FindNoCase("SQL Server", local.info.database_productname)){
			local.sql = "SELECT TOP 1 * FROM c_o_r_e_levels";
		} else if(FindNoCase("Oracle", local.info.database_productname)){
			local.sql = "SELECT * FROM c_o_r_e_levels FETCH FIRST 1 ROWS ONLY";
		} else{
			local.sql = "SELECT * FROM c_o_r_e_levels LIMIT 1";
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
					sql = "CREATE TABLE c_o_r_e_levels (id INT PRIMARY KEY, name VARCHAR(50) NOT NULL, description VARCHAR(255))"
				);
				$query(
					datasource = application[local.appKey].dataSourceName,
					sql = "INSERT INTO c_o_r_e_levels (id, name, description) VALUES (1, 'App', 'Application level migrations')"
				);
				$query(
					datasource = application[local.appKey].dataSourceName,
					sql = "INSERT INTO c_o_r_e_levels (id, name, description) VALUES (2, 'Test', 'Test level migrations')"
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
				try {
					local.dbType = local.info.database_productname;
					local.tableName = application[local.appKey].migratorTableName;

					// DB-specific SQLs
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
					$query(
						datasource = application[local.appKey].dataSourceName,
						sql = "SELECT version FROM migratorversions"
					);
					$query(
						datasource = application[local.appKey].dataSourceName,
						sql = local.renameSQL
					);
					$query(
						datasource = application[local.appKey].dataSourceName,
						sql = local.addColumnSQL
					);
					$query(
						datasource = application[local.appKey].dataSourceName,
						sql = "ALTER TABLE #local.tableName# ADD CONSTRAINT fk_core_level FOREIGN KEY (core_level) REFERENCES c_o_r_e_levels(id)"
					);
				} catch (any e) {
					// If rename fails, create table instead
					$query(
						datasource = application[local.appKey].dataSourceName,
						sql = local.createSQL
					);
					$query(
						datasource = application[local.appKey].dataSourceName,
						sql = "ALTER TABLE #local.tableName# ADD CONSTRAINT fk_core_level FOREIGN KEY (core_level) REFERENCES c_o_r_e_levels(id)"
					);
				}
			}
			return 0;
		}
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
