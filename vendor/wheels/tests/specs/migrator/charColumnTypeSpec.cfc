/**
 * t.char() must emit a CHAR column type on every adapter (#4092). SQLite, H2,
 * MySQL and Oracle had no `char` entry in their migrator type map, so
 * typeToSQL() returned "" and the column was created with no type. On SQLite
 * every model on such a table then failed to load.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.table = "c_o_r_e_charcodes";
		variables.adapters = "SQLite,H2,MySQL,Oracle,PostgreSQL,CockroachDB,MicrosoftSQLServer";
	}

	function afterAll() {
		variables.migration.dropTable(variables.table);
	}

	function run() {

		describe("typeToSQL() for a char column", () => {

			it("emits CHAR with a default length on every adapter", () => {
				for (var name in ListToArray(variables.adapters)) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Migrator");
					expect(adapter.typeToSQL(type = "char")).toMatch("^CHAR\(\d+\)$", name);
				}
			});

			it("uses an explicit limit on every adapter", () => {
				for (var name in ListToArray(variables.adapters)) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Migrator");
					expect(adapter.typeToSQL(type = "char", options = {limit = 3})).toBe("CHAR(3)", name);
				}
			});

		});

		describe("A char column created by the migrator", () => {

			beforeEach(() => {
				var t = variables.migration.createTable(name = variables.table, force = true);
				t.string(columnNames = "label");
				t.char(columnNames = "shortCode", limit = 3);
				t.create();
				StructDelete(application.wheels.models, "CharCode");
			});

			it("loads a model and introspects as a string property", () => {
				var prop = model("CharCode").$classData().properties.shortCode;
				expect(ListFindNoCase("cf_sql_char,cf_sql_varchar", prop.type)).toBeGT(0, prop.type);
				expect(prop.validationtype).toBe("string");
			});

			it("round-trips a value through save and find", () => {
				var obj = model("CharCode").new(label = "a", shortCode = "ABC");
				expect(obj.save()).toBeTrue();
				expect(Trim(model("CharCode").findByKey(obj.key()).shortCode)).toBe("ABC");
			});

		});

	}

}
