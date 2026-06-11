component extends="wheels.WheelsTest" {

	function run() {

		describe("select= suspicious-item development warning (SEC-21 deprecation window)", () => {

			it("flags parenthesized subqueries as suspicious", () => {
				var m = application.wo.model("post");
				expect(m.$isSuspiciousSelectItem("(SELECT secret FROM users) AS x")).toBeTrue();
			});

			it("flags statement separators and comment markers", () => {
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

			it("warns only in development mode", () => {
				var m = application.wo.model("post");
				var saved = application.wheels.environment;
				application.wheels.environment = "production";
				try {
					expect(m.$warnOnUnvalidatedSelectItem("(SELECT secret FROM users) AS x")).toBeFalse();
				} finally {
					application.wheels.environment = saved;
				}
				expect(m.$warnOnUnvalidatedSelectItem("(SELECT secret FROM users) AS x")).toBeTrue();
			});

			it("still passes the item through unchanged (warn-only, no enforcement)", () => {
				var m = application.wo.model("post");
				var out = m.$createSQLFieldList(
					clause = "select",
					list = "id,(SELECT 1) AS x",
					include = "",
					returnAs = "query"
				);
				expect(out).toInclude("(SELECT 1) AS x");
			});

		});

	}

}
