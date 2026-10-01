component extends="wheels.WheelsTest" {

	/*
	 * A CFML date interpolated into a where string renders in ODBC escape form,
	 * {ts '2020-01-01 00:00:00'} (also {d '...'} and {t '...'}). The literal masker
	 * read the quote inside {ts '...'} as the end of the surrounding literal, so
	 * the query failed with "invalid hexadecimal String" (#ISSUE). The masker now
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
