component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		// A condition whose left side is a function call and whose right side is a
		// value the WHERE parser binds as a parameter.

		describe("Where conditions with a function call compared with a bound value", () => {

			it("compares with a number", () => {
				var first = $firstPost();
				var posts = g.model("post").findAll(where = "ABS(id) = #first.id#", returnAs = "query", reload = true);
				expect(posts.recordCount).toBe(1);
				expect(posts.id).toBe(first.id);
			})

			it("compares with a quoted string", () => {
				var first = $firstPost();
				var posts = g.model("post").findAll(where = "UPPER(title) = '#UCase(first.title)#'", returnAs = "query", reload = true);
				expect(posts.recordCount).toBe(1);
				expect(posts.id).toBe(first.id);
			})

			it("compares with NULL", () => {
				var all = g.model("post").count(reload = true);
				var none = g.model("post").findAll(where = "UPPER(title) IS NULL", returnAs = "query", reload = true);
				var some = g.model("post").findAll(where = "UPPER(title) IS NOT NULL", returnAs = "query", reload = true);
				expect(none.recordCount).toBe(0);
				expect(some.recordCount).toBe(all);
			})

			it("keeps the other conditions in the clause", () => {
				var first = $firstPost();
				var posts = g.model("post").findAll(where = "ABS(id) = #first.id# AND title = '#first.title#'", returnAs = "query", reload = true);
				var none = g.model("post").findAll(where = "(ABS(id) = #first.id#) AND title = 'zznope'", returnAs = "query", reload = true);
				expect(posts.recordCount).toBe(1);
				expect(none.recordCount).toBe(0);
			})

			it("works under include", () => {
				var first = $firstPost();
				var posts = g.model("post").findAll(include = "author", where = "ABS(c_o_r_e_posts.id) = #first.id#", returnAs = "query", reload = true);
				expect(posts.recordCount).toBe(1);
			})

		})

	}

	public query function $firstPost() {
		return g.model("post").findAll(select = "id,title", order = "id", maxRows = 1, returnAs = "query", reload = true);
	}

}
