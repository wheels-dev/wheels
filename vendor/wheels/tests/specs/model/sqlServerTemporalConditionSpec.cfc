/**
 * Date and time conditions on SQL Server compare in the column's own type (#4326, #4327). Every
 * engine binds cf_sql_timestamp as DATETIME2(7), so a value with a fraction never equalled what a
 * DATETIME or SMALLDATETIME column stored, and cf_sql_time errored against a TIME column on Lucee
 * and BoxLang and lost its fraction on Adobe. The model path must now match exactly the rows a
 * comparison in the column's type matches, and leave ranges and DATETIME2 columns as they were.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.ds = variables.g.get("dataSourceName");
		variables.isSqlServer = variables.g.get("adapterName") == "MicrosoftSQLServerModel";
		// dev1-impl's #4318 probe values: whole seconds, fractions DATETIME can't hold, a value that
		// rounds to the next day, and half-minute boundaries SMALLDATETIME rounds differently.
		variables.values = [
			"2026-01-02 10:00:00.000",
			"2026-01-02 10:00:00.003",
			"2026-01-02 10:00:00.123",
			"2026-01-02 10:00:00.999",
			"2026-01-02 23:59:59.997",
			"2026-01-02 23:59:59.999",
			"2026-01-03 00:00:00.000",
			"2026-01-02 10:00:29.000",
			"2026-01-02 10:00:30.000"
		];
		variables.columnTypes = {dt = "DATETIME", sdt = "SMALLDATETIME", dt2 = "DATETIME2(7)", dt23 = "DATETIME2(3)"};
		if (!variables.isSqlServer) {
			return;
		}
		QueryExecute("IF OBJECT_ID('c_o_r_e_temporals') IS NOT NULL DROP TABLE c_o_r_e_temporals", [], {datasource = variables.ds});
		QueryExecute(
			"CREATE TABLE c_o_r_e_temporals (id INT IDENTITY PRIMARY KEY, dt DATETIME, sdt SMALLDATETIME, dt2 DATETIME2(7), dt23 DATETIME2(3), t TIME(7))",
			[],
			{datasource = variables.ds}
		);
		for (var v in variables.values) {
			QueryExecute(
				"INSERT INTO c_o_r_e_temporals (dt, sdt, dt2, dt23, t) VALUES (CAST(? AS DATETIME2(7)), CAST(? AS DATETIME2(7)), CAST(? AS DATETIME2(7)), CAST(? AS DATETIME2(7)), CAST(? AS TIME(7)))",
				[v, v, v, v, ListLast(v, " ")],
				{datasource = variables.ds}
			);
		}
	}

	function afterAll() {
		if (variables.isSqlServer) {
			QueryExecute("IF OBJECT_ID('c_o_r_e_temporals') IS NOT NULL DROP TABLE c_o_r_e_temporals", [], {datasource = variables.ds});
		}
		StructDelete(application.wheels.models, "Temporal");
	}

	// Rows a comparison in `castType` matches: the ground truth for the model path.
	function truthCount(required string column, required string operator, required string castType, required string value) {
		return QueryExecute(
			"SELECT COUNT(*) AS n FROM c_o_r_e_temporals WHERE #arguments.column# #arguments.operator# CAST(? AS #arguments.castType#)",
			[{value = arguments.value, cfsqltype = "cf_sql_varchar"}],
			{datasource = variables.ds}
		).n;
	}

	function run() {

		describe("$temporalComparisonType()", () => {

			it("compares DATETIME, SMALLDATETIME and TIME columns in their own type and leaves the rest", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
				expect(adapter.$temporalComparisonType("datetime")).toBe("DATETIME");
				expect(adapter.$temporalComparisonType("SMALLDATETIME")).toBe("SMALLDATETIME");
				expect(adapter.$temporalComparisonType("time")).toBe("TIME(7)");
				for (var type in ["datetime2", "date", "datetimeoffset", "varchar", "int"]) {
					expect(adapter.$temporalComparisonType(type)).toBe("", type);
				}
			});

			it("casts equality and IN on DATETIME, any comparison on TIME, and no range on DATETIME", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
				for (var op in ["=", "<>", "!=", "IN", "NOT IN", "not  in"]) {
					expect(adapter.$isTemporalCastParam({type = "cf_sql_timestamp", dataType = "datetime", value = "2026-01-02 10:00:00.123", operator = op})).toBeTrue(op);
				}
				for (var op in ["<", "<=", ">", ">=", "LIKE"]) {
					expect(adapter.$isTemporalCastParam({type = "cf_sql_timestamp", dataType = "datetime", value = "2026-01-02 10:00:00.123", operator = op})).toBeFalse(op);
				}
				var t = {type = "cf_sql_time", dataType = "time", value = "10:00:00.123", operator = ">="};
				expect(adapter.$isTemporalCastParam(t)).toBeTrue();
				var dt2 = {type = "cf_sql_timestamp", dataType = "datetime2", value = "2026-01-02 10:00:00.123", operator = "="};
				expect(adapter.$isTemporalCastParam(dt2)).toBeFalse();
				expect(adapter.$isTemporalCastParam({type = "cf_sql_timestamp", dataType = "datetime", value = "", null = true, operator = "="})).toBeFalse();
			});

			it("writes time values as SQL Server TIME text", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
				expect(adapter.$timeText("10:00:00.123")).toBe("10:00:00.123");
				expect(adapter.$timeText("9:05")).toBe("9:05");
				expect(adapter.$timeText("2026-01-02 10:00:00.1234567")).toBe("10:00:00.1234567");
				expect(adapter.$timeText(CreateDateTime(2026, 1, 2, 10, 0, 0))).toBe("10:00:00.000");
				expect(adapter.$timeText("noon")).toBe("noon");
			});

		});

		describe("A condition on a SQL Server date or time column", () => {

			it("matches with = exactly the rows a comparison in the column's type matches", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's DATETIME, SMALLDATETIME and TIME columns.");
				}
				for (var column in variables.columnTypes) {
					for (var v in variables.values) {
						var got = variables.g.model("temporal").count(where = "#column# = '#v#'");
						expect(got).toBe(truthCount(column, "=", variables.columnTypes[column], v), column & " = " & v);
					}
				}
			});

			it("matches fractional values that DATETIME and SMALLDATETIME round", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's DATETIME and SMALLDATETIME columns.");
				}
				expect(variables.g.model("temporal").count(where = "dt = '2026-01-02 10:00:00.123'")).toBe(1);
				expect(variables.g.model("temporal").count(where = "dt = '2026-01-02 10:00:00.003'")).toBe(1);
				// .999 rounds to the next midnight, which two rows hold once stored as DATETIME.
				expect(variables.g.model("temporal").count(where = "dt = '2026-01-02 23:59:59.999'")).toBe(2);
				expect(variables.g.model("temporal").findOneByDt("2026-01-02 10:00:00.123")).toBeWheelsModel();
			});

			it("matches IN and NOT IN lists value by value in the column's type", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's DATETIME columns.");
				}
				var list = ["2026-01-02 10:00:00.003", "2026-01-02 10:00:00.123", "2026-01-02 10:00:00.999"];
				var expected = 0;
				for (var v in list) {
					expected += truthCount("dt", "=", "DATETIME", v);
				}
				expect(variables.g.model("temporal").whereIn("dt", list).count()).toBe(expected);
				expect(variables.g.model("temporal").whereNotIn("dt", list).count()).toBe(ArrayLen(variables.values) - expected);
				expect(variables.g.model("temporal").whereIn("sdt", ["2026-01-02 10:00:29.000"]).count()).toBe(truthCount("sdt", "=", "SMALLDATETIME", "2026-01-02 10:00:29.000"));
			});

			it("keeps ranges on DATETIME exact, as before", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's DATETIME columns.");
				}
				for (var op in [">=", "<", ">", "<="]) {
					for (var v in ["2026-01-02 10:00:00.998", "2026-01-02 10:00:00.124", "2026-01-02 23:59:59.998"]) {
						var got = variables.g.model("temporal").count(where = "dt #op# '#v#'");
						expect(got).toBe(truthCount("dt", op, "DATETIME2(7)", v), "dt " & op & " " & v);
					}
				}
			});

			it("compares TIME columns exactly on every engine, fractions included", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's TIME columns.");
				}
				for (var v in ["10:00:00.000", "10:00:00.123", "10:00:00.999", "23:59:59.997", "10:00:29"]) {
					expect(variables.g.model("temporal").count(where = "t = '#v#'")).toBe(truthCount("t", "=", "TIME(7)", v), "t = " & v);
				}
				expect(variables.g.model("temporal").whereIn("t", ["10:00:00.123", "10:00:00.999"]).count()).toBe(2);
				expect(variables.g.model("temporal").count(where = "t >= '23:00:00'")).toBe(truthCount("t", ">=", "TIME(7)", "23:00:00"));
			});

			// Past the parameter limit the list is split (#4318), and the split compares as TIME(7) too.
			it("runs a TIME list past the parameter limit, matching the same rows", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's TIME columns.");
				}
				var times = ["10:00:00.123", "10:00:00.999"];
				for (var i = 1; i <= 2200; i++) {
					ArrayAppend(times, NumberFormat(Int(i / 3600), "00") & ":" & NumberFormat(Int((i mod 3600) / 60), "00") & ":" & NumberFormat(i mod 60, "00"));
				}
				expect(variables.g.model("temporal").whereIn("t", times).count()).toBe(2);
			});

		});

	}

}
