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
					transaction action="begin" {
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
