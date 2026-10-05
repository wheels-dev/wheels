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

			// SQL Server rounds a text value to the column's scale and MySQL compares a text IN list
			// as doubles, so a wide value binds inside a CAST to its own scale there.
			it("is a CAST to the value's own scale on MySQL and SQL Server", () => {
				for (var name in ["MySQL", "MicrosoftSQLServer"]) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Model");
					var p = name == "MySQL" ? 65 : 38;
					var args = {parameterize = true, sql = ["SELECT 1 FROM t WHERE wide IN", {type = "cf_sql_decimal", value = "1.50,1234567890123456789.1234567890", list = true, scale = 10}]};
					adapter.$castWideDecimalParams(args = args);
					expect(ArrayLen(args.sql)).toBe(7, name);
					expect(args.sql[2]).toBe("(CAST(", name);
					expect(args.sql[3].value).toBe("1.50", name);
					expect(StructKeyExists(args.sql[3], "list")).toBeFalse(name);
					expect(args.sql[4]).toBe(" AS DECIMAL(#p#, 1))", name);
					expect(args.sql[5]).toBe(", CAST(", name);
					expect(adapter.$queryParams(args.sql[6]).cfsqltype).toBe("cf_sql_varchar", name);
					expect(args.sql[7]).toBe(" AS DECIMAL(#p#, 9)))", name);
					var single = {parameterize = true, sql = ["SELECT 1 FROM t WHERE whole =", {type = "cf_sql_decimal", value = "123456789012345678901234567", scale = 0}]};
					adapter.$castWideDecimalParams(args = single);
					expect(ArrayLen(single.sql)).toBe(4, name);
					expect(single.sql[2]).toBe("CAST(", name);
					expect(single.sql[4]).toBe(" AS DECIMAL(#p#, 0))", name);
				}
			});

			it("leaves out of an IN list a value the database can't store while another remains", () => {
				var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
				var limits = mysql.$wideDecimalCastLimits();
				var tooFine = "1." & RepeatString("1", 31);
				var tooLong = RepeatString("9", 66);
				expect(mysql.$storableDecimalValues(values = ["1.5", tooFine, tooLong, " 1234567890123456789.1234567890 "], limits = limits)).toBe(["1.5", "1234567890123456789.1234567890"]);
				expect(ArrayLen(mysql.$storableDecimalValues(values = [tooFine, tooLong], limits = limits))).toBe(0);
				var args = {parameterize = true, sql = ["SELECT 1 FROM t WHERE wide IN", {type = "cf_sql_decimal", value = "1.5,#tooFine#,1234567890123456789.1234567890", list = true, scale = 10}]};
				mysql.$castWideDecimalParams(args = args);
				expect(ArrayLen(args.sql)).toBe(7);
				var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
				var tooLong38 = RepeatString("9", 39);
				var only = {parameterize = true, sql = ["SELECT 1 FROM t WHERE whole IN", {type = "cf_sql_decimal", value = "#tooLong38#,#tooLong38#1", list = true, scale = 0}]};
				mssql.$castWideDecimalParams(args = only);
				expect(ArrayLen(only.sql)).toBe(2);
				expect(only.sql[2].list).toBeTrue();
				var one = {parameterize = true, sql = ["SELECT 1 FROM t WHERE whole =", {type = "cf_sql_decimal", value = tooLong38, scale = 0}]};
				mssql.$castWideDecimalParams(args = one);
				expect(ArrayLen(one.sql)).toBe(2);
			});

			it("leaves ordinary values, inline SQL and other adapters uncast", () => {
				var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
				var args = {parameterize = true, sql = ["SELECT 1 FROM t WHERE amount IN", {type = "cf_sql_decimal", value = "1.50,2.25", list = true, scale = 2}, "AND amount =", {type = "cf_sql_decimal", value = "12345.67", scale = 2}]};
				mysql.$castWideDecimalParams(args = args);
				expect(ArrayLen(args.sql)).toBe(4);
				var wide = {type = "cf_sql_decimal", value = "1.5,1234567890123456789.1234567890", list = true, scale = 10};
				var inline = {parameterize = false, sql = ["SELECT 1 FROM t WHERE wide IN", wide]};
				mysql.$castWideDecimalParams(args = inline);
				expect(ArrayLen(inline.sql)).toBe(2);
				for (var name in ["PostgreSQL", "CockroachDB", "SQLite", "H2", "Oracle"]) {
					var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Model");
					var other = {parameterize = true, sql = ["SELECT 1 FROM t WHERE wide IN", Duplicate(wide)]};
					adapter.$castWideDecimalParams(args = other);
					expect(ArrayLen(other.sql)).toBe(2, name);
				}
			});

			it("counts a value's integer and fraction digits", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
				expect(adapter.$fractionDigitCount("120")).toBe(0);
				expect(adapter.$fractionDigitCount("1.12345678900")).toBe(9);
				expect(adapter.$integerDigitCount("-000123.45")).toBe(3);
				expect(adapter.$integerDigitCount("0.5")).toBe(0);
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
				t.decimal(columnNames = "whole", precision = 38, scale = 0);
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
				expect(model("DecAmount").count(where = "wide IN (1.5, 1234567890123456789.1234567891)")).toBe(0);
				expect(model("DecAmount").count(where = "wide IN (1234567890123456789.1234567891, 1234567890123456789.1234567892)")).toBe(0);
			});

			// The comparison is exact for each column scale: an element with more fraction digits
			// than the column is not rounded onto a stored value it doesn't equal.
			it("matches = and IN exactly against scale-0 and scale-10 columns", () => {
				if (!variables.applies) {
					skip("High-precision binds are adapter-specific; not `#variables.adapterName#`.");
				}
				QueryExecute("INSERT INTO c_o_r_e_decamounts (amount, wide, whole) VALUES (3.00, 1234567890123456789.1234567890, 123456789012345678901234567)", [], {datasource = variables.ds});
				expect(model("DecAmount").count(where = "whole = 123456789012345678901234567")).toBe(1);
				expect(model("DecAmount").count(where = "whole = 123456789012345678901234568")).toBe(0);
				expect(model("DecAmount").count(where = "whole = 123456789012345678901234567.4")).toBe(0);
				expect(model("DecAmount").count(where = "whole <> 123456789012345678901234567.4")).toBe(1);
				expect(model("DecAmount").count(where = "wide = 1234567890123456789.12345678900")).toBe(1);
				expect(model("DecAmount").count(where = "wide = 1234567890123456789.12345678904")).toBe(0);
				expect(model("DecAmount").count(where = "whole IN (1.5, 123456789012345678901234567)")).toBe(1);
				expect(model("DecAmount").count(where = "whole NOT IN (1.5, 123456789012345678901234567.4)")).toBe(1);
				expect(model("DecAmount").count(where = "whole IN (1.5, 123456789012345678901234568)")).toBe(0);
				expect(model("DecAmount").count(where = "whole IN (1.5, 123456789012345678901234567.4)")).toBe(0);
				expect(model("DecAmount").count(where = "wide IN (1.5, 1234567890123456789.12345678900)")).toBe(1);
				expect(model("DecAmount").count(where = "wide IN (1.5, 1234567890123456789.12345678904)")).toBe(0);
				expect(model("DecAmount").count(where = "wide NOT IN (1.5, 1234567890123456789.12345678904)")).toBe(1);
			});

		});

	}

}
