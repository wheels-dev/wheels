/**
 * Hardener SHOULDs S1–S20 (migrator / schema).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 *
 * Escalations (no silent public default/API flips): S9, S15, S16, S17, S20.
 * allowMigrationDown default stays false.
 */
component extends="wheels.WheelsTest" {

	include "../migrator/helperFunctions.cfm";

	function beforeAll() {
		variables.g = application.wo;
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.sqlMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
		variables.loadErrorMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/loaderror/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_loaderror/"
		);
		variables.autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
		variables.isCockroachDB = variables.migration.adapter.adapterName() == "CockroachDB";
	}

	function run() {

		describe("S1 migrateTo down does not look successful when allowMigrationDown is false", () => {

			beforeEach(() => {
				deleteMigratorVersions(2);
				try {
					variables.migration.dropTable("c_o_r_e_bunyips");
				} catch (any e) {}
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				try {
					variables.migration.dropTable("c_o_r_e_bunyips");
				} catch (any e) {}
			});

			it("refuses down with an explicit allowMigrationDown message instead of a no-op success banner", () => {
				if (variables.isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var priorDown = application.wheels.allowMigrationDown;
				application.wheels.allowMigrationDown = true;
				try {
					variables.sqlMigrator.migrateTo("001");
				} finally {
					application.wheels.allowMigrationDown = priorDown;
				}
				application.wheels.allowMigrationDown = false;
				try {
					var output = variables.sqlMigrator.migrateTo("0");
					expect(output).toInclude("allowMigrationDown");
					expect(FindNoCase("Migrating from", output)).toBe(
						0,
						"Blocked down must not print the successful Migrating-from-X-down banner."
					);
					var rows = queryExecute(
						"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '001'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					expect(rows.recordCount).toBe(1, "Blocked down must leave the version row in place.");
				} finally {
					application.wheels.allowMigrationDown = priorDown;
				}
			});

			it("does not flip the allowMigrationDown framework default", () => {
				var src = FileRead(ExpandPath("/wheels/events/onapplicationstart.cfc"));
				expect(src).toInclude("application.$wheels.allowMigrationDown = false");
			});

		});

		describe("S2 $getForeignKeys uses FK_NAME not FKCOLUMN_NAME", () => {

			it("reads constraint names from FK_NAME", () => {
				var q = QueryNew("FK_NAME,FKCOLUMN_NAME", "varchar,varchar");
				QueryAddRow(q);
				QuerySetCell(q, "FK_NAME", "FK_posts_users_userid", 1);
				QuerySetCell(q, "FKCOLUMN_NAME", "userid", 1);
				expect(variables.migration.$foreignKeyConstraintNames(q)).toBe("FK_posts_users_userid");
			});

			it("does not fall back to FKCOLUMN_NAME when FK_NAME is absent", () => {
				var q = QueryNew("FKCOLUMN_NAME", "varchar");
				QueryAddRow(q);
				QuerySetCell(q, "FKCOLUMN_NAME", "userid", 1);
				expect(variables.migration.$foreignKeyConstraintNames(q)).toBe("");
			});

		});

		describe("S3 versions table uniqueness is not JVM-lock-only", () => {

			it("creates the versions table with a PRIMARY KEY on version", () => {
				var src = FileRead(ExpandPath("/wheels/Migrator.cfc"));
				expect(src).toInclude("version VARCHAR(25) PRIMARY KEY");
				expect(src).toInclude("version VARCHAR2(25) PRIMARY KEY");
			});

			it("attempts a unique index on existing version tables", () => {
				var src = FileRead(ExpandPath("/wheels/Migrator.cfc"));
				expect(src).toInclude("$ensureVersionUniqueness");
				expect(src).toInclude("_version_uidx");
			});

		});

		describe("S4 updateRecord/removeRecord empty where is fail-closed", () => {

			it("throws when updateRecord is called with an empty where", () => {
				expect(() => {
					variables.migration.updateRecord(table = "c_o_r_e_tags", status = "x");
				}).toThrow("Wheels.Migrator.MissingWhere");
			});

			it("throws when removeRecord is called with an empty where", () => {
				expect(() => {
					variables.migration.removeRecord(table = "c_o_r_e_tags");
				}).toThrow("Wheels.Migrator.MissingWhere");
			});

			it("allows an explicit all=true wipe", () => {
				if (variables.isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var tableName = "dbm_hardener_s4_all";
				try {
					variables.migration.dropTable(tableName);
				} catch (any e) {}
				var t = variables.migration.createTable(name = tableName, force = true);
				t.string(columnNames = "label", allowNull = true);
				t.create();
				variables.migration.addRecord(table = tableName, label = "a");
				variables.migration.addRecord(table = tableName, label = "b");
				variables.migration.removeRecord(table = tableName, all = true);
				var rows = queryExecute(
					"SELECT * FROM #tableName#",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				try {
					variables.migration.dropTable(tableName);
				} catch (any e2) {}
				expect(rows.recordCount).toBe(0);
			});

		});

		describe("S5 loadError is checked before up/down", () => {

			it("does not invoke up() on a migration that failed to load", () => {
				if (variables.isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var output = variables.loadErrorMigrator.migrateTo("90000000000004");
				expect(output).toInclude("failed to load");
				expect(output).toInclude("intentional load failure for S5");
				expect(FindNoCase("must not run after loadError", output)).toBe(0);
			});

		});

		describe("S6 per-migration txn warns when DDL auto-commits", () => {

			it("flags MySQL and Oracle as DDL auto-commit engines", () => {
				var prior = application.wheels.$migratorDbType ?: "";
				var had = StructKeyExists(application.wheels, "$migratorDbType");
				try {
					application.wheels.$migratorDbType = "MySQL";
					expect(variables.sqlMigrator.$ddlAutoCommits()).toBeTrue();
					application.wheels.$migratorDbType = "Oracle";
					expect(variables.sqlMigrator.$ddlAutoCommits()).toBeTrue();
					application.wheels.$migratorDbType = "SQLite";
					expect(variables.sqlMigrator.$ddlAutoCommits()).toBeFalse();
				} finally {
					if (had) {
						application.wheels.$migratorDbType = prior;
					} else {
						StructDelete(application.wheels, "$migratorDbType");
					}
				}
			});

			it("documents that full DDL rollback is not implemented on those engines", () => {
				var src = FileRead(ExpandPath("/wheels/Migrator.cfc"));
				expect(src).toInclude("this database auto-commits DDL");
			});

		});

		describe("S7 Cockroach early return without skip is rejected", () => {

			it("does not use a bare Cockroach return in hardener or migrator specs", () => {
				var roots = [
					ExpandPath("/wheels/tests/specs/hardener"),
					ExpandPath("/wheels/tests/specs/migrator")
				];
				var offenders = [];
				for (var root in roots) {
					var files = DirectoryList(root, true, "path", "*Spec.cfc");
					for (var filePath in files) {
						var src = FileRead(filePath);
						if (ReFind("if\s*\((?:_isCockroachDB|isCockroachDB|ctx\.isCockroachDB)\)\s*return\s*;", src)) {
							ArrayAppend(offenders, filePath);
						}
					}
				}
				expect(ArrayLen(offenders)).toBe(
					0,
					"Bare Cockroach return marks the it() green: " & ArrayToList(offenders)
				);
			});

		});

		describe("S8 changeColumn default assertion matches the value written", () => {

			it("expects foo not bar for the changeColumn default", () => {
				var src = FileRead(ExpandPath("/wheels/tests/specs/migrator/migrationSpec.cfc"));
				expect(src).toInclude('expect(actual.default_value).toInclude("foo")');
				expect(Find('expect(actual.default_value).toInclude("bar")', src)).toBe(0);
			});

		});

		describe("S9 AutoMigrator unmapped columns stay opt-in for removal", () => {

			it("still emits removeColumns by default (no silent default flip)", () => {
				var result = variables.autoMigrator.diff("Author");
				expect(result).toHaveKey("unmappedColumns");
				expect(result).toHaveKey("removeColumns");
			});

			it("omits removeColumns when allowColumnRemoval is false", () => {
				var result = variables.autoMigrator.diff("Author", {allowColumnRemoval: false});
				expect(ArrayLen(result.removeColumns)).toBe(
					0,
					"allowColumnRemoval=false must not schedule destructive drops."
				);
			});

		});

		describe("S10 generateMigrationCFC rejects unsafe identifiers", () => {

			it("throws when a table name would break out of a CFML string", () => {
				var diffResult = {
					modelName: "TestModel",
					tableName: 'users"; announce("pwned"); //',
					addColumns: [],
					removeColumns: [],
					changeColumns: [],
					renameColumns: []
				};
				expect(() => {
					variables.autoMigrator.generateMigrationCFC(diffResult, "inject");
				}).toThrow("Wheels.Migrator.InvalidIdentifier");
			});

			it("strips quotes from the generated hint attribute", () => {
				var diffResult = {
					modelName: "TestModel",
					tableName: "test_models",
					addColumns: [],
					removeColumns: [],
					changeColumns: [],
					renameColumns: []
				};
				var cfc = variables.autoMigrator.generateMigrationCFC(diffResult, 'x" hint="evil');
				expect(Find('hint="evil', cfc)).toBe(0);
			});

		});

		describe("S11 auto-remove down() restores a typed column", () => {

			it("emits addColumn in down when the removed column type is known", () => {
				var diffResult = {
					modelName: "TestModel",
					tableName: "test_models",
					addColumns: [],
					removeColumns: [{name: "legacy_field", type: "string"}],
					changeColumns: [],
					renameColumns: []
				};
				var cfc = variables.autoMigrator.generateMigrationCFC(diffResult, "restore_typed");
				expect(cfc).toInclude('removeColumn(table="test_models", columnName="legacy_field")');
				expect(cfc).toInclude('addColumn(table="test_models", columnType="string", columnName="legacy_field")');
			});

			it("keeps the TODO when type is unknown", () => {
				var diffResult = {
					modelName: "TestModel",
					tableName: "test_models",
					addColumns: [],
					removeColumns: [{name: "legacy_field"}],
					changeColumns: [],
					renameColumns: []
				};
				var cfc = variables.autoMigrator.generateMigrationCFC(diffResult, "restore_unknown");
				expect(cfc).toInclude("TODO: restore column");
			});

		});

		describe("S12 changeColumns includes size scale and null", () => {

			it("emits limit and allowNull when the diff carries them", () => {
				var diffResult = {
					modelName: "TestModel",
					tableName: "test_models",
					addColumns: [],
					removeColumns: [],
					changeColumns: [
						{
							name: "title",
							from: {type: "string", size: 10, nullable: true},
							to: {type: "string", size: 50, nullable: false}
						}
					],
					renameColumns: []
				};
				var cfc = variables.autoMigrator.generateMigrationCFC(diffResult, "size_null");
				expect(cfc).toInclude("limit=50");
				expect(cfc).toInclude("allowNull=false");
			});

		});

		describe("S13 TenantMigrator credentials are request-scoped not hardcoded appKey", () => {

			afterEach(() => {
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "migratorDataSourceUserName");
					StructDelete(request.wheels, "migratorDataSourcePassword");
					StructDelete(request.wheels, "migratorDataSource");
					StructDelete(request.wheels, "tenant");
				}
				StructDelete(request, "hardenerTenantMigratorOverrideUser");
			});

			it("does not hardcode application.wheels for migrator $dbinfo credentials", () => {
				var src = FileRead(ExpandPath("/wheels/Migrator.cfc"));
				expect(Find("application.wheels.dataSourceUserName", src)).toBe(
					0,
					"Migrator $dbinfo must use $appKey() / $migratorDataSourceCredentials()."
				);
			});

			it("honors a request-scoped tenant username", () => {
				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				request.wheels.migratorDataSourceUserName = "tenant_probe_user";
				request.wheels.migratorDataSourcePassword = "tenant_probe_pass";
				var creds = variables.g.$migratorDataSourceCredentials();
				expect(creds.username).toBe("tenant_probe_user");
				expect(creds.password).toBe("tenant_probe_pass");
			});

			it("passes tenant userName onto the request during a tenant action", () => {
				var spy = CreateObject("component", "wheels.tests._assets.migrator.SpyTenantMigrator").init();
				spy.migrateAll(
					action = "info",
					tenants = [
						{
							id = "probe",
							dataSource = "wheels_hardener_tenant_ds_probe",
							userName = "tenant_ds_user"
						}
					],
					stopOnError = false,
					migratePath = "/wheels/tests/_assets/migrator/migrations/",
					sqlPath = "/wheels/tests/_assets/migrator/sql/"
				);
				expect(request.hardenerTenantMigratorOverrideUser).toBe("tenant_ds_user");
			});

		});

		describe("S14 bigInteger and char have types on PG and MSSQL", () => {

			it("maps biginteger and char on PostgreSQL", () => {
				var pg = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator");
				expect(pg.typeToSQL(type = "biginteger")).toBe("BIGINT");
				expect(pg.typeToSQL(type = "char")).toInclude("CHAR");
			});

			it("maps biginteger on Microsoft SQL Server", () => {
				var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerMigrator");
				expect(mssql.typeToSQL(type = "biginteger")).toBe("BIGINT");
			});

		});

		describe("S15 references default PK stays id (escalated public API)", () => {

			it("still defaults referenceColumn to id", () => {
				var prior = application.wheels.useUnderscoreReferenceColumns ?: false;
				application.wheels.useUnderscoreReferenceColumns = false;
				try {
					var t = variables.migration.createTable(name = "dbm_hardener_s15", force = true);
					t.references(columnNames = "user");
					expect(t.foreignKeys[1].referenceColumn).toBe("id");
				} finally {
					application.wheels.useUnderscoreReferenceColumns = prior;
				}
			});

			it("accepts an opt-in referenceColumn", () => {
				var prior = application.wheels.useUnderscoreReferenceColumns ?: false;
				application.wheels.useUnderscoreReferenceColumns = false;
				try {
					var t = variables.migration.createTable(name = "dbm_hardener_s15_opt", force = true);
					t.references(columnNames = "user", referenceColumn = "uuid");
					expect(t.foreignKeys[1].referenceColumn).toBe("uuid");
				} finally {
					application.wheels.useUnderscoreReferenceColumns = prior;
				}
			});

		});

		describe("S16 composite PK columnNames literal stays (escalated public API)", () => {

			it("still treats columnNames as a literal single PK name", () => {
				var t = variables.migration.createTable(name = "dbm_hardener_s16", id = false, force = true);
				t.primaryKey(columnNames = "a,b");
				expect(ArrayLen(t.primaryKeys)).toBe(1);
				expect(t.primaryKeys[1].name).toBe("a,b");
			});

			it("emits a composite PRIMARY KEY via multiple primaryKey() calls", () => {
				var t = variables.migration.createTable(name = "dbm_hardener_s16_comp", id = false, force = true);
				t.primaryKey(columnNames = "firstId");
				t.primaryKey(columnNames = "secondId");
				var sql = variables.migration.adapter.createTable(
					name = "dbm_hardener_s16_comp",
					columns = t.columns,
					primaryKeys = t.primaryKeys,
					foreignKeys = []
				);
				expect(sql).toInclude("PRIMARY KEY");
				expect(sql).toInclude("firstId");
				expect(sql).toInclude("secondId");
			});

		});

		describe("S17 timestamp() default stays datetime (escalated public API)", () => {

			it("defaults columnType to datetime", () => {
				var t = variables.migration.createTable(name = "dbm_hardener_s17", force = true);
				t.timestamp(columnNames = "publishedAt");
				expect(t.columns[1].type).toBe("datetime");
			});

			it("still allows columnType=timestamp as an opt-in", () => {
				var t = variables.migration.createTable(name = "dbm_hardener_s17_opt", force = true);
				t.timestamp(columnNames = "publishedAt", columnType = "timestamp");
				expect(t.columns[1].type).toBe("timestamp");
			});

		});

		describe("S18 CREATE FK quotes identifiers", () => {

			it("quotes the constraint name and referenced table in toForeignKeySQL", () => {
				var fk = CreateObject("component", "wheels.migrator.ForeignKeyDefinition").init(
					adapter = variables.migration.adapter,
					table = "posts",
					referenceTable = "users",
					column = "userid",
					referenceColumn = "id"
				);
				var sql = fk.toForeignKeySQL();
				var quotedName = variables.migration.adapter.quoteTableName(fk.name);
				var quotedRef = variables.migration.adapter.quoteTableName("users");
				expect(sql).toInclude(quotedName);
				expect(sql).toInclude(quotedRef);
			});

		});

		describe("S19 changeColumnInTable always emits a type change", () => {

			it("PostgreSQL emits TYPE even when only limit is set", () => {
				var pg = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator");
				var col = CreateObject("component", "wheels.migrator.ColumnDefinition").init(
					adapter = pg,
					name = "title",
					type = "string",
					limit = 50
				);
				var sql = pg.changeColumnInTable(name = "posts", column = col);
				expect(sql).toInclude("TYPE");
				expect(sql).toInclude("VARCHAR");
			});

			it("MSSQL emits ALTER COLUMN even when only limit is set", () => {
				var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerMigrator");
				var col = CreateObject("component", "wheels.migrator.ColumnDefinition").init(
					adapter = mssql,
					name = "title",
					type = "string",
					limit = 50
				);
				var sql = mssql.changeColumnInTable(name = "posts", column = col);
				expect(sql).toInclude("ALTER COLUMN");
				expect(sql).toInclude("VARCHAR");
			});

		});

		describe("S20 float() public defaults stay empty / true (escalated)", () => {

			it("keeps default empty string and allowNull true", () => {
				var t = variables.migration.createTable(name = "dbm_hardener_s20", force = true);
				t.float(columnNames = "ratio");
				expect(t.columns[1]["default"]).toBe("");
				expect(t.columns[1].allowNull).toBeTrue();
			});

			it("does not change the declared parameter defaults in source", () => {
				var src = FileRead(ExpandPath("/wheels/migrator/TableDefinition.cfc"));
				expect(src).toInclude('function float(string columnNames, default = "", boolean allowNull = "true")');
			});

		});

	}

}
