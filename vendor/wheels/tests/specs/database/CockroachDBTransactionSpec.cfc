component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("CockroachDB Transaction Tests", () => {

			// Guard: only run when connected to CockroachDB
			var migration = CreateObject("component", "wheels.migrator.Migration").init();
			if (migration.adapter.adapterName() != "CockroachDB") return;

			describe("Basic transactions", () => {

				it("commit persists data", () => {
					transaction action="begin" {
						var author = g.model("author").create(firstName = "TxCommit", lastName = "Test");
						expect(author.key()).toBeNumeric();
						transaction action="rollback";
					}
				});

				it("rollback reverts data", () => {
					var beforeCount = g.model("author").count();
					transaction action="begin" {
						g.model("author").create(firstName = "TxRollback", lastName = "Test");
						transaction action="rollback";
					}
					var afterCount = g.model("author").count();
					expect(afterCount).toBe(beforeCount);
				});
			});

			describe("invokeWithTransaction", () => {

				it("create with rollback does not persist", () => {
					var beforeCount = g.model("tag").count();
					g.model("tag").create(name = "CRDBTxTest", transaction = "rollback");
					var afterCount = g.model("tag").count();
					expect(afterCount).toBe(beforeCount);
				});

				it("deleteAll with rollback does not remove records", () => {
					var beforeCount = g.model("tag").count();
					g.model("tag").deleteAll(transaction = "rollback");
					var afterCount = g.model("tag").count();
					expect(afterCount).toBe(beforeCount);
				});

				it("updateAll with rollback does not persist changes", () => {
					// The isolation level must be declared here even though this
					// outer transaction does not otherwise need one. updateAll's
					// transaction="rollback" routes through invokeWithTransaction,
					// which opens its own cftransaction with isolation="read_committed"
					// — and Adobe rejects a nested cftransaction whose isolation
					// level differs from its parent's ("Nested cftransaction tag
					// should specify same isolation level as the parent"). Lucee and
					// BoxLang do not enforce that, so an undeclared parent only fails
					// on the two Adobe legs of the matrix (#3302).
					transaction action="begin" isolation="read_committed" {
						g.model("tag").updateAll(name = "CRDBTemp", transaction = "rollback");
						var changed = g.model("tag").findAll(where = "name = 'CRDBTemp'");
						expect(changed.recordCount).toBe(0);
						transaction action="rollback";
					}
				});
			});
		});
	}

}
