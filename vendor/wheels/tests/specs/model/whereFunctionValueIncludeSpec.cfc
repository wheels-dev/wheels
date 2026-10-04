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

			it("uses the tbl alias under useIndex, as a bound condition does", () => {
				// Only deleteAll() passes useIndex to the where clause, so check $whereClause directly.
				// author has no soft-delete column; the alias applies only then, as for a bound condition.
				var parts = g.model("author").$whereClause(where = "id = ABS(1)", include = "posts", sql = ["SELECT"], useIndex = {author: "idx_authors_123"});
				var text = "";
				for (var part in parts) {
					if (IsSimpleValue(part)) {
						text &= part & " ";
					}
				}
				expect(ReFindNoCase("tbl\.[^ ]*id[^ ]* = ABS\(1\)", text)).toBeGT(0, text);
			})

			it("writes a calculated property's SQL in place of its name", () => {
				var all = g.model("post").count(reload = true);
				var posts = g.model("post").findAll(include = "author", where = "titleAlias LIKE TRIM('%Title for%')", returnAs = "query", reload = true);
				var sql = g.model("post").findAll(include = "author", where = "titleAlias LIKE TRIM('%Title for%')", returnAs = "sql");
				expect(posts.recordCount).toBe(all);
				expect(sql).toInclude("(title) LIKE TRIM(");
			})

			it("qualifies a condition after a lowercase or mixed-case and/or", () => {
				var lower = g.model("post").findAll(include = "author", where = "title LIKE TRIM('%Title for%') and id = ABS(1)", returnAs = "query", reload = true);
				var mixed = g.model("post").findAll(include = "author", where = "(id = ABS(1) Or id = ABS(2)) And title LIKE TRIM('%Title for%')", returnAs = "query", reload = true);
				expect(lower.recordCount).toBe(1);
				expect(mixed.recordCount).toBe(2);
			})

			it("leaves an expression that doesn't start with a property alone", () => {
				var posts = g.model("post").findAll(include = "author", where = "ABS(c_o_r_e_posts.id) = ABS(1)", returnAs = "query", reload = true);
				expect(posts.recordCount).toBe(1);
			})

		})

	}

}
