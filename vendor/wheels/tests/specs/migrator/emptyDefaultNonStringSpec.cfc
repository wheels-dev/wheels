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
