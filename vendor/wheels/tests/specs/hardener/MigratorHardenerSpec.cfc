/**
 * Hardener BLOCKERs B1–B6 (migrator / schema).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 */
component extends="wheels.WheelsTest" {

	include "../migrator/helperFunctions.cfm";

	function beforeAll() {
		variables.g = application.wo;
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.announceMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/announceonly/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_announce/"
		);
		variables.stubMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/defaultstubs/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_stubs/"
		);
		variables.wrapperMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations_2789/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_2789/"
		);
		variables.sqlMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
		variables.autoMigrator = CreateObject("component", "wheels.migrator.AutoMigrator");
		variables.fkAdapter = variables.migration.adapter;
	}

	function run() {

		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		describe("B1 announce-only migrations do not update the version table", () => {

			beforeEach(() => {
				deleteMigratorVersions(2);
				StructDelete(request, "$wheelsDebugSQL");
				StructDelete(request, "$wheelsMigrationDidExecute");
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				StructDelete(request, "$wheelsDebugSQL");
				StructDelete(request, "$wheelsMigrationDidExecute");
			});

			it("does not mark an announce-only up() as migrated", () => {
				if (_isCockroachDB) return;
				variables.announceMigrator.migrateTo("90000000000001");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000001'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(
					0,
					"Announce-only up() must not INSERT into the migrator versions table."
				);
			});

			it("does not mark the default announce-only Migration.up() stub as migrated", () => {
				if (_isCockroachDB) return;
				variables.stubMigrator.migrateTo("90000000000002");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000002'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(
					0,
					"Default up() that only announces NOT IMPLEMENTED must not mark the version migrated."
				);
			});

			it("does not remove a tracking row when down() is announce-only", () => {
				if (_isCockroachDB) return;
				var priorDown = application.wheels.allowMigrationDown;
				application.wheels.allowMigrationDown = true;
				try {
					// Ensure the tracking table exists without relying on up()
					// to write the row (that write is the bug under test).
					variables.announceMigrator.migrateTo("90000000000001");
					queryExecute(
						"DELETE FROM #application.wheels.migratorTableName# WHERE version = '90000000000001'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					queryExecute(
						"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('90000000000001', #application.wheels.migrationLevel#)",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					variables.announceMigrator.migrateTo("0");
					var rows = queryExecute(
						"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000001'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					expect(rows.recordCount).toBe(
						1,
						"Announce-only down() must not DELETE the migrator versions row."
					);
				} finally {
					application.wheels.allowMigrationDown = priorDown;
				}
			});

			it("still records a version when up() actually executes SQL", () => {
				if (_isCockroachDB) return;
				try {
					variables.migration.dropTable("c_o_r_e_bunyips");
				} catch (any e) {}
				variables.sqlMigrator.migrateTo("001");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '001'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				try {
					variables.migration.dropTable("c_o_r_e_bunyips");
				} catch (any e) {}
				expect(rows.recordCount).toBe(
					1,
					"A migration that executes SQL must still be recorded as migrated."
				);
			});

		});

		describe("B2 redo fails closed when allowMigrationDown is false", () => {

			beforeEach(() => {
				deleteMigratorVersions(2);
				try {
					queryExecute(
						"DELETE FROM c_o_r_e_tags WHERE name = 'issue2789_via_model_create'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
				} catch (any e) {}
				StructDelete(request, "$issue2789FlagDuringUp");
				StructDelete(request, "$wheelsTransactionWrapper");
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				try {
					queryExecute(
						"DELETE FROM c_o_r_e_tags WHERE name = 'issue2789_via_model_create'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
				} catch (any e) {}
				StructDelete(request, "$issue2789FlagDuringUp");
				StructDelete(request, "$wheelsTransactionWrapper");
			});

			it("does not re-run up() when down is blocked by the default allowMigrationDown=false", () => {
				if (_isCockroachDB) return;
				var priorDown = application.wheels.allowMigrationDown;
				application.wheels.allowMigrationDown = true;
				try {
					variables.wrapperMigrator.migrateTo("001");
				} finally {
					application.wheels.allowMigrationDown = priorDown;
				}
				var before = queryExecute(
					"SELECT id FROM c_o_r_e_tags WHERE name = 'issue2789_via_model_create'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(before.recordCount).toBeGT(0);

				application.wheels.allowMigrationDown = false;
				try {
					var output = variables.wrapperMigrator.redoMigration("001");
					var after = queryExecute(
						"SELECT id FROM c_o_r_e_tags WHERE name = 'issue2789_via_model_create'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					expect(after.recordCount).toBe(
						before.recordCount,
						"redo must not re-run up() when down is blocked — that double-applies."
					);
					expect(output).toInclude("allowMigrationDown");
					var versions = queryExecute(
						"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '001'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					expect(versions.recordCount).toBe(
						1,
						"Fail-closed redo must leave the version tracking row in place."
					);
				} finally {
					application.wheels.allowMigrationDown = priorDown;
				}
			});

			it("does not flip the allowMigrationDown framework default", () => {
				var src = FileRead(ExpandPath("/wheels/events/onapplicationstart.cfc"));
				expect(src).toInclude("application.$wheels.allowMigrationDown = false");
			});

		});

		describe("B3 CREATE FK path preserves onUpdate and onDelete", () => {

			it("includes ON UPDATE / ON DELETE in toForeignKeySQL() used by CREATE TABLE", () => {
				var fk = CreateObject("component", "wheels.migrator.ForeignKeyDefinition").init(
					adapter = variables.fkAdapter,
					table = "posts",
					referenceTable = "users",
					column = "userid",
					referenceColumn = "id",
					onUpdate = "cascade",
					onDelete = "null"
				);
				var sql = fk.toForeignKeySQL();
				expect(sql).toInclude("ON UPDATE CASCADE");
				expect(sql).toInclude("ON DELETE SET NULL");
			});

			it("includes ON UPDATE / ON DELETE in adapter.createTable() SQL", () => {
				var fk = CreateObject("component", "wheels.migrator.ForeignKeyDefinition").init(
					adapter = variables.fkAdapter,
					table = "posts",
					referenceTable = "users",
					column = "authorid",
					referenceColumn = "id",
					onUpdate = "none",
					onDelete = "cascade"
				);
				var sql = variables.fkAdapter.createTable(
					name = "posts",
					columns = [],
					primaryKeys = [],
					foreignKeys = [fk]
				);
				expect(sql).toInclude("ON UPDATE NO ACTION");
				expect(sql).toInclude("ON DELETE CASCADE");
			});

		});

		describe("B4 default FK name includes the column so two FKs to the same table do not collide", () => {

			it("names two FKs to the same reference table differently", () => {
				var authorFk = CreateObject("component", "wheels.migrator.ForeignKeyDefinition").init(
					adapter = variables.fkAdapter,
					table = "posts",
					referenceTable = "users",
					column = "authorid",
					referenceColumn = "id"
				);
				var editorFk = CreateObject("component", "wheels.migrator.ForeignKeyDefinition").init(
					adapter = variables.fkAdapter,
					table = "posts",
					referenceTable = "users",
					column = "editorid",
					referenceColumn = "id"
				);
				expect(authorFk.name).notToBe(
					editorFk.name,
					"Default FK name must include the column (or otherwise be unique per column)."
				);
				expect(authorFk.name).toInclude("authorid");
				expect(editorFk.name).toInclude("editorid");
			});

			it("still includes table and reference table in the default name", () => {
				var fk = CreateObject("component", "wheels.migrator.ForeignKeyDefinition").init(
					adapter = variables.fkAdapter,
					table = "posts",
					referenceTable = "users",
					column = "userid",
					referenceColumn = "id"
				);
				expect(fk.name).toInclude("posts");
				expect(fk.name).toInclude("users");
				expect(fk.name).toInclude("userid");
			});

		});

		describe("B5 TenantMigrator does not mutate shared application.wheels.dataSourceName", () => {

			afterEach(() => {
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "tenant");
					StructDelete(request.wheels, "migratorDataSource");
				}
				StructDelete(request, "hardenerTenantMigratorAppDs");
				StructDelete(request, "hardenerTenantMigratorOverrideDs");
			});

			it("leaves application.wheels.dataSourceName unchanged while a tenant action runs", () => {
				var original = application.wheels.dataSourceName;
				var spy = CreateObject("component", "wheels.tests._assets.migrator.SpyTenantMigrator").init();
				spy.migrateAll(
					action = "info",
					tenants = [{id = "probe", dataSource = "wheels_hardener_tenant_ds_probe"}],
					stopOnError = false,
					migratePath = "/wheels/tests/_assets/migrator/migrations/",
					sqlPath = "/wheels/tests/_assets/migrator/sql/"
				);
				expect(StructKeyExists(request, "hardenerTenantMigratorAppDs")).toBeTrue(
					"$executeAction must run so the spec can observe the datasource in the lock."
				);
				expect(request.hardenerTenantMigratorAppDs).toBe(
					original,
					"TenantMigrator must not swap application.wheels.dataSourceName — concurrent requests read that key without the tenant lock."
				);
				expect(application.wheels.dataSourceName).toBe(original);
			});

			it("isolates the tenant datasource on the request instead of application scope", () => {
				var original = application.wheels.dataSourceName;
				var spy = CreateObject("component", "wheels.tests._assets.migrator.SpyTenantMigrator").init();
				spy.migrateAll(
					action = "info",
					tenants = [{id = "probe", dataSource = "wheels_hardener_tenant_ds_probe"}],
					stopOnError = false,
					migratePath = "/wheels/tests/_assets/migrator/migrations/",
					sqlPath = "/wheels/tests/_assets/migrator/sql/"
				);
				expect(request.hardenerTenantMigratorOverrideDs).toBe("wheels_hardener_tenant_ds_probe");
				expect(application.wheels.dataSourceName).toBe(original);
			});

		});

		describe("B6 AutoMigrator honors suggestedRenames instead of remove+add", () => {

			it("emits renameColumn for suggestedRenames and does not emit destructive remove+add for those columns", () => {
				var diffResult = {
					modelName: "TestModel",
					tableName: "test_models",
					addColumns: [{name: "emailAddress", type: "string", nullable: true, "default": ""}],
					removeColumns: [{name: "email_addr"}],
					changeColumns: [],
					renameColumns: [],
					suggestedRenames: [
						{
							from: "email_addr",
							to: "emailAddress",
							type: "string",
							confidence: 0.82,
							ambiguous: false
						}
					]
				};
				var cfc = variables.autoMigrator.generateMigrationCFC(diffResult, "honor_suggested");
				expect(cfc).toInclude('renameColumn(table="test_models", columnName="email_addr", newColumnName="emailAddress")');
				expect(Find('removeColumn(table="test_models", columnName="email_addr"', cfc)).toBe(
					0,
					"suggestedRenames must not be emitted as removeColumn."
				);
				expect(Find('addColumn(table="test_models"', cfc)).toBe(
					0,
					"suggestedRenames must not be emitted as addColumn."
				);
			});

			it("does not drop a suggested-rename source column even when it is also listed in removeColumns", () => {
				var diffResult = {
					modelName: "TestModel",
					tableName: "test_models",
					addColumns: [{name: "fullName", type: "string", nullable: true, "default": ""}],
					removeColumns: [{name: "full_name"}, {name: "legacy_unused"}],
					changeColumns: [],
					renameColumns: [],
					suggestedRenames: [
						{
							from: "full_name",
							to: "fullName",
							type: "string",
							confidence: 0.9,
							ambiguous: false
						}
					]
				};
				var cfc = variables.autoMigrator.generateMigrationCFC(diffResult, "honor_suggested_mixed");
				expect(cfc).toInclude('renameColumn(table="test_models", columnName="full_name", newColumnName="fullName")');
				expect(Find('removeColumn(table="test_models", columnName="full_name"', cfc)).toBe(0);
				expect(cfc).toInclude('removeColumn(table="test_models", columnName="legacy_unused")');
			});

		});

	}

}
