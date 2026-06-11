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
				// $warnOnUnvalidatedSelectItem reads get("environment"), which resolves
				// through $appKey(): "$wheels" on a fully-initialized app, plain "wheels"
				// in the core-test harness where application["$wheels"] doesn't exist.
				// Resolve the key dynamically — hard-coding application["$wheels"] throws
				// "key [$wheels] doesn't exist" in the harness. Run both assertions
				// inside try/finally so a non-"development" baseline doesn't break us.
				var m = application.wo.model("post");
				var appKey = m.$appKey();
				var saved = application[appKey].environment;
				try {
					application[appKey].environment = "development";
					expect(m.$warnOnUnvalidatedSelectItem("(SELECT secret FROM users) AS x")).toBeTrue();
					application[appKey].environment = "production";
					expect(m.$warnOnUnvalidatedSelectItem("(SELECT secret FROM users) AS x")).toBeFalse();
				} finally {
					application[appKey].environment = saved;
				}
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
