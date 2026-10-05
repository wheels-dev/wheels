/**
 * IN lists past SQL Server's parameter limit (#4103). A statement that would bind more than the
 * adapter's limit binds each of its largest IN lists as one parameter instead, expanded on the
 * server: `IN (SELECT CAST(value AS <type>) FROM STRING_SPLIT(?, NCHAR(31)))`. Statements that fit
 * keep their SQL. It needs compatibility level 130; below it, and for lists of other types such as
 * dates, Wheels.TooManyParameters is kept.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.isSqlServer = variables.g.get("adapterName") == "MicrosoftSQLServerModel";
		variables.mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
		if (variables.isSqlServer) {
			variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
			var t = variables.migration.createTable(name = "c_o_r_e_decamounts", force = true);
			t.decimal(columnNames = "amount", precision = 10, scale = 2);
			t.decimal(columnNames = "wide", precision = 38, scale = 10);
			t.decimal(columnNames = "whole", precision = 38, scale = 0);
			t.create();
			StructDelete(application.wheels.models, "DecAmount");
			QueryExecute(
				"INSERT INTO c_o_r_e_decamounts (amount, wide, whole) VALUES (1.50, 1234567890123456789.1234567890, 7), (2.25, 2.5, 8)",
				[],
				{datasource = variables.g.get("dataSourceName")}
			);
		}
	}

	function afterAll() {
		if (variables.isSqlServer) {
			adapterOf("author").$setInListSplitLimit(0);
			adapterOf("decAmount").$setInListSplitLimit(0);
			variables.migration.dropTable("c_o_r_e_decamounts");
		}
		StructDelete(application.wheels.models, "DecAmount");
	}

	function adapterOf(required string modelName) {
		return variables.g.model(arguments.modelName).$classData().adapter;
	}

	function listPart(required string type, required string value) {
		return {type = arguments.type, value = arguments.value, list = true};
	}

	// `size` keys: every real author id, padded with negative ids that can never match.
	function paddedIds(required numeric size) {
		var ids = [];
		var authors = variables.g.model("author").findAll(select = "id", returnAs = "query");
		for (var r = 1; r <= authors.recordCount; r++) {
			ArrayAppend(ids, authors.id[r]);
		}
		var pad = -1;
		while (ArrayLen(ids) < arguments.size) {
			ArrayAppend(ids, pad);
			pad--;
		}
		return ids;
	}

	// The error a call throws, or empty fields when it doesn't.
	function errorOf(required any callback) {
		var state = {type = "", message = "", extendedInfo = ""};
		var target = arguments.callback;
		try {
			target();
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
			state.extendedInfo = e.extendedInfo;
		}
		return state;
	}

	function run() {

		describe("The STRING_SPLIT form of an IN list", () => {

			it("casts integers and decimals and leaves strings as they are", () => {
				var ints = variables.mssql.$stringSplitList(listPart("cf_sql_integer", "1, 2,3"));
				expect(ints.expression).toBe("CAST(value AS INT)");
				expect(ints.values).toBe(["1", "2", "3"]);
				expect(variables.mssql.$stringSplitList(listPart("cf_sql_bigint", "1,2")).expression).toBe("CAST(value AS BIGINT)");
				var decimals = variables.mssql.$stringSplitList(listPart("cf_sql_decimal", "1.5,1234567890123456789.1234567890,7"));
				expect(decimals.expression).toBe("CAST(value AS DECIMAL(38, 9))");
				var strings = variables.mssql.$stringSplitList(listPart("cf_sql_varchar", "'a','b c'"));
				expect(strings.expression).toBe("value");
				expect(strings.values).toBe(["a", "b c"]);
			});

			it("is not used for dates, values that don't validate, or a decimal beyond 38 digits", () => {
				expect(StructIsEmpty(variables.mssql.$stringSplitList(listPart("cf_sql_timestamp", "'2026-01-01','2026-01-02'")))).toBeTrue();
				expect(StructIsEmpty(variables.mssql.$stringSplitList(listPart("cf_sql_integer", "1,x")))).toBeTrue();
				expect(StructIsEmpty(variables.mssql.$stringSplitList(listPart("cf_sql_decimal", "1.5,1E5")))).toBeTrue();
				expect(StructIsEmpty(variables.mssql.$stringSplitList(listPart("cf_sql_decimal", RepeatString("9", 30) & "," & "1." & RepeatString("1", 9))))).toBeTrue();
				expect(StructIsEmpty(variables.mssql.$stringSplitList({type = "cf_sql_integer", value = "1"}))).toBeTrue();
			});

			it("refuses a string value that holds the delimiter", () => {
				var thrown = errorOf(() => variables.mssql.$stringSplitList(listPart("cf_sql_varchar", "'a','b#Chr(31)#c'")));
				expect(thrown.type).toBe("Wheels.QueryParamValue");
			});

			it("splits the largest lists first, only until the statement fits", () => {
				var sql = [
					"SELECT 1 FROM t WHERE a IN", listPart("cf_sql_integer", "1,2,3"),
					"AND b IN", listPart("cf_sql_integer", "1,2,3,4,5"),
					"AND c =", {type = "cf_sql_integer", value = "1"}
				];
				expect(variables.mssql.$boundParameterCount(sql)).toBe(9);
				expect(StructKeyList(variables.mssql.$inListsToSplit(sql = sql, limit = 6))).toBe("4");
				expect(ListSort(StructKeyList(variables.mssql.$inListsToSplit(sql = sql, limit = 4)), "numeric")).toBe("2,4");
				expect(StructIsEmpty(variables.mssql.$inListsToSplit(sql = sql, limit = 9))).toBeTrue();
			});

			it("keeps the SQL of a statement that fits", () => {
				var args = {parameterize = true, dataSource = "unused", sql = ["SELECT 1 FROM t WHERE a IN", listPart("cf_sql_integer", "1,2,3")]};
				variables.mssql.$splitLargeInLists(args = args);
				expect(ArrayLen(args.sql)).toBe(2);
				var parts = variables.mssql.$stringSplitParts(listPart("cf_sql_integer", "1,2"));
				expect(parts[1]).toBe("(SELECT CAST(value AS INT) FROM STRING_SPLIT(");
				expect(parts[2].value).toBe("1#Chr(31)#2");
				expect(parts[3]).toBe(", NCHAR(31)))");
			});

		});

		describe("IN lists past SQL Server's parameter limit", () => {

			afterEach(() => {
				if (variables.isSqlServer) {
					adapterOf("author").$setInListSplitLimit(0);
					adapterOf("decAmount").$setInListSplitLimit(0);
				}
			});

			it("returns the same rows split as bound one parameter per value", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				var ids = paddedIds(12);
				var authors = variables.g.model("author").findAll(returnAs = "query");
				var names = [];
				for (var r = 1; r <= authors.recordCount; r++) {
					ArrayAppend(names, authors.firstName[r]);
				}
				ArrayAppend(names, "nobody, at all");
				var expected = {
					idIn = variables.g.model("author").whereIn("id", ids).count(),
					idNotIn = variables.g.model("author").whereNotIn("id", ids).count(),
					nameIn = variables.g.model("author").whereIn("firstName", names).count(),
					whereIn = variables.g.model("author").count(where = "id IN (#ArrayToList(ids)#)")
				};
				adapterOf("author").$setInListSplitLimit(2);
				expect(variables.g.model("author").whereIn("id", ids).count()).toBe(expected.idIn);
				expect(variables.g.model("author").whereNotIn("id", ids).count()).toBe(expected.idNotIn);
				expect(variables.g.model("author").whereIn("firstName", names).count()).toBe(expected.nameIn);
				expect(variables.g.model("author").count(where = "id IN (#ArrayToList(ids)#)")).toBe(expected.whereIn);
				expect(expected.idIn).toBeGT(0);
				expect(expected.nameIn).toBe(authors.recordCount);
			});

			it("matches decimals exactly when split", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				adapterOf("decAmount").$setInListSplitLimit(2);
				expect(variables.g.model("decAmount").count(where = "wide IN (2.5, 1234567890123456789.1234567890, 9)")).toBe(2);
				expect(variables.g.model("decAmount").count(where = "wide IN (2.5000, 1234567890123456789.1234567891, 9)")).toBe(1);
				expect(variables.g.model("decAmount").count(where = "wide NOT IN (2.5, 1234567890123456789.12345678904, 9)")).toBe(1);
				expect(variables.g.model("decAmount").count(where = "amount IN (1.5, 2.25, 3)")).toBe(2);
				expect(variables.g.model("decAmount").count(where = "whole IN (7.4, 8, 9)")).toBe(1);
			});

			it("runs a list far past the limit", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				var realCount = variables.g.model("author").count();
				expect(variables.g.model("author").whereIn("id", paddedIds(5000)).count()).toBe(realCount);
				expect(variables.g.model("author").whereNotIn("id", paddedIds(5000)).count()).toBe(0);
			});

			it("keeps Wheels.TooManyParameters for a date list past the limit", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				var dates = [];
				for (var i = 1; i <= 2200; i++) {
					ArrayAppend(dates, DateFormat(DateAdd("d", i, CreateDate(2000, 1, 1)), "yyyy-mm-dd"));
				}
				var thrown = errorOf(() => variables.g.model("post").whereIn("createdAt", dates).count());
				expect(thrown.type).toBe("Wheels.TooManyParameters");
				expect(thrown.extendedInfo).toInclude("Any other list (dates, times");
			});

			it("keeps Wheels.TooManyParameters for a float list past the limit, and says which lists it combines", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				var ratings = [];
				for (var i = 1; i <= 2200; i++) {
					ArrayAppend(ratings, i + 0.25);
				}
				var thrown = errorOf(() => variables.g.model("post").whereIn("averageRating", ratings).count());
				expect(thrown.type).toBe("Wheels.TooManyParameters");
				expect(thrown.extendedInfo).toInclude("integers, plain decimals (up to 38 digits), strings or uniqueidentifiers");
				expect(thrown.extendedInfo).toInclude("float");
			});

			it("keeps Wheels.TooManyParameters below compatibility level 130", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				var ds = variables.g.get("dataSourceName");
				var original = QueryExecute("SELECT compatibility_level AS lvl FROM sys.databases WHERE name = DB_NAME()", [], {datasource = ds}).lvl;
				try {
					QueryExecute("ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 120", [], {datasource = ds});
					if (StructKeyExists(application.wheels, "sqlServerCompatibilityLevels")) {
						StructDelete(application.wheels.sqlServerCompatibilityLevels, ds);
					}
					var thrown = errorOf(() => variables.g.model("author").whereIn("id", paddedIds(2200)).count());
					expect(thrown.type).toBe("Wheels.TooManyParameters");
					expect(thrown.extendedInfo).toInclude("below level 130");
					expect(application.wheels.sqlServerCompatibilityLevels[ds]).toBe(120);
				} finally {
					QueryExecute("ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = #original#", [], {datasource = ds});
					StructDelete(application.wheels.sqlServerCompatibilityLevels, ds);
				}
			});

			// The level lives in the application's Wheels settings, which an application reload
			// rebuilds from scratch, so a reload reads it again.
			it("reads the compatibility level once per datasource and again once it is cleared", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				var ds = variables.g.get("dataSourceName");
				var adapter = adapterOf("author");
				if (StructKeyExists(application.wheels, "sqlServerCompatibilityLevels")) {
					StructDelete(application.wheels.sqlServerCompatibilityLevels, ds);
				}
				expect(adapter.$supportsStringSplit(ds)).toBeTrue();
				expect(application.wheels.sqlServerCompatibilityLevels[ds]).toBeGTE(130);
				application.wheels.sqlServerCompatibilityLevels[ds] = 100;
				expect(adapter.$supportsStringSplit(ds)).toBeFalse();
				StructDelete(application.wheels.sqlServerCompatibilityLevels, ds);
				expect(adapter.$supportsStringSplit(ds)).toBeTrue();
			});

		});

	}

}
