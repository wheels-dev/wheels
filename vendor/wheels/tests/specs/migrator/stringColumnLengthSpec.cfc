/**
 * A string column created by the migrator must report its declared length, so
 * automatic validations enforce it (#4101). CockroachDB reported a STRING(n)
 * column over JDBC as `text` with no usable size, so any length passed.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.table = "c_o_r_e_stringlimits";
	}

	function afterAll() {
		variables.migration.dropTable(variables.table);
	}

	// Drops the model and its memoized column metadata, so the next model() call
	// re-reads the table after a schema change.
	function reloadStringLimit(required string tableName) {
		StructDelete(application.wheels.models, "StringLimit");
		if (StructKeyExists(application.wheels, "schemaColumnCache")) {
			StructDelete(application.wheels.schemaColumnCache, Hash(application.wo.get("dataSourceName") & Chr(31) & arguments.tableName));
		}
	}

	function run() {

		describe("A string column created by the migrator", () => {

			beforeEach(() => {
				var t = variables.migration.createTable(name = variables.table, force = true);
				t.string(columnNames = "shortName", limit = 20, allowNull = false);
				t.string(columnNames = "label");
				t.create();
				StructDelete(application.wheels.models, "StringLimit");
			});

			it("introspects with its declared limit", () => {
				var props = model("StringLimit").$classData().properties;
				expect(props.shortName.size).toBe(20);
				expect(props.label.size).toBe(255);
			});

			it("is length-validated against that limit", () => {
				expect(model("StringLimit").new(shortName = RepeatString("x", 20)).valid()).toBeTrue();
				var tooLong = model("StringLimit").new(shortName = RepeatString("x", 21));
				expect(tooLong.valid()).toBeFalse();
				expect(ArrayLen(tooLong.errorsOn("shortName"))).toBeGT(0);
			});

		});

		// The upgrade path the changelog documents for columns created before #4101.
		describe("A legacy CockroachDB STRING(n) column", () => {

			it("reports its limit after changeColumn re-declares it", () => {
				if (variables.migration.adapter.adapterName() != "CockroachDB") {
					skip("STRING(n) columns are CockroachDB-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				variables.migration.execute("ALTER TABLE #variables.table# ADD COLUMN legacyName STRING(20)");
				reloadStringLimit(variables.table);
				expect(model("StringLimit").$classData().properties.legacyName.size).toBe(2147483647);

				variables.migration.changeColumn(table = variables.table, columnName = "legacyName", columnType = "string", limit = 20);
				reloadStringLimit(variables.table);
				expect(model("StringLimit").$classData().properties.legacyName.size).toBe(20);
			});

		});

		describe("CockroachDB typeToSQL() for a string column", () => {

			it("declares VARCHAR, which reports its length over JDBC", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.CockroachDB.CockroachDBMigrator");
				expect(adapter.typeToSQL(type = "string")).toBe("VARCHAR(255)");
				expect(adapter.typeToSQL(type = "string", options = {limit = 20})).toBe("VARCHAR(20)");
			});

		});

	}

}
