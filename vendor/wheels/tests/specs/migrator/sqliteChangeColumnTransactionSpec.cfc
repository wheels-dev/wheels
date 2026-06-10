/**
 * Regression coverage for db-adapters review finding DA7 — SQLite's
 * recreate-table pattern (`SQLiteMigrator.changeColumnInTable()`) emitted raw
 * `PRAGMA foreign_keys` / `BEGIN TRANSACTION` / `COMMIT` statements
 * unconditionally. When the migrator's cftransaction wraps `up()` (issue
 * ##2789 sets `request.$wheelsTransactionWrapper`), the literal BEGIN collides
 * with the engine transaction, PRAGMA foreign_keys is a silent no-op inside an
 * active transaction, and the raw COMMIT defeats the wrapper's rollback —
 * leaving the `_wheels_new_*` temp table behind on a mid-sequence failure.
 *
 * Inside the wrapper the adapter must instead emit
 * `PRAGMA defer_foreign_keys = ON` (allowed mid-transaction, auto-resets on
 * commit/rollback) and let the wrapper own atomicity. Standalone execution
 * keeps the original explicit transaction.
 */
component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo
		migration = CreateObject("component", "wheels.migrator.Migration").init()
		tableName = "dbm_sqlite_txn_aware"
		columnName = "stringcolumn"

		describe("SQLiteMigrator.changeColumnInTable() transaction awareness (DA7)", () => {

			beforeEach(() => {
				if (get("adapterName") neq 'SQLiteModel') {
					skip("SQLite-specific recreate-table behavior")
				}
				StructDelete(request, "$wheelsTransactionWrapper")
				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = columnName, limit = 10, allowNull = true)
				t.create()
			})

			afterEach(() => {
				StructDelete(request, "$wheelsTransactionWrapper")
				if (get("adapterName") eq 'SQLiteModel') {
					try {
						migration.dropTable(tableName)
					} catch (any e) {
					}
				}
			})

			it("omits raw BEGIN/COMMIT and foreign_keys toggles inside the migrator transaction wrapper", () => {
				request.$wheelsTransactionWrapper = true
				t = migration.changeTable(tableName)
				t.string(columnNames = columnName, limit = 50, allowNull = false, default = "foo")
				statements = migration.adapter.changeColumnInTable(name = tableName, column = t.columns[1])
				StructDelete(request, "$wheelsTransactionWrapper")

				joined = ArrayToList(statements, "||")
				expect(statements[1]).toBe("PRAGMA defer_foreign_keys = ON")
				expect(joined).notToInclude("BEGIN TRANSACTION")
				expect(joined).notToInclude("COMMIT")
				expect(joined).notToInclude("PRAGMA foreign_keys")
			})

			it("keeps its own explicit transaction and foreign_keys toggles when standalone", () => {
				t = migration.changeTable(tableName)
				t.string(columnNames = columnName, limit = 50, allowNull = false, default = "foo")
				statements = migration.adapter.changeColumnInTable(name = tableName, column = t.columns[1])

				joined = ArrayToList(statements, "||")
				expect(statements[1]).toBe("PRAGMA foreign_keys = OFF")
				expect(statements[2]).toBe("BEGIN TRANSACTION")
				expect(joined).toInclude("COMMIT")
				expect(statements[ArrayLen(statements)]).toBe("PRAGMA foreign_keys = ON")
				expect(joined).notToInclude("defer_foreign_keys")
			})

			it("changes a column successfully when run inside an engine-level transaction like the migrator's", () => {
				g.$query(
					datasource = application.wheels.dataSourceName,
					sql = "INSERT INTO #tableName# (#columnName#) VALUES ('keep')"
				)

				transaction {
					try {
						// Mirrors Migrator.cfc's BoxLang datasource-establishing query.
						if (StructKeyExists(server, "boxlang")) {
							g.$query(datasource = application.wheels.dataSourceName, sql = "SELECT 1 AS test")
						}
						request.$wheelsTransactionWrapper = true
						migration.changeColumn(
							table = tableName,
							columnName = columnName,
							columnType = 'string',
							limit = 50,
							allowNull = false,
							default = "foo"
						)
					} catch (any e) {
						StructDelete(request, "$wheelsTransactionWrapper")
						transaction action="rollback";
						rethrow;
					}
					StructDelete(request, "$wheelsTransactionWrapper")
					transaction action="commit";
				}

				pragma = g.$query(datasource = application.wheels.dataSourceName, sql = "PRAGMA table_info(#tableName#)")
				changedRow = 0
				for (i = 1; i <= pragma.recordCount; i++) {
					if (pragma.name[i] == columnName) {
						changedRow = i
						break
					}
				}
				rowCheck = g.$query(
					datasource = application.wheels.dataSourceName,
					sql = "SELECT #columnName# FROM #tableName# WHERE #columnName# = 'keep'"
				)

				expect(changedRow).toBeGT(0)
				expect(pragma.notnull[changedRow]).toBe(1)
				expect(pragma.dflt_value[changedRow]).toInclude("foo")
				expect(rowCheck.recordCount).toBe(1)
			})

		});

	}

}
