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
		variables.ormMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/announceorm/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_announceorm/"
		);
		variables.rawMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/announceraw/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_announceraw/"
		);
		variables.rawOtherMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/announceraw_other/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_announceraw_other/"
		);
		variables.noTxOtherMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/notransaction_other/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_notransaction_other/"
		);
		variables.noTxFailMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/notransaction_fail/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_notransaction_fail/"
		);
		variables.rawSuperMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/announceraw_super/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_announceraw_super/"
		);
		variables.rawBaseMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/announceraw_base/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_hardener_announceraw_base/"
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

		// #3402 B1 originally skipped version tracking for any step that
		// announced without $execute or ORM work. That also skipped steps
		// whose work was raw queryExecute() (for example DDL on a second
		// datasource), which then re-ran on every migrate. Only the inherited
		// NOT IMPLEMENTED placeholder is untracked now; every migration whose
		// own up()/down() completes is tracked, as in 4.0.x.
		describe("B1 only the inherited placeholder migration skips version tracking", () => {

			beforeEach(() => {
				deleteMigratorVersions(2);
				StructDelete(request, "$wheelsDebugSQL");
				StructDelete(request, "$wheelsMigrationDidExecute");
				StructDelete(request, "$wheelsMigrationDidAnnounce");
				StructDelete(request, "$wheelsMigrationDidWork");
				try {
					queryExecute(
						"DELETE FROM c_o_r_e_tags WHERE name = 'hardener_b1_announce_then_orm'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
				} catch (any e) {}
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				StructDelete(request, "$wheelsDebugSQL");
				StructDelete(request, "$wheelsMigrationDidExecute");
				StructDelete(request, "$wheelsMigrationDidAnnounce");
				StructDelete(request, "$wheelsMigrationDidWork");
				try {
					queryExecute(
						"DELETE FROM c_o_r_e_tags WHERE name = 'hardener_b1_announce_then_orm'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
				} catch (any e) {}
			});

			it("records a migration's own up() that only announces", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				variables.announceMigrator.migrateTo("90000000000001");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000001'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(
					1,
					"A migration's own up() that completes must INSERT its version, even when it only announces."
				);
			});

			it("does not mark the default announce-only Migration.up() stub as migrated", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
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

			it("says why the placeholder's version was not recorded", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var output = variables.stubMigrator.migrateTo("90000000000002");
				expect(output).toInclude("NOT IMPLEMENTED placeholder, so its version was not recorded");
			});

			it("keeps the tracking row when down() is the inherited placeholder", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var priorDown = application.wheels.allowMigrationDown;
				application.wheels.allowMigrationDown = true;
				try {
					variables.stubMigrator.migrateTo("90000000000002");
					queryExecute(
						"DELETE FROM #application.wheels.migratorTableName# WHERE version = '90000000000002'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					queryExecute(
						"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('90000000000002', #application.wheels.migrationLevel#)",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					variables.stubMigrator.migrateTo("0");
					var rows = queryExecute(
						"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000002'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					expect(rows.recordCount).toBe(
						1,
						"The inherited NOT IMPLEMENTED down() must not DELETE the migrator versions row."
					);
				} finally {
					application.wheels.allowMigrationDown = priorDown;
				}
			});

			it("records a version when up() runs raw queryExecute() and then announces", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				variables.rawMigrator.migrateTo("90000000000004");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000004'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(
					1,
					"Raw queryExecute() is invisible to the migrator; announce() after it must not leave the version unrecorded."
				);
			});

			it("records a migration's own up() that runs raw SQL and then calls super.up()", () => {
				// Placeholder detection is by declaration: this migration declares
				// up(), so it is user code even though it ends in the placeholder.
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				variables.rawSuperMigrator.migrateTo("90000000000006");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000006'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(
					1,
					"An own up() that calls super.up() must still INSERT the migrator versions row."
				);
			});

			it("records a migration that inherits up() from an app base class", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				variables.rawBaseMigrator.migrateTo("90000000000007");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000007'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(
					1,
					"up() declared by an app base class is user code and must INSERT the migrator versions row."
				);
			});

			it("records a version when up() runs raw SQL on a second datasource and then announces", () => {
				// The multi-database app shape: DDL through queryExecute() against
				// another datasource, then announce().
				var otherDs = "wheelstestdb_sqlite_tenant_b";
				var state = {available = true};
				try {
					queryExecute("SELECT 1 AS x", {}, {datasource: otherDs});
				} catch (any e) {
					state.available = false;
				}
				if (!state.available) {
					skip("The second SQLite datasource #otherDs# is not configured on this run.");
					return;
				}
				// Two engines cannot run a second datasource inside the migrator's
				// per-step transaction, so the step fails before tracking is decided:
				//   Adobe ColdFusion refuses it ("Datasource names for all the
				//   database tags within the cftransaction tag must be the same");
				//   RustCFML sends every statement in a transaction to the first
				//   datasource it used, so the version INSERT lands in the second
				//   database ("no such table: wheels_migrator_versions").
				// Such a migration sets this.useTransaction = false (#3772); see the
				// opt-out specs below.
				var adapter = application.wheels.engineAdapter;
				if (adapter.isRustCFML()) {
					skip("RustCFML routes every statement in a transaction to the first datasource it used.");
					return;
				}
				var output = variables.rawOtherMigrator.migrateTo("90000000000005");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000005'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				if (adapter.isAdobe()) {
					// Adobe refuses the mix. The failure has to say how to fix it, and the
					// step must not be recorded.
					expect(output).toInclude("this.useTransaction = false");
					expect(rows.recordCount).toBe(0, "A refused step must not be recorded. Migration output: " & output);
					return;
				}
				expect(rows.recordCount).toBe(
					1,
					"announce() after raw SQL on a second datasource must still INSERT the migrator versions row. Migration output: " & output
				);
			});

			it("records an opted-out step (this.useTransaction = false) that uses a second datasource, on every engine", () => {
				var otherDs = "wheelstestdb_sqlite_tenant_b";
				var state = {available = true};
				try {
					queryExecute("SELECT 1 AS x", {}, {datasource: otherDs});
				} catch (any e) {
					state.available = false;
				}
				if (!state.available) {
					skip("The second SQLite datasource #otherDs# is not configured on this run.");
					return;
				}
				var output = variables.noTxOtherMigrator.migrateTo("90000000000011");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000011'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(output).notToInclude("Error migrating");
				expect(rows.recordCount).toBe(
					1,
					"A step run without a transaction must be recorded after it succeeds. Migration output: " & output
				);
			});

			it("records nothing when an opted-out step fails", () => {
				var output = variables.noTxFailMigrator.migrateTo("90000000000012");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000012'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(output).toInclude("Error migrating to 90000000000012");
				expect(output).toInclude("deliberate failure after the step started");
				// Nothing rolled back: the report says so instead of implying it did.
				expect(output).toInclude("without a transaction");
				expect(rows.recordCount).toBe(0, "A failed step must leave no version row. Migration output: " & output);
			});

			it("names the opt-out when the engine rejects a second datasource inside the transaction", () => {
				var migrator = variables.rawOtherMigrator;
				var hint = migrator.$mixedDatasourceTransactionHint({
					message = "Datasource wheelstestdb verification failed.",
					detail = "The root cause was that: java.sql.SQLException: Datasource names for all the database tags within the cftransaction tag must be the same."
				});
				expect(hint).toInclude("this.useTransaction = false");
				expect(migrator.$mixedDatasourceTransactionHint({message = "Table not found", detail = ""})).toBe("");
			});

			it("removes the tracking row when a migration's own down() only announces", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var priorDown = application.wheels.allowMigrationDown;
				application.wheels.allowMigrationDown = true;
				try {
					// Ensure the tracking table exists, then force the row present
					// so down() is actually invoked.
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
						0,
						"A migration's own down() that completes must DELETE its version, even when it only announces."
					);
				} finally {
					application.wheels.allowMigrationDown = priorDown;
				}
			});

			it("still marks a version migrated when up() announces then creates via ORM without $execute", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				variables.ormMigrator.migrateTo("90000000000003");
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000003'",
					{},
					{datasource: application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(
					1,
					"announce() then model().create() with no $execute must still INSERT the migrator versions row."
				);
			});

			it("still removes a tracking row when down() announces then deletes via ORM without $execute", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var priorDown = application.wheels.allowMigrationDown;
				application.wheels.allowMigrationDown = true;
				try {
					// Ensure the tracking table exists. up() may or may not
					// write the row (that write is the sibling hole); the
					// row is forced present so down() is actually invoked.
					variables.ormMigrator.migrateTo("90000000000003");
					queryExecute(
						"DELETE FROM #application.wheels.migratorTableName# WHERE version = '90000000000003'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					queryExecute(
						"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('90000000000003', #application.wheels.migrationLevel#)",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					var existing = queryExecute(
						"SELECT id FROM c_o_r_e_tags WHERE name = 'hardener_b1_announce_then_orm'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					if (existing.recordCount == 0) {
						model("Tag").create(name = "hardener_b1_announce_then_orm");
					}
					variables.ormMigrator.migrateTo("0");
					var rows = queryExecute(
						"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '90000000000003'",
						{},
						{datasource: application.wheels.dataSourceName}
					);
					expect(rows.recordCount).toBe(
						0,
						"announce() then model delete with no $execute must still DELETE the migrator versions row."
					);
				} finally {
					application.wheels.allowMigrationDown = priorDown;
				}
			});

			it("still records a version when up() actually executes SQL", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
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
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
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
