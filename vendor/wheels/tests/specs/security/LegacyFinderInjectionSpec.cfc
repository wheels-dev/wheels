component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Legacy finder SQL injection prevention", () => {

			// PR #2416 closed the SQL-injection vector in the chainable QueryBuilder by
			// validating typed values before they reach the adapter's $quoteValue. The
			// same root-cause pattern existed in the legacy ORM paths that pre-date the
			// chainable builder — findByKey / updateByKey / deleteByKey (which share the
			// $keyWhereString sink in sql.cfc) and the dynamic finders (findByX /
			// findOneByX / findAllByX) in onmissingmethod.cfc. Adapter-side validation
			// in Base.$quoteValue closes those at the only sink they share.
			//
			// Tracking issue: #2417.

			describe("$keyWhereString — findByKey / updateByKey / deleteByKey", () => {

				it("findByKey rejects tautology injection on integer-keyed model", () => {
					expect(function() {
						g.model("post").findByKey("1 OR 1=1");
					}).toThrow("Wheels.InvalidValue");
				});

				it("findByKey rejects UNION SELECT injection", () => {
					expect(function() {
						g.model("post").findByKey("1 UNION SELECT password FROM c_o_r_e_users");
					}).toThrow("Wheels.InvalidValue");
				});

				it("findByKey rejects comment-truncation injection", () => {
					expect(function() {
						g.model("post").findByKey("1 --");
					}).toThrow("Wheels.InvalidValue");
				});

				it("findByKey rejects stacked-statement injection", () => {
					expect(function() {
						g.model("post").findByKey("1; DROP TABLE c_o_r_e_posts");
					}).toThrow("Wheels.InvalidValue");
				});

				it("updateByKey rejects tautology injection in key", () => {
					expect(function() {
						g.model("post").updateByKey(key = "1 OR 1=1", title = "hijacked");
					}).toThrow("Wheels.InvalidValue");
				});

				it("deleteByKey rejects tautology injection in key", () => {
					expect(function() {
						g.model("post").deleteByKey("1 OR 1=1");
					}).toThrow("Wheels.InvalidValue");
				});

				it("findByKey accepts a legitimate integer key", () => {
					// Should not throw; the row may or may not exist depending on
					// fixtures, but the value-shape gate must let integers through.
					expect(function() {
						g.model("post").findByKey(1);
					}).notToThrow();
				});

				it("findByKey accepts an integer-shaped string key", () => {
					expect(function() {
						g.model("post").findByKey("1");
					}).notToThrow();
				});

				it("findByKey accepts a negative integer key", () => {
					// Negative integers are legitimate per the regex (^-?[0-9]+$).
					// No row will match, but the gate must not throw.
					expect(function() {
						g.model("post").findByKey("-1");
					}).notToThrow();
				});

			});

			describe("dynamic finders — findByX / findOneByX / findAllByX", () => {

				it("findAllByViews rejects tautology injection on integer column", () => {
					expect(function() {
						g.model("post").findAllByViews("0 OR 1=1");
					}).toThrow("Wheels.InvalidValue");
				});

				it("findOneByViews rejects UNION SELECT injection on integer column", () => {
					expect(function() {
						g.model("post").findOneByViews("0 UNION SELECT 1");
					}).toThrow("Wheels.InvalidValue");
				});

				it("findOneByViews rejects comment-truncation on integer column", () => {
					expect(function() {
						g.model("post").findOneByViews("0 --");
					}).toThrow("Wheels.InvalidValue");
				});

				it("findAllByAveragerating rejects injection on float column", () => {
					expect(function() {
						g.model("post").findAllByAveragerating("3.14 OR 1=1");
					}).toThrow("Wheels.InvalidValue");
				});

				it("findAllByViews accepts legitimate integer value", () => {
					expect(function() {
						g.model("post").findAllByViews(0);
					}).notToThrow();
				});

				it("findAllByAveragerating accepts legitimate float value", () => {
					expect(function() {
						g.model("post").findAllByAveragerating(3.14);
					}).notToThrow();
				});

				it("findAllByTitle accepts ordinary string values (string column)", () => {
					// String columns are quoted-and-escaped by the adapter; the
					// numeric/boolean shape gate is skipped for them so legitimate
					// string content (including spaces) passes through.
					expect(function() {
						g.model("post").findAllByTitle("any title here");
					}).notToThrow();
				});

			});

		});

	}

}
