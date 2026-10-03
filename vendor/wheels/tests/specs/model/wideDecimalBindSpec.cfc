/**
 * High-precision DECIMAL / NUMERIC values (#4172). Lucee and BoxLang bind cf_sql_decimal and
 * cf_sql_numeric through a double, so a value with more than 15 significant digits was stored,
 * or matched, as a different number on PostgreSQL, SQL Server, MySQL and CockroachDB. Such a
 * value now binds in each database's exact form (text on SQL Server and MySQL, cf_sql_other on
 * PostgreSQL and CockroachDB); values with up to 15 significant digits keep their bind.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.adapterName = variables.migration.adapter.adapterName();
		variables.applies = ListFindNoCase("PostgreSQL,MicrosoftSQLServer,MySQL,CockroachDB", variables.adapterName) > 0;
		variables.ds = application.wo.get("dataSourceName");
		variables.textOf = {
			"PostgreSQL" = "CAST(## AS VARCHAR(80))",
			"MicrosoftSQLServer" = "CAST(## AS VARCHAR(80))",
			"MySQL" = "CAST(## AS CHAR)",
			"CockroachDB" = "CAST(## AS STRING)"
		};
		variables.wideType = {
			"PostgreSQL" = "cf_sql_other",
			"CockroachDB" = "cf_sql_other",
			"MicrosoftSQLServer" = "cf_sql_varchar",
			"MySQL" = "cf_sql_varchar"
		};
	}

	function afterAll() {
		if (variables.applies) {
			variables.migration.dropTable("c_o_r_e_decamounts");
		}
		StructDelete(application.wheels.models, "DecAmount");
	}

	// The stored value as text, so no engine conversion can hide a difference.
	function storedText(required string column, required any key) {
		var sqlText = "SELECT " & Replace(variables.textOf[variables.adapterName], "##", arguments.column) & " AS t FROM c_o_r_e_decamounts WHERE id = " & arguments.key;
		return QueryExecute(sqlText, [], {datasource = variables.ds}).t;
	}

	function run() {

		describe("The bind type for a decimal or numeric param", () => {

			it("is unchanged for values with up to 15 significant digits", () => {
				for (var name in variables.wideType) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Model");
					for (var v in ["12345.67", "0.10", "99999999.99", "12345.6789012345", "-123456789012345"]) {
						expect(adapter.$queryParams({type = "cf_sql_decimal", value = v, scale = 10}).cfsqltype).toBe("cf_sql_decimal", name & " " & v);
						expect(adapter.$queryParams({type = "cf_sql_numeric", value = v, scale = 10}).cfsqltype).toBe("cf_sql_numeric", name & " " & v);
					}
				}
			});

			it("is each database's exact form beyond 15 significant digits", () => {
				for (var name in variables.wideType) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Model");
					expect(adapter.$queryParams({type = "cf_sql_decimal", value = "1234567890123456789.1234567890", scale = 10}).cfsqltype).toBe(variables.wideType[name], name);
					expect(adapter.$queryParams({type = "cf_sql_numeric", value = "1234567890123456", scale = 0}).cfsqltype).toBe(variables.wideType[name], name);
					expect(adapter.$queryParams({type = "cf_sql_decimal", value = "1.5,1234567890123456789.12", list = true}).cfsqltype).toBe(variables.wideType[name], name);
				}
			});

			it("is unchanged for exponent forms, nulls and other adapters", () => {
				var pg = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
				expect(pg.$queryParams({type = "cf_sql_decimal", value = "1.2345678901234567E30"}).cfsqltype).toBe("cf_sql_decimal");
				expect(pg.$queryParams({type = "cf_sql_decimal", value = "", null = true}).cfsqltype).toBe("cf_sql_decimal");
				for (var name in ["SQLite", "H2", "Oracle"]) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Model");
					expect(adapter.$queryParams({type = "cf_sql_decimal", value = "1234567890123456789.1234567890"}).cfsqltype).toBe("cf_sql_decimal", name);
				}
			});

			it("counts significant digits without leading zeros or a fraction's trailing zeros", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
				expect(adapter.$significantDigitCount("0.10")).toBe(1);
				expect(adapter.$significantDigitCount("12345.6789012345")).toBe(15);
				expect(adapter.$significantDigitCount("-000123.4500")).toBe(5);
				expect(adapter.$significantDigitCount("1234567890123456")).toBe(16);
				expect(adapter.$significantDigitCount("120")).toBe(3);
			});

		});

		describe("A high-precision decimal column", () => {

			beforeEach(() => {
				if (!variables.applies) {
					return;
				}
				var t = variables.migration.createTable(name = "c_o_r_e_decamounts", force = true);
				t.decimal(columnNames = "amount", precision = 10, scale = 2);
				t.decimal(columnNames = "wide", precision = 38, scale = 10);
				t.create();
				StructDelete(application.wheels.models, "DecAmount");
			});

			it("stores and matches values with up to 15 significant digits exactly", () => {
				if (!variables.applies) {
					skip("High-precision binds are adapter-specific; not `#variables.adapterName#`.");
				}
				var rec = model("DecAmount").create(amount = "12345.67", wide = "12345.6789012345");
				expect(Val(storedText("amount", rec.key()))).toBe(12345.67);
				expect(storedText("wide", rec.key())).toInclude("12345.6789012345");
				expect(model("DecAmount").count(where = "amount = 12345.67")).toBe(1);
				expect(model("DecAmount").count(where = "wide = 12345.6789012345")).toBe(1);
			});

			it("stores a value beyond 15 significant digits exactly", () => {
				if (!variables.applies) {
					skip("High-precision binds are adapter-specific; not `#variables.adapterName#`.");
				}
				var rec = model("DecAmount").create(amount = "0.10", wide = "1234567890123456789.1234567890");
				expect(storedText("wide", rec.key())).toBe("1234567890123456789.1234567890");
				var whole = model("DecAmount").create(amount = "1.00", wide = "123456789012345678901234567");
				expect(ListFirst(storedText("wide", whole.key()), ".")).toBe("123456789012345678901234567");
			});

			// A value written exactly by other means must be found too, which a double-rounded
			// bind on both sides would hide.
			it("matches an exactly stored value beyond 15 significant digits in a WHERE", () => {
				if (!variables.applies) {
					skip("High-precision binds are adapter-specific; not `#variables.adapterName#`.");
				}
				QueryExecute("INSERT INTO c_o_r_e_decamounts (amount, wide) VALUES (2.50, 1234567890123456789.1234567890)", [], {datasource = variables.ds});
				expect(model("DecAmount").count(where = "wide = 1234567890123456789.1234567890")).toBe(1);
				expect(model("DecAmount").count(where = "wide = 1234567890123456789.1234567891")).toBe(0);
				expect(model("DecAmount").count(where = "wide IN (1.5, 1234567890123456789.1234567890)")).toBe(1);
			});

		});

	}

}
