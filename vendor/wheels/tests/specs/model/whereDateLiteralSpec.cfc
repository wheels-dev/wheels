component extends="wheels.WheelsTest" {

	/*
	 * A CFML date interpolated into a where string renders in ODBC escape form,
	 * {ts '2020-01-01 00:00:00'} (also {d '...'} and {t '...'}). The literal masker
	 * read the quote inside {ts '...'} as the end of the surrounding literal, so
	 * the query failed with "invalid hexadecimal String" (#3941). The masker now
	 * binds the inner date value; anything that is not exactly an ODBC date form
	 * keeps the ordinary literal handling.
	 */
	function run() {

		g = application.wo

		describe("where strings with an interpolated CFML date", () => {

			it("finds rows with a quoted {ts} date", () => {
				var since = CreateDateTime(2000, 1, 1, 0, 0, 0)
				var total = g.model("post").count()
				expect(g.model("post").findAll(where = "createdAt >= '#since#'", returnAs = "query").recordCount).toBe(total)
			})

			it("finds rows with an unquoted {ts} date", () => {
				var since = CreateDateTime(2000, 1, 1, 0, 0, 0)
				if (Left("#since#", 4) != "{ts ") {
					// RustCFML renders a date as plain "2000-01-01 00:00:00", so unquoted it is not a literal at all.
					skip("This engine renders dates without the {ts} escape.")
				}
				var total = g.model("post").count()
				expect(g.model("post").findAll(where = "createdAt >= #since#", returnAs = "query").recordCount).toBe(total)
			})

			it("excludes rows with a future {ts} date", () => {
				var future = CreateDateTime(2999, 1, 1, 0, 0, 0)
				expect(g.model("post").findAll(where = "createdAt >= '#future#'", returnAs = "query").recordCount).toBe(0)
			})

			it("masks the inner date of {ts}, {d} and {t} forms as one literal", () => {
				var sentinel = g.model("post").$whereLiteralSentinel()
				for (var odbc in ["{ts '2020-01-02 03:04:05'}", "{d '2020-01-02'}", "{t '03:04:05'}"]) {
					var masked = g.model("post").$maskWhereLiterals("createdAt >= '#odbc#'")
					expect(Find("{", masked)).toBe(0, "no ODBC wrapper left for #odbc#")
					expect(ListLen(masked, "'")).toBe(2, "one literal for #odbc#")
					expect(Find(sentinel, masked)).toBeGT(0)
				}
			})
		})

		describe("dates in positions that aren't bound (BETWEEN, function arguments)", () => {

			// Unbound positions get the date back as the JDBC escape the author wrote, so
			// databases that won't convert a plain string to a date (Oracle) still work. The
			// escapes are written out rather than interpolated: not every engine renders a date
			// in {ts} form (RustCFML gives "2000-01-01 00:00:00").
			it("writes {ts} back for BETWEEN bounds", () => {
				var sql = ArrayToList(g.model("post").$whereClause(where = "createdAt BETWEEN {ts '2000-01-01 00:00:00'} AND {ts '2999-12-31 00:00:00'}", include = "", sql = ["SELECT 1"]).filter((f) => IsSimpleValue(f)), " ")
				expect(Find("{ts '2000-01-01 00:00:00'}", sql)).toBeGT(0, sql)
				expect(Find("{ts '2999-12-31 00:00:00'}", sql)).toBeGT(0, sql)
			})

			it("writes {ts} back for a function argument", () => {
				var sql = ArrayToList(g.model("post").$whereClause(where = "createdAt >= COALESCE({ts '2000-01-01 00:00:00'}, createdAt)", include = "", sql = ["SELECT 1"]).filter((f) => IsSimpleValue(f)), " ")
				expect(Find("{ts '2000-01-01 00:00:00'}", sql)).toBeGT(0, sql)
			})

			it("unmasks a bound ODBC date to its plain value", () => {
				var masked = g.model("post").$maskWhereLiterals("x = {d '2020-01-02'}")
				var inner = ListGetAt(masked, 2, "'")
				var adapter = g.model("post").$classData().adapter
				expect(adapter.$unmaskParameterValue(inner)).toBe("2020-01-02")
			})

			it("finds rows with dates in BETWEEN and in a function argument", () => {
				if (FindNoCase("SQLite", g.get("adapterName"))) {
					skip("The SQLite JDBC driver does not process {ts} escapes.")
				}
				var a = CreateDateTime(2000, 1, 1, 0, 0, 0)
				var b = CreateDateTime(2999, 12, 31, 0, 0, 0)
				var total = g.model("post").count()
				expect(g.model("post").findAll(where = "createdAt BETWEEN #a# AND #b#", returnAs = "query").recordCount).toBe(total)
				expect(g.model("post").findAll(where = "createdAt >= COALESCE(#a#, createdAt)", returnAs = "query").recordCount).toBe(total)
			})
		})

		describe("text that only resembles a {ts} date", () => {

			// Each of these is not exactly an ODBC date form, so it gets the ordinary
			// literal handling: every quoted region is masked and nothing else changes.
			it("keeps the ordinary handling when the inner value is not a date", () => {
				var m = g.model("post")
				var cases = [
					"createdAt >= '{ts ''x'') OR 1=1 --''}'",
					"createdAt >= '{ts ''2020-01-01''}'",
					"createdAt >= '{ts 2020-01-01}'",
					"createdAt >= '{tsx ''2020-01-01''}'"
				]
				for (var c in cases) {
					var masked = m.$maskWhereLiterals(c)
					// the text outside the masked literal is unchanged
					expect(ListFirst(masked, "'")).toBe("createdAt >= ")
					expect(Find(" OR 1=1", masked)).toBe(0)
				}
			})

			it("still rejects an unbalanced quote", () => {
				var callBad = () => {
					g.model("post").$maskWhereLiterals("createdAt >= '{ts '2020-01-01 00:00:00'}")
				}
				expect(callBad).toThrow("Wheels.InvalidWhereClause")
			})
		})
	}

}
