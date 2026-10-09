component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		// `where` binds every `column <operator> value`. A comparison between two numbers
		// (1 = 0, 1 = 1) has no column and goes into the SQL unbound; a value that has no column
		// of the model or an included model to bind against, such as one inside a subquery,
		// throws an error that names the condition.

		describe("where with a comparison between two numbers", () => {

			it("matches nothing with 1 = 0 and everything with 1 = 1", () => {
				var all = g.model("post").count(reload = true);
				expect(g.model("post").findAll(where = "1 = 0", returnAs = "query", reload = true).recordCount).toBe(0);
				expect(g.model("post").findAll(where = "1 = 1", returnAs = "query", reload = true).recordCount).toBe(all);
				expect(g.model("post").findAll(where = "1=0", returnAs = "query", reload = true).recordCount).toBe(0);
			})

			it("keeps the bound values of the other conditions in line", () => {
				var first = $firstPost();
				expect(g.model("post").findAll(where = "id = #first.id# AND 1 = 1", returnAs = "query", reload = true).id).toBe(first.id);
				expect(g.model("post").findAll(where = "1 = 1 AND id = #first.id#", returnAs = "query", reload = true).id).toBe(first.id);
				expect(g.model("post").findAll(where = "1 = 0 OR id = #first.id#", returnAs = "query", reload = true).id).toBe(first.id);
				expect(g.model("post").findAll(where = "id = #first.id# AND 1 = 0", returnAs = "query", reload = true).recordCount).toBe(0);
				var byTitle = g.model("post").findAll(where = "1 = 1 AND title = '#first.title#' AND 2 > 1", returnAs = "query", reload = true);
				expect(byTitle.recordCount).toBe(1);
				expect(byTitle.id).toBe(first.id);
			})

			it("leaves a comparison inside a quoted value as text", () => {
				expect(g.model("post").findAll(where = "title = '1 = 0'", returnAs = "query", reload = true).recordCount).toBe(0);
			})

			it("works in count(), updateAll() and deleteAll() too", () => {
				expect(g.model("post").count(where = "1 = 0", reload = true)).toBe(0);
				expect(g.model("post").updateAll(where = "1 = 0", views = 999)).toBe(0);
				expect(g.model("post").deleteAll(where = "1 = 0")).toBe(0);
			})

		});

		describe("where with a value it can't bind", () => {

			it("names the condition when a subquery compares a column with a value", () => {
				var state = {type = "", message = ""};
				try {
					g.model("author").findAll(where = "id IN (SELECT authorid FROM c_o_r_e_posts WHERE views = 5)", returnAs = "query", reload = true);
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
				}
				expect(state.type).toBe("Wheels.UnbindableWhereValue");
				// The parser drops the spaces around an operator it masks.
				expect(state.message).toInclude("WHERE views=?");
			})

			it("still runs a subquery that compares columns only", () => {
				var authors = g.model("author").findAll(
					where = "id IN (SELECT authorid FROM c_o_r_e_posts WHERE c_o_r_e_posts.authorid = c_o_r_e_authors.id)",
					returnAs = "query",
					reload = true
				);
				expect(authors.recordCount).toBeGT(0);
			})

			it("points at subqueries when a later condition names a column the model doesn't have", () => {
				var state = {type = "", detail = ""};
				try {
					g.model("author").findAll(
						where = "id IN (SELECT authorid FROM c_o_r_e_posts WHERE c_o_r_e_posts.authorid = c_o_r_e_authors.id AND views = 5)",
						returnAs = "query",
						reload = true
					);
				} catch (any e) {
					state.type = e.type;
					state.detail = e.extendedInfo;
				}
				expect(state.type).toBe("Wheels.ColumnNotFound");
				expect(state.detail).toInclude("subquery");
				expect(state.detail).toInclude("whereIn()");
			})

		});
	}

	private struct function $firstPost() {
		var posts = g.model("post").findAll(order = "id", maxRows = 1, returnAs = "query", reload = true);
		return {id = posts.id, title = posts.title};
	}

}
