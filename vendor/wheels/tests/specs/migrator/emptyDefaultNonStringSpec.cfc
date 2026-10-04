/**
 * An empty `default` on a column that is not string-like means "no default": DEFAULT NULL
 * when the column may hold null, no DEFAULT clause on a NOT NULL column. It never renders as
 * a bare DEFAULT (biginteger, uniqueidentifier) or an empty literal (binary), which the
 * databases reject. Checked on the generated clause and by creating the table.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.adapter = variables.migration.adapter;
		variables.types = ["biginteger", "binary", "uniqueidentifier", "integer", "decimal", "date"];
	}

	private string function clauseFor(required string type, required boolean allowNull) {
		return variables.adapter.addColumnOptions(
			sql = "",
			options = {type: arguments.type, default: "", allowNull: arguments.allowNull}
		);
	}

	function run() {

		describe("addColumnOptions with default='' on types that are not string-like", () => {

			it("renders DEFAULT NULL on a column that may hold null", () => {
				for (var type in variables.types) {
					var clause = clauseFor(type = type, allowNull = true);
					expect(clause).toInclude(" DEFAULT NULL", "#type#: '#clause#'");
					expect(clause).notToInclude("DEFAULT ''", "#type#: '#clause#'");
					expect(clause).notToInclude("DEFAULT  ", "#type#: '#clause#'");
				}
			});

			it("renders no DEFAULT clause on a NOT NULL column", () => {
				for (var type in variables.types) {
					var clause = clauseFor(type = type, allowNull = false);
					expect(clause).notToInclude("DEFAULT", "#type#: '#clause#'");
					expect(clause).toInclude("NOT NULL", "#type#: '#clause#'");
				}
			});

			it("still rejects an empty default on string-like columns", () => {
				var state = {type = ""};
				try {
					clauseFor(type = "string", allowNull = false);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.InvalidDefault");
			});

		});

		describe("changeColumn with default='' on a column that is not string-like", () => {

			it("changes the column to NOT NULL with no DEFAULT, and back to nullable", () => {
				var state = {step = "", message = "", notNullSql = ""};
				var tableName = "dbm_empty_dflt_change";
				try {
					state.step = "create";
					var t = variables.migration.createTable(name = tableName, force = true);
					t.bigInteger(columnNames = "amount", allowNull = true);
					t.create();
					state.step = "generate";
					var column = CreateObject("component", "wheels.migrator.ColumnDefinition").init(
						adapter = variables.adapter,
						name = "amount",
						type = "biginteger",
						default = "",
						allowNull = false
					);
					// SQLite rebuilds the table and returns its statements as an array.
					var generated = variables.adapter.changeColumnInTable(name = tableName, column = column);
					state.notNullSql = IsArray(generated) ? ArrayToList(generated, "; ") : generated;
					state.step = "change to NOT NULL";
					variables.migration.changeColumn(table = tableName, columnName = "amount", columnType = "biginteger", default = "", allowNull = false);
					state.step = "change to nullable";
					variables.migration.changeColumn(table = tableName, columnName = "amount", columnType = "biginteger", default = "", allowNull = true);
					state.step = "done";
				} catch (any e) {
					state.message = e.message & " " & (e.detail ?: "");
				}
				try {
					variables.migration.dropTable(tableName);
				} catch (any e) {
				}
				expect(state.step).toBe("done", "failed at '#state.step#': #state.message#");
				// a NOT NULL column with an empty default gets no DEFAULT on any adapter
				expect(state.notNullSql).toInclude("amount", "the generated change must cover the column: #state.notNullSql#");
				expect(state.notNullSql).toInclude("NOT NULL", "the generated change must make the column NOT NULL: #state.notNullSql#");
				expect(state.notNullSql).notToInclude("DEFAULT", state.notNullSql);
			});

		});

		describe("createTable with default='' on types that are not string-like", () => {

			it("creates the table whether the columns allow null or not", () => {
				var state = {created = false, message = ""};
				var tableName = "dbm_empty_default_test";
				try {
					var t = variables.migration.createTable(name = tableName, force = true);
					for (var type in variables.types) {
						t.column(columnName = "#type#_null", columnType = type, default = "", allowNull = true);
						t.column(columnName = "#type#_notnull", columnType = type, default = "", allowNull = false);
					}
					t.create();
					state.created = true;
				} catch (any e) {
					state.message = e.message & " " & (e.detail ?: "");
				}
				try {
					variables.migration.dropTable(tableName);
				} catch (any e) {
				}
				expect(state.created).toBeTrue(state.message);
			});

		});

	}

}
