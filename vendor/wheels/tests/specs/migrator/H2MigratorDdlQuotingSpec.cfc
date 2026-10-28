/**
 * Phase 1 of #4629 item 3: the H2 migrator quotes every generated-DDL identifier in
 * the datasource's own fold case, so reserved-word tables/columns can be created and
 * legacy unquoted schemas still resolve. Live tests are H2-only; the fold-case units
 * live in AdapterSqlGenerationSpec via H2MigratorCaseProbe.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("H2 migrator DDL quoting (##4629)", () => {

			beforeEach(() => {
				migration = CreateObject("component", "wheels.migrator.Migration").init();
				if (!FindNoCase("H2", migration.adapter.adapterName())) {
					skip("H2 DDL quoting");
				}
				variables.savedObjectCase = application.wheels.migratorObjectCase;
			});

			afterEach(() => {
				application.wheels.migratorObjectCase = variables.savedObjectCase;
			});

			it("probes the datasource fold case through the model adapter", () => {
				// The suite's H2 datasource uses the default upper folding.
				expect(migration.adapter.$ddlIdentifierCase()).toBe("upper");
			});

			it("creates, reads and drops a reserved table and column (the original failure)", () => {
				try {
					var t = migration.createTable(name = "order", force = true);
					t.string(columnNames = "group");
					t.create();

					QueryExecute(
						'INSERT INTO "ORDER" ("GROUP") VALUES (''b'')',
						[],
						{datasource = application.wheels.dataSourceName}
					);
					var rows = QueryExecute(
						'SELECT "GROUP" FROM "ORDER"',
						[],
						{datasource = application.wheels.dataSourceName}
					);
					expect(rows.recordCount).toBe(1);
					expect(rows["GROUP"][1]).toBe("b");
				} finally {
					try {
						migration.dropTable("order");
					} catch (any e) {
					}
				}
			});

			it("resolves an existing unquoted schema through the quoted fold-case names", () => {
				var name = "dbm_h2_ddlq_legacy";
				var renamed = "dbm_h2_ddlq_legacy_renamed";
				QueryExecute(
					"CREATE TABLE #name# (id INT, legacycol INT)",
					[],
					{datasource = application.wheels.dataSourceName}
				);
				try {
					migration.addColumn(table = name, columnType = "integer", columnName = "newcol");
					migration.renameTable(oldName = name, newName = renamed);

					var info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
					expect(ListFindNoCase(ValueList(info.table_name), renamed)).toBeGT(0);
				} finally {
					try {
						migration.dropTable(renamed);
					} catch (any e) {
					}
					try {
						migration.dropTable(name);
					} catch (any e) {
					}
				}
				var after = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				expect(ListFindNoCase(ValueList(after.table_name), renamed)).toBe(0);
			});

			it("keeps up/down symmetric for a migration-created table", () => {
				var name = "dbm_h2_ddlq_cycle";
				var t = migration.createTable(name = name, force = true);
				t.string(columnNames = "label");
				t.create();

				var created = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				expect(ListFindNoCase(ValueList(created.table_name), name)).toBeGT(0);

				migration.dropTable(name);

				var dropped = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				expect(ListFindNoCase(ValueList(dropped.table_name), name)).toBe(0);
			});

			it("ignores migratorObjectCase while quoting is active", () => {
				var lowered = "dbm_h2_ddlq_case_lower";
				var uppered = "dbm_h2_ddlq_case_upper";
				try {
					application.wheels.migratorObjectCase = "lower";
					var t = migration.createTable(name = lowered, force = true);
					t.string(columnNames = "camelCase");
					t.create();

					application.wheels.migratorObjectCase = "upper";
					var t2 = migration.createTable(name = uppered, force = true);
					t2.string(columnNames = "camelCase");
					t2.create();

					// Column identifiers are quoted in the H2 fold case regardless of the setting.
					QueryExecute(
						'SELECT "CAMELCASE" FROM "DBM_H2_DDLQ_CASE_LOWER"',
						[],
						{datasource = application.wheels.dataSourceName}
					);
					QueryExecute(
						'SELECT "CAMELCASE" FROM "DBM_H2_DDLQ_CASE_UPPER"',
						[],
						{datasource = application.wheels.dataSourceName}
					);
				} finally {
					try {
						migration.dropTable(lowered);
					} catch (any e) {
					}
					try {
						migration.dropTable(uppered);
					} catch (any e) {
					}
				}
			});

		});

	}

}
