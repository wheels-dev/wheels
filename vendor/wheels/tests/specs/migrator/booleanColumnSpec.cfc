/**
 * Boolean columns created by the migrator must reach the model as booleans.
 *
 * SQLite used to create `t.boolean()` columns as INTEGER and H2 as TINYINT(1),
 * so the model introspected them as integers: automatic numericality validation
 * rejected `true` / "true" ("is not a number") and a validated save failed.
 * The migrators now emit BOOLEAN, which both adapters' $getType map to
 * cf_sql_bit. Existing INTEGER / TINYINT columns keep the old behaviour until a
 * migration converts them with changeColumn(columnType="boolean"); the second
 * block pins that the conversion works and keeps the stored 1/0 values.
 *
 * Both models (BooleanFlag, BooleanFlagConverted) turn automatic validations on
 * for themselves only; the runner's global setting is left alone.
 *
 * Scoped to SQLite and H2, the adapters this fix changes. MySQL (TINYINT(1),
 * driver-dependent BIT reporting) and Oracle (NUMBER(1)) map booleans
 * differently and are not covered here.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.adapterName = variables.migration.adapter.adapterName();
		variables.applies = ListFindNoCase("SQLite,H2", variables.adapterName) > 0;
		variables.newTable = "c_o_r_e_booleanflags";
		variables.convertedTable = "c_o_r_e_booleanflagsconverted";
	}

	function afterAll() {
		if (variables.applies) {
			variables.migration.dropTable(variables.newTable);
			variables.migration.dropTable(variables.convertedTable);
		}
	}

	function run() {

		describe("A boolean column created by the migrator", () => {

			beforeEach(() => {
				if (!variables.applies) {
					return;
				}
				var t = variables.migration.createTable(name = variables.newTable, force = true);
				t.string(columnNames = "label");
				t.boolean(columnNames = "flag");
				t.create();
				StructDelete(application.wheels.models, "BooleanFlag");
			});

			it("introspects as a boolean property", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite and H2 only, not `#variables.adapterName#`.");
				}
				var prop = model("BooleanFlag").$classData().properties.flag;
				expect(prop.validationtype).toBe("boolean");
				expect(prop.type).toBe("cf_sql_bit");
			});

			it("passes automatic validation for true and the strings true / false", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite and H2 only, not `#variables.adapterName#`.");
				}
				expect(model("BooleanFlag").new(label = "a", flag = true).valid()).toBeTrue();
				expect(model("BooleanFlag").new(label = "b", flag = "true").valid()).toBeTrue();
				expect(model("BooleanFlag").new(label = "c", flag = "false").valid()).toBeTrue();
			});

			it("saves true with validation on and reads it back as true", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite and H2 only, not `#variables.adapterName#`.");
				}
				var obj = model("BooleanFlag").new(label = "d", flag = true);
				expect(obj.save()).toBeTrue();
				var reloaded = model("BooleanFlag").findByKey(obj.key());
				expect(reloaded.flag ? true : false).toBeTrue();
			});

		});

		describe("Converting an existing integer boolean column with changeColumn", () => {

			beforeEach(() => {
				if (!variables.applies) {
					return;
				}
				// The type each adapter used to emit for t.boolean().
				var legacyType = variables.adapterName == "H2" ? "TINYINT(1)" : "INTEGER";
				variables.migration.dropTable(variables.convertedTable);
				variables.migration.execute(
					"CREATE TABLE #variables.convertedTable# (id INTEGER PRIMARY KEY, label VARCHAR(20), flag #legacyType#)"
				);
				variables.migration.execute("INSERT INTO #variables.convertedTable# (id, label, flag) VALUES (1, 'on', 1)");
				variables.migration.execute("INSERT INTO #variables.convertedTable# (id, label, flag) VALUES (2, 'off', 0)");
				variables.migration.changeColumn(table = variables.convertedTable, columnName = "flag", columnType = "boolean");
				StructDelete(application.wheels.models, "BooleanFlagConverted");
			});

			it("introspects as a boolean property after the conversion", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite and H2 only, not `#variables.adapterName#`.");
				}
				var prop = model("BooleanFlagConverted").$classData().properties.flag;
				expect(prop.validationtype).toBe("boolean");
				expect(prop.type).toBe("cf_sql_bit");
			});

			it("keeps the stored 1 / 0 values", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite and H2 only, not `#variables.adapterName#`.");
				}
				var rows = model("BooleanFlagConverted").findAll(order = "id");
				expect(rows.recordCount).toBe(2);
				expect(rows.flag[1] ? true : false).toBeTrue();
				expect(rows.flag[2] ? true : false).toBeFalse();
			});

			it("passes automatic validation for true and saves it", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite and H2 only, not `#variables.adapterName#`.");
				}
				var obj = model("BooleanFlagConverted").new(id = 3, label = "new", flag = true);
				expect(obj.valid()).toBeTrue();
				expect(obj.save()).toBeTrue();
			});

		});

	}

}
