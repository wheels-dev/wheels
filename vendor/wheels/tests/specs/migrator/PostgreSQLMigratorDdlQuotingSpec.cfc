/**
 * Phase 2 of #4629 item 3: the PostgreSQL and CockroachDB migrators quote every
 * generated-DDL identifier lowercase (matching their model adapters), so reserved
 * words are usable and legacy unquoted schemas still resolve. Live tests are
 * PG/Cockroach-only; the fold-case units live in AdapterSqlGenerationSpec.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("PostgreSQL/CockroachDB migrator DDL quoting (##4629)", () => {

			beforeEach(() => {
				migration = CreateObject("component", "wheels.migrator.Migration").init();
				var adapterName = migration.adapter.adapterName();
				if (!FindNoCase("PostgreSQL", adapterName) && !FindNoCase("Cockroach", adapterName)) {
					skip("PostgreSQL/CockroachDB DDL quoting");
				}
				variables.savedObjectCase = application.wheels.migratorObjectCase;
			});

			afterEach(() => {
				application.wheels.migratorObjectCase = variables.savedObjectCase;
			});

			it("reports the lower DDL identifier case", () => {
				expect(migration.adapter.$ddlIdentifierCase()).toBe("lower");
			});

			it("creates, reads and drops a reserved table and column (the original failure)", () => {
				try {
					var t = migration.createTable(name = "order", force = true);
					t.string(columnNames = "group");
					t.create();

					QueryExecute(
						'INSERT INTO "order" ("group") VALUES (''b'')',
						[],
						{datasource = application.wheels.dataSourceName}
					);
					var rows = QueryExecute(
						'SELECT "group" FROM "order"',
						[],
						{datasource = application.wheels.dataSourceName}
					);
					expect(rows.recordCount).toBe(1);
					expect(rows["group"][1]).toBe("b");
				} finally {
					try {
						migration.dropTable("order");
					} catch (any e) {
					}
				}
			});

			it("resolves an existing unquoted schema through the quoted lower-case names", () => {
				var name = "dbm_pg_ddlq_legacy";
				var renamed = "dbm_pg_ddlq_legacy_renamed";
				QueryExecute(
					"CREATE TABLE #name# (id INT, legacycol INT)",
					[],
					{datasource = application.wheels.dataSourceName}
				);
				try {
					migration.addColumn(table = name, columnType = "integer", columnName = "newcol");
					var columns = g.$dbinfo(datasource = application.wheels.dataSourceName, table = name, type = "columns");
					expect(ListFindNoCase(ValueList(columns.column_name), "newcol")).toBeGT(0);

					migration.renameTable(oldName = name, newName = renamed);
					var tables = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
					expect(ListFindNoCase(ValueList(tables.table_name), renamed)).toBeGT(0);
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

			it("keeps up/down symmetric for a migration-created table and column", () => {
				var name = "dbm_pg_ddlq_cycle";
				var t = migration.createTable(name = name, force = true);
				t.string(columnNames = "label");
				t.create();

				var created = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				expect(ListFindNoCase(ValueList(created.table_name), name)).toBeGT(0);

				migration.addColumn(table = name, columnType = "integer", columnName = "extra");
				var columns = g.$dbinfo(datasource = application.wheels.dataSourceName, table = name, type = "columns");
				expect(ListFindNoCase(ValueList(columns.column_name), "extra")).toBeGT(0);

				migration.removeColumn(table = name, columnName = "extra");
				var afterDropColumn = g.$dbinfo(datasource = application.wheels.dataSourceName, table = name, type = "columns");
				expect(ListFindNoCase(ValueList(afterDropColumn.column_name), "extra")).toBe(0);

				migration.dropTable(name);
				var dropped = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				expect(ListFindNoCase(ValueList(dropped.table_name), name)).toBe(0);
			});

			it("ignores migratorObjectCase while quoting is active", () => {
				var lowered = "dbm_pg_ddlq_case_lower";
				var uppered = "dbm_pg_ddlq_case_upper";
				try {
					application.wheels.migratorObjectCase = "lower";
					var t = migration.createTable(name = lowered, force = true);
					t.string(columnNames = "camelCase");
					t.create();

					application.wheels.migratorObjectCase = "upper";
					var t2 = migration.createTable(name = uppered, force = true);
					t2.string(columnNames = "camelCase");
					t2.create();

					// Names are quoted lowercase regardless of the setting.
					QueryExecute(
						'SELECT "camelcase" FROM "dbm_pg_ddlq_case_lower"',
						[],
						{datasource = application.wheels.dataSourceName}
					);
					QueryExecute(
						'SELECT "camelcase" FROM "dbm_pg_ddlq_case_upper"',
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
