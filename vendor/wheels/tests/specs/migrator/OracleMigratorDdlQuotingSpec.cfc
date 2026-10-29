/**
 * Phase 3 of #4629 item 3: the Oracle migrator quotes every generated-DDL identifier
 * uppercase (matching the Oracle model adapter), so reserved words are usable and
 * legacy unquoted schemas still resolve. Live tests are Oracle-only; the quote units
 * live in AdapterSqlGenerationSpec.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Oracle migrator DDL quoting (##4629)", () => {

			beforeEach(() => {
				migration = CreateObject("component", "wheels.migrator.Migration").init();
				if (!FindNoCase("Oracle", migration.adapter.adapterName())) {
					skip("Oracle DDL quoting");
				}
				variables.savedObjectCase = application.wheels.migratorObjectCase;
			});

			afterEach(() => {
				application.wheels.migratorObjectCase = variables.savedObjectCase;
			});

			it("reports the upper DDL identifier case", () => {
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

			it("resolves an existing unquoted schema through the quoted upper-case names", () => {
				QueryExecute(
					"CREATE TABLE dbm_ora_legacy (id NUMBER, legacycol NUMBER)",
					[],
					{datasource = application.wheels.dataSourceName}
				);
				try {
					migration.addColumn(table = "dbm_ora_legacy", columnType = "integer", columnName = "newcol");
					var columns = QueryExecute(
						"SELECT COUNT(*) AS c FROM user_tab_columns WHERE table_name = 'DBM_ORA_LEGACY' AND column_name = 'NEWCOL'",
						[],
						{datasource = application.wheels.dataSourceName}
					);
					expect(columns.c[1]).toBe(1);

					migration.renameTable(oldName = "dbm_ora_legacy", newName = "dbm_ora_legacy_ren");
					var tables = QueryExecute(
						"SELECT COUNT(*) AS c FROM user_tables WHERE table_name = 'DBM_ORA_LEGACY_REN'",
						[],
						{datasource = application.wheels.dataSourceName}
					);
					expect(tables.c[1]).toBe(1);
				} finally {
					try {
						migration.dropTable("dbm_ora_legacy_ren");
					} catch (any e) {
					}
					try {
						migration.dropTable("dbm_ora_legacy");
					} catch (any e) {
					}
				}
				var after = QueryExecute(
					"SELECT COUNT(*) AS c FROM user_tables WHERE table_name IN ('DBM_ORA_LEGACY', 'DBM_ORA_LEGACY_REN')",
					[],
					{datasource = application.wheels.dataSourceName}
				);
				expect(after.c[1]).toBe(0);
			});

			it("keeps up/down symmetric for a migration-created table and column", () => {
				var name = "dbm_ora_cycle";
				var t = migration.createTable(name = name, force = true);
				t.string(columnNames = "label");
				t.create();

				var created = QueryExecute(
					"SELECT COUNT(*) AS c FROM user_tables WHERE table_name = 'DBM_ORA_CYCLE'",
					[],
					{datasource = application.wheels.dataSourceName}
				);
				expect(created.c[1]).toBe(1);

				migration.addColumn(table = name, columnType = "integer", columnName = "extra");
				migration.removeColumn(table = name, columnName = "extra");
				var columns = QueryExecute(
					"SELECT COUNT(*) AS c FROM user_tab_columns WHERE table_name = 'DBM_ORA_CYCLE' AND column_name = 'EXTRA'",
					[],
					{datasource = application.wheels.dataSourceName}
				);
				expect(columns.c[1]).toBe(0);

				migration.dropTable(name);
				var dropped = QueryExecute(
					"SELECT COUNT(*) AS c FROM user_tables WHERE table_name = 'DBM_ORA_CYCLE'",
					[],
					{datasource = application.wheels.dataSourceName}
				);
				expect(dropped.c[1]).toBe(0);
			});

			it("ignores migratorObjectCase while quoting is active", () => {
				try {
					application.wheels.migratorObjectCase = "lower";
					var t = migration.createTable(name = "dbm_ora_case_l", force = true);
					t.string(columnNames = "camelCase");
					t.create();

					application.wheels.migratorObjectCase = "upper";
					var t2 = migration.createTable(name = "dbm_ora_case_u", force = true);
					t2.string(columnNames = "camelCase");
					t2.create();

					// Column identifiers are quoted uppercase regardless of the setting.
					QueryExecute(
						'SELECT "CAMELCASE" FROM "DBM_ORA_CASE_L"',
						[],
						{datasource = application.wheels.dataSourceName}
					);
					QueryExecute(
						'SELECT "CAMELCASE" FROM "DBM_ORA_CASE_U"',
						[],
						{datasource = application.wheels.dataSourceName}
					);
				} finally {
					try {
						migration.dropTable("dbm_ora_case_l");
					} catch (any e) {
					}
					try {
						migration.dropTable("dbm_ora_case_u");
					} catch (any e) {
					}
				}
			});

			it("creates and drops an index on a quoted uppercase table", () => {
				var name = "dbm_ora_idx_tbl";
				var t = migration.createTable(name = name, force = true);
				t.string(columnNames = "label");
				t.create();
				try {
					migration.addIndex(table = name, columnNames = "label", indexName = "dbm_ora_idx");
					var created = QueryExecute(
						"SELECT COUNT(*) AS c FROM user_indexes WHERE index_name = 'DBM_ORA_IDX'",
						[],
						{datasource = application.wheels.dataSourceName}
					);
					expect(created.c[1]).toBe(1);

					migration.removeIndex(table = name, indexName = "dbm_ora_idx");
					var dropped = QueryExecute(
						"SELECT COUNT(*) AS c FROM user_indexes WHERE index_name = 'DBM_ORA_IDX'",
						[],
						{datasource = application.wheels.dataSourceName}
					);
					expect(dropped.c[1]).toBe(0);
				} finally {
					try {
						migration.dropTable(name);
					} catch (any e) {
					}
				}
			});

		});

	}

}
