component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that withAdvisoryLock", () => {

			it("executes callback and returns result", () => {
				local.result = g.model("author").withAdvisoryLock(name="test_lock_1", callback=function() {
					return 42;
				});
				expect(local.result).toBe(42);
			})

			it("releases lock even when callback throws an exception", () => {
				local.exceptionThrown = false;
				try {
					g.model("author").withAdvisoryLock(name="test_lock_2", callback=function() {
						Throw(type="TestException", message="deliberate error");
					});
				} catch (TestException e) {
					local.exceptionThrown = true;
				}
				expect(local.exceptionThrown).toBeTrue();

				// Verify the lock was released by successfully acquiring it again
				local.result = g.model("author").withAdvisoryLock(name="test_lock_2", callback=function() {
					return "reacquired";
				});
				expect(local.result).toBe("reacquired");
			})

			it("accepts a custom timeout argument", () => {
				local.result = g.model("author").withAdvisoryLock(name="test_lock_timeout", timeout=5, callback=function() {
					return "locked";
				});
				expect(local.result).toBe("locked");
			})

			it("safely handles lock names with single quotes", () => {
				// Regression guard: verify lock names are parameterized, not interpolated.
				// On SQLite this is a no-op, but the call must not throw a SQL syntax error
				// regardless of adapter. With proper parameterization, "O'Brien" is fine.
				local.result = g.model("author").withAdvisoryLock(name="O'Brien's lock", callback=function() {
					return "safe";
				});
				expect(local.result).toBe("safe");
			})

		})

		describe("Tests that forUpdate on QueryBuilder", () => {

			it("sets the forUpdate flag in built finder args", () => {
				local.builder = g.model("author").where("firstName", "Per").forUpdate();
				local.args = local.builder.$buildFinderArgs();
				expect(local.args).toHaveKey("$forUpdate");
				expect(local.args.$forUpdate).toBeTrue();
			})

			it("does not set forUpdate flag when not called", () => {
				local.builder = g.model("author").where("firstName", "Per");
				local.args = local.builder.$buildFinderArgs();
				expect(local.args).notToHaveKey("$forUpdate");
			})

			it("works in a QueryBuilder chain with other methods", () => {
				local.builder = g.model("author")
					.where("firstName", "Per")
					.orderBy("lastName")
					.forUpdate()
					.limit(1);
				local.args = local.builder.$buildFinderArgs();
				expect(local.args).toHaveKey("$forUpdate");
				expect(local.args.$forUpdate).toBeTrue();
				expect(local.args).toHaveKey("where");
				expect(local.args).toHaveKey("order");
				expect(local.args).toHaveKey("maxRows");
			})

			it("executes a findAll with forUpdate without error", () => {
				// On SQLite this is a no-op (empty FOR UPDATE clause), but should not throw
				local.result = g.model("author").where("firstName", "Per").forUpdate().get();
				expect(local.result.recordCount).toBeGTE(0);
			})

			it("executes findAll with dollar forUpdate argument without error", () => {
				// Direct findAll with $forUpdate argument
				local.result = g.model("author").findAll(where="firstName = 'Per'", $forUpdate=true);
				expect(local.result.recordCount).toBeGTE(0);
			})

		})

		describe("Tests that adapter forUpdateClause", () => {

			it("returns correct clause for the current adapter", () => {
				local.adapter = g.model("author").$classData().adapter;
				local.adapterName = g.model("author").get("adapterName");
				local.clause = local.adapter.$forUpdateClause();

				if (local.adapterName == "SQLiteModel" || local.adapterName == "MicrosoftSQLServerModel") {
					expect(local.clause).toBe("");
				} else {
					expect(local.clause).toBe("FOR UPDATE");
				}
			})

		})

	}

}
