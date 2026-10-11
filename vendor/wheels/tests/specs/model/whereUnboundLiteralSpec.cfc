component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		// `where` binds every `column <operator> value`, and the column must belong to the model or
		// an included model. A condition with no column (1 = 0) isn't supported, and a value with no
		// column to bind against, such as one inside a subquery, throws an error naming the condition.

		describe("where with a condition that has no column", () => {

			it("says 1 = 0 isn't supported, and what to use instead", () => {
				var state = {type = "", detail = ""};
				try {
					g.model("post").findAll(where = "1 = 0", returnAs = "query", reload = true);
				} catch (any e) {
					state.type = e.type;
					state.detail = e.extendedInfo;
				}
				expect(state.type).toBe("Wheels.ColumnNotFound");
				expect(state.detail).toInclude("isn't supported");
				expect(state.detail).toInclude("whereIn() with an empty array");
			})

			it("returns no rows for whereIn() with an empty array, the suggested alternative", () => {
				expect(g.model("post").whereIn("id", []).count()).toBe(0);
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

			it("hides quoted values in the error, including a quoted literal elsewhere in the subquery", () => {
				var state = {type = "", message = ""};
				try {
					g.model("author").findAll(
						where = "id IN (SELECT COALESCE(authorid, LENGTH('private_marker_x')) FROM c_o_r_e_posts WHERE views = 5 AND title = 'private_title_y')",
						returnAs = "query",
						reload = true
					);
				} catch (any e) {
					state.type = e.type;
					state.message = e.message & " " & e.extendedInfo;
				}
				expect(state.type).toBe("Wheels.UnbindableWhereValue");
				expect(state.message).toInclude("'...'");
				for (var secret in ["private_marker_x", "private_title_y"]) {
					expect(state.message).notToInclude(secret);
					expect(state.message).notToInclude(LCase(BinaryEncode(CharsetDecode(secret, "utf-8"), "hex")));
				}
				expect(state.message).notToInclude("wmask");
				expect(Find(Chr(2), state.message)).toBe(0);
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

}
