component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		// With include, a column that two joined tables share must be qualified
		// with its table. Conditions whose value is a bound parameter always were;
		// these compare a column with a function call instead.

		describe("Where conditions with a function-call value under include", () => {

			it("qualifies a shared column compared with a function call", () => {
				var posts = g.model("post").findAll(include = "author", where = "id = ABS(1)", returnAs = "query", reload = true);
				expect(posts.recordCount).toBe(1);
			})

			it("qualifies a shared column when the function wraps a quoted value", () => {
				var posts = g.model("post").findAll(include = "author", where = "id = ABS(CAST('1' AS DECIMAL))", returnAs = "query", reload = true);
				expect(posts.recordCount).toBe(1);
			})

			it("qualifies each such condition, after AND/OR and inside parentheses", () => {
				var posts = g.model("post").findAll(
					include = "author",
					where = "(id = ABS(1) OR id = ABS(2)) AND title LIKE TRIM('%Title for%')",
					returnAs = "query",
					reload = true
				);
				expect(posts.recordCount).toBe(2);
			})

			it("leaves an expression that doesn't start with a property alone", () => {
				var posts = g.model("post").findAll(include = "author", where = "ABS(c_o_r_e_posts.id) = ABS(1)", returnAs = "query", reload = true);
				expect(posts.recordCount).toBe(1);
			})

		})

	}

}
