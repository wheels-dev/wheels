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
				// $warnOnUnvalidatedSelectItem reads get("environment"), which on a
				// fully-initialized app resolves through $appKey() == "$wheels" and reads
				// from application.$wheels.environment (see
				// .ai/wheels/cross-engine-compatibility.md § $appKey() Returns "$wheels").
				// Set both scopes so the override takes effect, and run both assertions
				// inside try/finally so a non-"development" baseline doesn't break us.
				var m = application.wo.model("post");
				var saved = application.wheels.environment;
				var savedAppKey = application["$wheels"].environment;
				try {
					application.wheels.environment = "development";
					application["$wheels"].environment = "development";
					expect(m.$warnOnUnvalidatedSelectItem("(SELECT secret FROM users) AS x")).toBeTrue();
					application.wheels.environment = "production";
					application["$wheels"].environment = "production";
					expect(m.$warnOnUnvalidatedSelectItem("(SELECT secret FROM users) AS x")).toBeFalse();
				} finally {
					application.wheels.environment = saved;
					application["$wheels"].environment = savedAppKey;
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
