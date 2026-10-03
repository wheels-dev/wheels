/**
 * Oracle integer columns must carry their precision (#4097). OracleMigrator's
 * typeToSQL() applied only the `limit` default from its type map, so
 * t.integer(), t.bigInteger(), t.boolean() and the id primary key were all
 * created as a bare NUMBER, which binds as cf_sql_numeric and validates as a
 * float. Without a precision, changeColumn() keeps a column's current precision:
 * Oracle refuses to narrow a populated column (ORA-01440), and changeColumn() is
 * how existing apps change a default or allowNull, so it must not re-type one.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.isOracle = variables.migration.adapter.adapterName() == "Oracle";
		variables.table = "c_o_r_e_oranumbers";
		variables.oracle = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleMigrator");
	}

	function afterAll() {
		variables.migration.dropTable(variables.table);
	}

	// Drops the model and its memoized column metadata, so the next model() call
	// re-reads the table after a schema change.
	function reloadOraNumber(required string tableName) {
		StructDelete(application.wheels.models, "OraNumber");
		if (StructKeyExists(application.wheels, "schemaColumnCache")) {
			StructDelete(application.wheels.schemaColumnCache, Hash(application.wo.get("dataSourceName") & Chr(31) & arguments.tableName));
		}
	}

	function declaredPrecision(required string tableName, required string columnName) {
		var q = QueryExecute(
			"SELECT data_precision FROM user_tab_columns WHERE table_name = UPPER('#arguments.tableName#') AND column_name = UPPER('#arguments.columnName#')",
			[],
			{datasource = application.wo.get("dataSourceName")}
		);
		return q.recordCount ? q.data_precision : "missing";
	}

	function run() {

		describe("OracleMigrator typeToSQL() for NUMBER types", () => {

			it("applies the precision default of each integer type", () => {
				expect(variables.oracle.typeToSQL(type = "integer")).toBe("NUMBER(10)");
				expect(variables.oracle.typeToSQL(type = "biginteger")).toBe("NUMBER(19)");
				expect(variables.oracle.typeToSQL(type = "boolean")).toBe("NUMBER(1)");
			});

			it("lets an explicit precision win and leaves decimal without a default", () => {
				expect(variables.oracle.typeToSQL(type = "integer", options = {precision = 5})).toBe("NUMBER(5)");
				expect(variables.oracle.typeToSQL(type = "decimal")).toBe("NUMBER");
				expect(variables.oracle.typeToSQL(type = "decimal", options = {precision = 8, scale = 2})).toBe("NUMBER(8,2)");
			});

			it("emits a bare NUMBER in changeColumn() for a column with no current precision, unless one is passed", () => {
				var column = CreateObject("component", "wheels.migrator.ColumnDefinition").init(adapter = variables.oracle, name = "qty", type = "integer");
				var sqlText = variables.oracle.changeColumnInTable(name = "orders", column = column);
				expect(sqlText).toInclude("MODIFY");
				expect(sqlText).notToInclude("NUMBER(");

				var narrowed = CreateObject("component", "wheels.migrator.ColumnDefinition").init(adapter = variables.oracle, name = "qty", type = "integer", precision = 10);
				expect(variables.oracle.changeColumnInTable(name = "orders", column = narrowed)).toInclude("NUMBER(10)");
			});

		});

		describe("An integer column created by the migrator", () => {

			beforeEach(() => {
				var t = variables.migration.createTable(name = variables.table, force = true);
				t.integer(columnNames = "qty");
				t.bigInteger(columnNames = "total");
				t.decimal(columnNames = "price", precision = 8, scale = 2);
				t.create();
				reloadOraNumber(variables.table);
			});

			it("validates as an integer and rejects a fraction", () => {
				var props = model("OraNumber").$classData().properties;
				expect(props.qty.validationtype).toBe("integer");
				expect(props.total.validationtype).toBe("integer");
				expect(model("OraNumber").new(qty = 3, total = 4).valid()).toBeTrue();
				expect(model("OraNumber").new(qty = 1.5, total = 4).valid()).toBeFalse();
			});

			it("is declared with its precision on Oracle", () => {
				if (!variables.isOracle) {
					skip("NUMBER precision is Oracle-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				expect(declaredPrecision(variables.table, "id")).toBe(10);
				expect(declaredPrecision(variables.table, "qty")).toBe(10);
				expect(declaredPrecision(variables.table, "total")).toBe(19);
				var props = model("OraNumber").$classData().properties;
				expect(props.qty.type).toBe("cf_sql_integer");
				expect(props.total.type).toBe("cf_sql_bigint");
			});

			// changeColumn() is how a migration changes a default; it must not re-type the column.
			it("keeps NUMBER(10) and NUMBER(8,2) when changeColumn() changes only a default", () => {
				if (!variables.isOracle) {
					skip("NUMBER precision is Oracle-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				variables.migration.changeColumn(table = variables.table, columnName = "qty", columnType = "integer", default = 0);
				variables.migration.changeColumn(table = variables.table, columnName = "price", columnType = "decimal", default = 0);

				expect(declaredPrecision(variables.table, "qty")).toBe(10);
				expect(declaredPrecision(variables.table, "price")).toBe(8);
				var scale = QueryExecute(
					"SELECT data_scale FROM user_tab_columns WHERE table_name = UPPER('#variables.table#') AND column_name = 'PRICE'",
					[],
					{datasource = application.wo.get("dataSourceName")}
				);
				expect(scale.data_scale).toBe(2);
				reloadOraNumber(variables.table);
				expect(model("OraNumber").$classData().properties.qty.validationtype).toBe("integer");
			});

			// The guide's in-place conversion for a legacy column that holds no data.
			it("moves an empty legacy bare NUMBER column to NUMBER(10) when a precision is passed", () => {
				if (!variables.isOracle) {
					skip("Bare NUMBER columns are Oracle-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				variables.migration.execute("ALTER TABLE #variables.table# ADD emptycount NUMBER");
				variables.migration.changeColumn(table = variables.table, columnName = "emptycount", columnType = "integer", precision = 10);
				expect(declaredPrecision(variables.table, "emptycount")).toBe(10);
			});

			// An app upgrading from an earlier version has populated bare NUMBER columns.
			it("can still changeColumn() a populated legacy bare NUMBER column", () => {
				if (!variables.isOracle) {
					skip("Bare NUMBER columns are Oracle-only, not `#variables.migration.adapter.adapterName()#`.");
				}
				variables.migration.execute("ALTER TABLE #variables.table# ADD legacycount NUMBER");
				reloadOraNumber(variables.table);
				var row = model("OraNumber").create(qty = 1, total = 2);
				variables.migration.execute("UPDATE #variables.table# SET legacycount = 5");

				variables.migration.changeColumn(table = variables.table, columnName = "legacycount", columnType = "integer", allowNull = false, default = 0);

				expect(declaredPrecision(variables.table, "legacycount")).toBe("");
				reloadOraNumber(variables.table);
				expect(model("OraNumber").findByKey(row.key()).legacycount).toBe(5);
			});

		});

	}

}
