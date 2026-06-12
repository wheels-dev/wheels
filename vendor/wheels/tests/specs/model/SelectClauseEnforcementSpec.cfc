component extends="wheels.WheelsTest" {

	function run() {

		describe("select= validation policy enforcement (SEC-21 hard mode, 5.0)", () => {

			it("flags parenthesized subqueries as suspicious", () => {
				var m = application.wo.model("post");
				expect(m.$isSuspiciousSelectItem("(SELECT secret FROM users) AS x")).toBeTrue();
			});

			it("flags statement separators and comment markers as suspicious", () => {
				var m = application.wo.model("post");
				expect(m.$isSuspiciousSelectItem("users.id; DROP TABLE users")).toBeTrue();
				expect(m.$isSuspiciousSelectItem("users.id -- x")).toBeTrue();
				expect(m.$isSuspiciousSelectItem("users.id /* x */")).toBeTrue();
			});

			it("does not flag legitimate dotted, aliased, and aggregate items", () => {
				var m = application.wo.model("post");
				expect(m.$isSuspiciousSelectItem("c_o_r_e_posts.id")).toBeFalse();
				expect(m.$isSuspiciousSelectItem("firstname AS fn")).toBeFalse();
				expect(m.$isSuspiciousSelectItem("COUNT(id) AS cnt")).toBeFalse();
			});

			it("throws Wheels.InvalidSelectClause for a subquery select item", () => {
				var m = application.wo.model("post");
				expect(() => {
					m.$validateSelectItem(item = "(SELECT secret FROM users) AS x");
				}).toThrow("Wheels.InvalidSelectClause");
			});

			it("throws for statement separators and comment markers", () => {
				var m = application.wo.model("post");
				expect(() => {
					m.$validateSelectItem(item = "users.id; DROP TABLE users");
				}).toThrow("Wheels.InvalidSelectClause");
				expect(() => {
					m.$validateSelectItem(item = "users.id -- x");
				}).toThrow("Wheels.InvalidSelectClause");
				expect(() => {
					m.$validateSelectItem(item = "users.id /* x */");
				}).toThrow("Wheels.InvalidSelectClause");
			});

			it("does not throw for legitimate dotted, aliased, and aggregate items", () => {
				var m = application.wo.model("post");
				// $validateSelectItem returns void on safe input; absence of a thrown
				// error is the assertion. Touch a sentinel afterwards to prove we got here.
				var state = {reached = false};
				m.$validateSelectItem(item = "c_o_r_e_posts.id");
				m.$validateSelectItem(item = "firstname AS fn");
				m.$validateSelectItem(item = "COUNT(id) AS cnt");
				state.reached = true;
				expect(state.reached).toBeTrue();
			});

			it("does not throw for a suspicious item when allowRawSelect=true", () => {
				var m = application.wo.model("post");
				var state = {reached = false};
				m.$validateSelectItem(item = "(SELECT 1) AS x", allowRawSelect = true);
				state.reached = true;
				expect(state.reached).toBeTrue();
			});

			it("rejects a raw-SQL select item from $createSQLFieldList by default", () => {
				var m = application.wo.model("post");
				expect(() => {
					m.$createSQLFieldList(
						clause = "select",
						list = "id,(SELECT 1) AS x",
						include = "",
						returnAs = "query"
					);
				}).toThrow("Wheels.InvalidSelectClause");
			});

			it("passes a raw-SQL select item through $createSQLFieldList when allowRawSelect=true", () => {
				var m = application.wo.model("post");
				var out = m.$createSQLFieldList(
					clause = "select",
					list = "id,(SELECT 1) AS x",
					include = "",
					returnAs = "query",
					allowRawSelect = true
				);
				expect(out).toInclude("(SELECT 1) AS x");
			});

			it("enforces the policy end-to-end through findAll(select=...)", () => {
				var m = application.wo.model("post");
				expect(() => {
					m.findAll(select = "id,(SELECT secret FROM users) AS x");
				}).toThrow("Wheels.InvalidSelectClause");
			});

			it("lets findAll(select=..., allowRawSelect=true) run the audited expression", () => {
				var m = application.wo.model("post");
				// Should not throw the policy error; a plain dotted/aliased subquery
				// alias compiles into the SELECT list and the finder returns rows.
				var rv = m.findAll(select = "id,(SELECT 1) AS rawFlag", allowRawSelect = true);
				expect(IsQuery(rv)).toBeTrue();
			});

		});

	}

}
