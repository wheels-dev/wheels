/**
 * Date and timestamp IN lists past SQL Server's parameter limit (#4318). A long list binds as one
 * STRING_SPLIT parameter cast to the type the driver binds each value as (datetime2(7) for a
 * timestamp, date for a date), so it matches exactly the rows the same list matches bound one
 * parameter per value. Time lists, and dates written in other forms, keep Wheels.TooManyParameters.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.isSqlServer = variables.g.get("adapterName") == "MicrosoftSQLServerModel";
		variables.mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
		// Stored values: whole and fractional seconds, the last ticks of a day, midnight, and
		// the seconds either side of SMALLDATETIME's rounding point.
		variables.stored = [
			"2026-01-02T10:00:00.000",
			"2026-01-02T10:00:00.003",
			"2026-01-02T10:00:00.123",
			"2026-01-02T10:00:00.999",
			"2026-01-02T23:59:59.997",
			"2026-01-02T23:59:59.999",
			"2026-01-03T00:00:00.000",
			"2026-01-02T10:00:29.000",
			"2026-01-02T10:00:30.000"
		];
		variables.columns = "d,dt,sdt,dt2,dt23,dto";
		if (variables.isSqlServer) {
			var ds = variables.g.get("dataSourceName");
			QueryExecute("IF OBJECT_ID('c_o_r_e_dtsplits') IS NOT NULL DROP TABLE c_o_r_e_dtsplits", [], {datasource = ds});
			QueryExecute(
				"CREATE TABLE c_o_r_e_dtsplits (id INT IDENTITY PRIMARY KEY, d DATE, t TIME(7), dt DATETIME, sdt SMALLDATETIME, dt2 DATETIME2(7), dt23 DATETIME2(3), dto DATETIMEOFFSET(7))",
				[],
				{datasource = ds}
			);
			for (var v in variables.stored) {
				var c = "CAST('#v#' AS DATETIME2(7))";
				QueryExecute(
					"INSERT INTO c_o_r_e_dtsplits (d, t, dt, sdt, dt2, dt23, dto) VALUES (#c#, #c#, #c#, #c#, #c#, #c#, #c#)",
					[],
					{datasource = ds}
				);
			}
			// a row of NULLs, which neither IN nor NOT IN matches
			QueryExecute("INSERT INTO c_o_r_e_dtsplits (d) VALUES (NULL)", [], {datasource = ds});
			StructDelete(application.wheels.models, "DtSplit");
		}
	}

	function afterAll() {
		if (variables.isSqlServer) {
			adapterOf().$setInListSplitLimit(0);
			QueryExecute("DROP TABLE c_o_r_e_dtsplits", [], {datasource = variables.g.get("dataSourceName")});
		}
		StructDelete(application.wheels.models, "DtSplit");
	}

	function adapterOf() {
		return variables.g.model("dtSplit").$classData().adapter;
	}

	function listPart(required string type, required string value) {
		return {type = arguments.type, value = arguments.value, list = true};
	}

	// The ids a call returns, as a sorted list, or its error type.
	function idsOf(required any callback) {
		var target = arguments.callback;
		try {
			var q = target();
			return ListSort(ValueList(q.id), "numeric");
		} catch (any e) {
			return "ERROR " & e.type;
		}
	}

	// Every stored value written the way an app would pass it for `column`, plus values that match
	// nothing, so each list has more than the forced split limit.
	function listFor(required string column) {
		var rv = [];
		for (var v in variables.stored) {
			if (arguments.column == "d") {
				ArrayAppend(rv, Left(v, 10));
			} else {
				ArrayAppend(rv, Replace(v, "T", " "));
			}
		}
		ArrayAppend(rv, arguments.column == "d" ? "1999-12-31" : "1999-12-31 08:15:00");
		ArrayAppend(rv, arguments.column == "d" ? "2026-01-04" : "2026-01-02 10:00");
		return rv;
	}

	// `list` padded past SQL Server's parameter limit with values that match no row, so the
	// statement only runs if the list is split.
	function padded(required array list, required string column) {
		var rv = Duplicate(arguments.list);
		var base = CreateDateTime(1900, 1, 1, 0, 0, 0);
		for (var i = 1; i <= 2150; i++) {
			if (arguments.column == "d") {
				ArrayAppend(rv, DateFormat(DateAdd("d", i, base), "yyyy-mm-dd"));
			} else {
				var stamp = DateAdd("n", i, base);
				ArrayAppend(rv, DateFormat(stamp, "yyyy-mm-dd") & " " & TimeFormat(stamp, "HH:mm:ss"));
			}
		}
		return rv;
	}

	// The same queries, one parameter per value (the default) and split (forced with a low limit).
	function bothWays(required any callback) {
		var target = arguments.callback;
		adapterOf().$setInListSplitLimit(0);
		var normal = idsOf(target);
		adapterOf().$setInListSplitLimit(1);
		try {
			var split = idsOf(target);
		} finally {
			adapterOf().$setInListSplitLimit(0);
		}
		return {normal = normal, split = split};
	}

	function run() {

		describe("The STRING_SPLIT form of a date or timestamp IN list", () => {

			it("normalises each value to an unambiguous ISO form", () => {
				expect(variables.mssql.$isoDateTimeValue(value = "2026-01-02 10:00:00.123", dateOnly = false)).toBe("2026-01-02T10:00:00.123");
				expect(variables.mssql.$isoDateTimeValue(value = " 2026-01-02T10:00 ", dateOnly = false)).toBe("2026-01-02T10:00:00.000");
				expect(variables.mssql.$isoDateTimeValue(value = "2026-01-02", dateOnly = false)).toBe("2026-01-02T00:00:00.000");
				expect(variables.mssql.$isoDateTimeValue(value = "{ts '2026-01-02 23:59:59'}", dateOnly = false)).toBe("2026-01-02T23:59:59.000");
				expect(variables.mssql.$isoDateTimeValue(value = "2026-01-02", dateOnly = true)).toBe("2026-01-02");
				expect(variables.mssql.$isoDateTimeValue(value = "{d '2026-01-02'}", dateOnly = true)).toBe("2026-01-02");
			});

			it("leaves other forms to the one-parameter-per-value path", () => {
				var refused = [
					"01/02/2026",
					"2026-01-02T10:00:00Z",
					"2026-01-02 10:00:00+02:00",
					"2026-01-02 10:00:00.1",
					"2026-02-30",
					"2026-01-02 24:00:00",
					"2026-1-2",
					"January 2, 2026",
					""
				];
				for (var v in refused) {
					expect(variables.mssql.$isoDateTimeValue(value = v, dateOnly = false)).toBe("", "accepted [#v#]");
				}
				expect(variables.mssql.$isoDateTimeValue(value = "2026-01-02 10:00:00", dateOnly = true)).toBe("");
			});

			it("casts to the type the driver binds, only for the bind types it mirrors", () => {
				var casts = variables.mssql.$dateCastsFor({cf_sql_timestamp = "datetime2/7", cf_sql_date = "date/0"});
				expect(casts.cf_sql_timestamp).toBe("DATETIME2(7)");
				expect(casts.cf_sql_date).toBe("DATE");
				expect(StructIsEmpty(variables.mssql.$dateCastsFor({cf_sql_timestamp = "datetime/3", cf_sql_date = "datetime/3"}))).toBeTrue();
				expect(StructIsEmpty(variables.mssql.$dateCastsFor({}))).toBeTrue();
				var split = variables.mssql.$stringSplitList(part = listPart("cf_sql_timestamp", "'2026-01-02 10:00:00.123','2026-01-03'"), dateCasts = casts);
				expect(split.expression).toBe("CAST(value AS DATETIME2(7))");
				expect(split.values).toBe(["2026-01-02T10:00:00.123", "2026-01-03T00:00:00.000"]);
				expect(variables.mssql.$stringSplitList(part = listPart("CF_SQL_DATE", "2026-01-02"), dateCasts = casts).expression).toBe("CAST(value AS DATE)");
			});

			it("isn't used for times, without a known bind type, or when any value is in another form", () => {
				var casts = {cf_sql_timestamp = "DATETIME2(7)", cf_sql_date = "DATE"};
				expect(StructIsEmpty(variables.mssql.$stringSplitList(part = listPart("cf_sql_time", "10:00:00,11:00:00"), dateCasts = casts))).toBeTrue();
				expect(StructIsEmpty(variables.mssql.$stringSplitList(part = listPart("cf_sql_timestamp", "2026-01-02,2026-01-03")))).toBeTrue();
				expect(StructIsEmpty(variables.mssql.$stringSplitList(part = listPart("cf_sql_timestamp", "2026-01-02,01/03/2026"), dateCasts = casts))).toBeTrue();
			});

			it("reads the driver's bind types once per datasource", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server only.");
				}
				var ds = variables.g.get("dataSourceName");
				if (StructKeyExists(application.wheels, "sqlServerDateBindTypes")) {
					StructDelete(application.wheels.sqlServerDateBindTypes, ds);
				}
				var casts = adapterOf().$stringSplitDateCasts(ds);
				// every engine on the CI matrix binds these types; the split form mirrors them
				expect(application.wheels.sqlServerDateBindTypes[ds].cf_sql_timestamp).toBe("datetime2/7");
				expect(application.wheels.sqlServerDateBindTypes[ds].cf_sql_date).toBe("date/0");
				expect(casts.cf_sql_timestamp).toBe("DATETIME2(7)");
				application.wheels.sqlServerDateBindTypes[ds] = {cf_sql_timestamp = "datetime/3"};
				expect(StructIsEmpty(adapterOf().$stringSplitDateCasts(ds))).toBeTrue();
				StructDelete(application.wheels.sqlServerDateBindTypes, ds);
				expect(adapterOf().$stringSplitDateCasts(ds).cf_sql_date).toBe("DATE");
			});

		});

		describe("Date and timestamp IN lists past SQL Server's parameter limit", () => {

			afterEach(() => {
				if (variables.isSqlServer) {
					adapterOf().$setInListSplitLimit(0);
				}
			});

			// The same list must match the same rows whether bound one parameter per value or
			// split, for every date and timestamp column type, including where the one-parameter
			// path misses values the column can't hold exactly (DATETIME, SMALLDATETIME).
			it("returns the same rows split as bound one parameter per value, for each column type", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				for (var col in ListToArray(variables.columns)) {
					var values = listFor(col);
					var longList = padded(values, col);
					// whereIn / whereNotIn: the short list runs one parameter per value; the same
					// list padded past the limit can only run split
					var inShort = idsOf(() => variables.g.model("dtSplit").whereIn(col, values).get(select = "id", returnAs = "query"));
					var inLong = idsOf(() => variables.g.model("dtSplit").whereIn(col, longList).get(select = "id", returnAs = "query"));
					var notInShort = idsOf(() => variables.g.model("dtSplit").whereNotIn(col, values).get(select = "id", returnAs = "query"));
					var notInLong = idsOf(() => variables.g.model("dtSplit").whereNotIn(col, longList).get(select = "id", returnAs = "query"));
					// a where-string IN list, split by a low limit
					var quoted = "'" & ArrayToList(values, "','") & "'";
					var whereString = bothWays(() => variables.g.model("dtSplit").findAll(select = "id", where = "#col# IN (#quoted#)", returnAs = "query"));
					expect(inShort).notToInclude("ERROR", "whereIn on #col#");
					expect(inLong).toBe(inShort, "whereIn on #col#");
					expect(notInLong).toBe(notInShort, "whereNotIn on #col#");
					expect(whereString.split).toBe(whereString.normal, "where IN on #col#");
				}
			});

			it("matches date objects the same way split", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				var dates = [CreateDateTime(2026, 1, 2, 10, 0, 0), CreateDateTime(2026, 1, 3, 0, 0, 0), CreateDateTime(1999, 12, 31, 8, 0, 0)];
				var longList = Duplicate(dates);
				for (var i = 1; i <= 2150; i++) {
					ArrayAppend(longList, DateAdd("n", i, CreateDateTime(1900, 1, 1, 0, 0, 0)));
				}
				var shortIds = idsOf(() => variables.g.model("dtSplit").whereIn("dt2", dates).get(select = "id", returnAs = "query"));
				expect(ListLen(shortIds)).toBe(2);
				expect(idsOf(() => variables.g.model("dtSplit").whereIn("dt2", longList).get(select = "id", returnAs = "query"))).toBe(shortIds);
			});

			it("runs a timestamp list far past the limit", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				var values = [];
				for (var i = 1; i <= 2500; i++) {
					ArrayAppend(values, DateFormat(DateAdd("d", i, CreateDate(2000, 1, 1)), "yyyy-mm-dd") & " 10:00:00");
				}
				ArrayAppend(values, "2026-01-02 10:00:00.123");
				expect(variables.g.model("dtSplit").whereIn("dt2", values).count()).toBe(1);
				expect(variables.g.model("dtSplit").whereNotIn("dt2", values).count()).toBe(ArrayLen(variables.stored) - 1);
			});

			it("keeps Wheels.TooManyParameters for a time list, or dates in another form, past the limit", () => {
				if (!variables.isSqlServer) {
					skip("SQL Server's parameter limit.");
				}
				var times = [];
				var localDates = [];
				for (var i = 1; i <= 2200; i++) {
					ArrayAppend(times, TimeFormat(DateAdd("s", i, CreateDateTime(2026, 1, 2, 0, 0, 0)), "HH:mm:ss"));
					ArrayAppend(localDates, DateFormat(DateAdd("d", i, CreateDate(2000, 1, 1)), "mm/dd/yyyy"));
				}
				var timeError = "";
				try {
					variables.g.model("dtSplit").whereIn("t", times).count();
				} catch (any e) {
					timeError = e.type;
				}
				var dateError = "";
				try {
					variables.g.model("dtSplit").whereIn("dt2", localDates).count();
				} catch (any e) {
					dateError = e.type;
				}
				expect(timeError).toBe("Wheels.TooManyParameters");
				expect(dateError).toBe("Wheels.TooManyParameters");
			});

		});

	}

}
