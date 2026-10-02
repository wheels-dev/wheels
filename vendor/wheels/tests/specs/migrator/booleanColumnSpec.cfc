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
 * MySQL used to emit TINYINT(1), which reaches the model as an integer
 * whenever the DSN sets `tinyInt1isBit=false` (cfdbinfo then reports it exactly
 * like TINYINT(4)). It now emits BIT(1), which every driver setting reports as
 * BIT (#3897). Its legacy TINYINT(1) column is converted with changeColumn too.
 *
 * Oracle 23ai+ has a native BOOLEAN type, which the migrator now emits instead
 * of NUMBER(1) (#3897); earlier Oracle releases keep NUMBER(1) and are not
 * covered. Oracle cannot change the datatype of a non-empty column (ORA-01439),
 * so the changeColumn conversion block does not apply to it.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.adapterName = variables.migration.adapter.adapterName();
		variables.nativeOracle = variables.adapterName == "Oracle" && variables.migration.$oracleSupportsNativeBoolean();
		variables.applies = ListFindNoCase("SQLite,H2,MySQL", variables.adapterName) > 0 || variables.nativeOracle;
		variables.convertApplies = ListFindNoCase("SQLite,H2,MySQL", variables.adapterName) > 0;
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
				t.boolean(columnNames = "flagged", default = true);
				t.create();
				StructDelete(application.wheels.models, "BooleanFlag");
			});

			it("introspects as a boolean property", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite, H2, MySQL and Oracle 23ai+ only, not `#variables.adapterName#`.");
				}
				var prop = model("BooleanFlag").$classData().properties.flag;
				expect(prop.validationtype).toBe("boolean");
				expect(prop.type).toBe("cf_sql_bit");
			});

			// The DDL itself, not the driver's report of it: with the driver default
			// (tinyInt1isBit=true) a TINYINT(1) column also introspects as BIT, so only
			// the declared type shows the column works under every DSN setting.
			it("is declared as BIT(1) on MySQL", () => {
				if (variables.adapterName != "MySQL") {
					skip("The BIT(1) declaration is MySQL-only, not `#variables.adapterName#`.");
				}
				var declared = QueryExecute(
					"SELECT COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '#variables.newTable#' AND COLUMN_NAME = 'flag'",
					[],
					{datasource = application.wo.get("dataSourceName")}
				);
				expect(declared.recordCount).toBe(1);
				expect(LCase(declared.COLUMN_TYPE)).toBe("bit(1)");
			});

			it("is declared as BOOLEAN on Oracle 23ai+", () => {
				if (!variables.nativeOracle) {
					skip("The native BOOLEAN declaration is Oracle 23ai+ only, not `#variables.adapterName#`.");
				}
				var declared = QueryExecute(
					"SELECT data_type FROM user_tab_columns WHERE table_name = UPPER('#variables.newTable#') AND column_name = 'FLAG'",
					[],
					{datasource = application.wo.get("dataSourceName")}
				);
				expect(declared.recordCount).toBe(1);
				expect(UCase(declared.data_type)).toBe("BOOLEAN");
			});

			it("passes automatic validation for true and the strings true / false", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite, H2, MySQL and Oracle 23ai+ only, not `#variables.adapterName#`.");
				}
				expect(model("BooleanFlag").new(label = "a", flag = true).valid()).toBeTrue();
				expect(model("BooleanFlag").new(label = "b", flag = "true").valid()).toBeTrue();
				expect(model("BooleanFlag").new(label = "c", flag = "false").valid()).toBeTrue();
			});

			it("applies a boolean default when the property is not set", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite, H2, MySQL and Oracle 23ai+ only, not `#variables.adapterName#`.");
				}
				var obj = model("BooleanFlag").new(label = "defaulted", flag = false);
				expect(obj.save()).toBeTrue();
				var reloaded = model("BooleanFlag").findByKey(obj.key());
				expect(reloaded.flagged ? true : false).toBeTrue();
			});

			// #3896: true / false bind through the value APIs on a migration boolean column.
			it("finds rows by true and false through where() and dynamic finders", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite, H2, MySQL and Oracle 23ai+ only, not `#variables.adapterName#`.");
				}
				expect(model("BooleanFlag").new(label = "yes", flag = true).save()).toBeTrue();
				expect(model("BooleanFlag").new(label = "no", flag = false).save()).toBeTrue();
				expect(model("BooleanFlag").where("flag", true).count()).toBe(1);
				expect(model("BooleanFlag").where("flag", false).count()).toBe(1);
				expect(model("BooleanFlag").findAllByFlag(value = true, returnAs = "query").recordCount).toBe(1);
				expect(model("BooleanFlag").findOneByFlag(value = false, returnAs = "query").label).toBe("no");
			});

			it("saves true with validation on and reads it back as true", () => {
				if (!variables.applies) {
					skip("Boolean column mapping is pinned for SQLite, H2, MySQL and Oracle 23ai+ only, not `#variables.adapterName#`.");
				}
				var obj = model("BooleanFlag").new(label = "d", flag = true);
				expect(obj.save()).toBeTrue();
				var reloaded = model("BooleanFlag").findByKey(obj.key());
				expect(reloaded.flag ? true : false).toBeTrue();
			});

		});

		describe("Converting an existing integer boolean column with changeColumn", () => {

			beforeEach(() => {
				if (!variables.convertApplies) {
					return;
				}
				// The type each adapter used to emit for t.boolean().
				var legacyType = ListFindNoCase("H2,MySQL", variables.adapterName) ? "TINYINT(1)" : "INTEGER";
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
				if (!variables.convertApplies) {
					skip("The changeColumn conversion is pinned for SQLite, H2 and MySQL only, not `#variables.adapterName#`: Oracle cannot change the datatype of a non-empty column (ORA-01439).");
				}
				var prop = model("BooleanFlagConverted").$classData().properties.flag;
				expect(prop.validationtype).toBe("boolean");
				expect(prop.type).toBe("cf_sql_bit");
			});

			it("keeps the stored 1 / 0 values", () => {
				if (!variables.convertApplies) {
					skip("The changeColumn conversion is pinned for SQLite, H2 and MySQL only, not `#variables.adapterName#`: Oracle cannot change the datatype of a non-empty column (ORA-01439).");
				}
				var rows = model("BooleanFlagConverted").findAll(order = "id");
				expect(rows.recordCount).toBe(2);
				expect(rows.flag[1] ? true : false).toBeTrue();
				expect(rows.flag[2] ? true : false).toBeFalse();
			});

			it("passes automatic validation for true and saves it", () => {
				if (!variables.convertApplies) {
					skip("The changeColumn conversion is pinned for SQLite, H2 and MySQL only, not `#variables.adapterName#`: Oracle cannot change the datatype of a non-empty column (ORA-01439).");
				}
				var obj = model("BooleanFlagConverted").new(id = 3, label = "new", flag = true);
				expect(obj.valid()).toBeTrue();
				expect(obj.save()).toBeTrue();
			});

		});

	}

}
