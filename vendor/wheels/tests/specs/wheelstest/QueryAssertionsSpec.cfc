/**
 * Query assertions for specs (F4): recordQueries(), assertQueries(), assertNoQueries(),
 * assertQueriesMatch() and assertNoQueriesMatch() count the SQL statements the model layer sends
 * while a callback runs. Statements are recorded with a ? for each bound value, never the value.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("Query assertions", () => {

			it("records each statement a callback sends, with ? for its values", () => {
				var queries = recordQueries(() => {
					g.model("author").findOne(where = "lastName = 'Djurner'");
				});
				expect(ArrayLen(queries)).toBe(1);
				expect(queries[1].sql).toInclude("SELECT");
				expect(queries[1].sql).toInclude("?");
				expect(queries[1].sql).notToInclude("Djurner");
				expect(queries[1].dataSource).toBe(g.get("dataSourceName"));
			});

			it("returns the callback's result from assertQueries() and assertNoQueries()", () => {
				var author = assertQueries(1, () => g.model("author").findOne(order = "id"));
				expect(author).toBeWheelsModel();
				var name = assertNoQueries(() => author.firstName);
				expect(name).toBe(author.firstName);
			});

			it("fails with the statements listed, values left out", () => {
				var state = {message = ""};
				try {
					assertQueries(2, () => g.model("author").findAll(where = "lastName = 'F4-secret-value'"));
				} catch (any e) {
					state.message = e.message;
				}
				expect(state.message).toInclude("Expected 2 queries, ran 1.");
				expect(state.message).toInclude("[1] SELECT");
				expect(state.message).notToInclude("F4-secret-value");
			});

			it("matches statements against a pattern, or finds none", () => {
				// author: no spec registers callbacks on it, so the create's INSERT always runs.
				var created = assertQueriesMatch("^INSERT", () => g.model("author").create(firstName = "F4", lastName = "Insert", transaction = "rollback"));
				expect(created.hasErrors()).toBeFalse();
				assertQueriesMatch("FROM", () => g.model("author").findAll(), 1);
				assertNoQueriesMatch("c_o_r_e_comments", () => g.model("author").findAll());
				var state = {message = ""};
				try {
					assertNoQueriesMatch("c_o_r_e_authors", () => g.model("author").findAll());
				} catch (any e) {
					state.message = e.message;
				}
				expect(state.message).toInclude("Expected 0 queries matching");
			});

			it("counts its own window when nested in another recorder", () => {
				var inner = {count = -1};
				var outer = recordQueries(() => {
					g.model("author").findOne(order = "id");
					inner.count = ArrayLen(recordQueries(() => g.model("post").findOne(order = "id")));
					assertQueries(1, () => g.model("author").count());
				});
				expect(inner.count).toBe(1);
				expect(ArrayLen(outer)).toBe(3, "the outer recorder sees every statement in its window");
			});

			it("takes its recorder off when the callback throws", () => {
				var before = (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "$queryRecorders")) ? ArrayLen(request.wheels.$queryRecorders) : 0;
				var state = {threw = false};
				try {
					recordQueries(() => {
						g.model("author").findOne(order = "id");
						Throw(type = "Wheels.F4SpecBoom", message = "boom");
					});
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeTrue();
				expect(ArrayLen(request.wheels.$queryRecorders)).toBe(before);
				expect(ArrayLen(recordQueries(() => g.model("author").findOne(order = "id")))).toBe(1);
			});

			it("filters by datasource", () => {
				var ds = g.get("dataSourceName");
				expect(ArrayLen(recordQueries(() => g.model("author").findOne(order = "id"), ds))).toBe(1);
				expect(ArrayLen(recordQueries(() => g.model("author").findOne(order = "id"), "wheels_f4_other_ds"))).toBe(0);
				assertNoQueries(() => g.model("author").findOne(order = "id"), "wheels_f4_other_ds");
			});

			it("records nothing while no recorder is active", () => {
				g.model("author").findOne(order = "id");
				expect(
					!StructKeyExists(request, "wheels")
					|| !StructKeyExists(request.wheels, "$queryRecorders")
					|| !ArrayLen(request.wheels.$queryRecorders)
				).toBeTrue();
			});

		});

	}

}
