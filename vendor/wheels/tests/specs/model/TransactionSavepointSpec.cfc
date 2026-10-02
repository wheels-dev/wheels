/**
 * transaction="savepoint": a nested unit inside an open transaction rolls back
 * only its own writes; the outer transaction keeps its earlier writes and
 * resolves on its own outcome (#3958). The fixtures live on the Tag model.
 * The test runner uses transactionMode="none", so specs pass transaction=
 * explicitly.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("Savepoint units", () => {

			beforeEach(() => {
				request.$acLog = [];
				request.$spCaught = false;
			});

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "afterCommit");
				g.model("tag").$clearCallbacks(type = "afterRollback");
				g.model("tag").deleteAll(
					where = "name LIKE 'sp-%'",
					instantiate = false,
					callbacks = false,
					transaction = "commit"
				);
			});

			it("rolls back a failing unit and keeps the outer transaction's writes", () => {
				var rv = g.model("tag").invokeWithTransaction(method = "txnOuterThenFailingUnit", transaction = "commit");
				expect(rv).toBeTrue();
				expect(g.model("tag").count(where = "name = 'sp-outer1'")).toBe(1);
				expect(g.model("tag").count(where = "name = 'sp-outer2'")).toBe(1);
				expect(g.model("tag").count(where = "name = 'sp-unit'")).toBe(0);
			});

			it("works when the unit is the first database work in the outer transaction", () => {
				var rv = g.model("tag").invokeWithTransaction(method = "txnFailingUnitFirst", transaction = "commit");
				expect(rv).toBeTrue();
				expect(g.model("tag").count(where = "name = 'sp-unit'")).toBe(0);
				expect(g.model("tag").count(where = "name = 'sp-after'")).toBe(1);
			});

			it("rethrows from a throwing unit after rolling back only its writes", () => {
				var rv = g.model("tag").invokeWithTransaction(method = "txnOuterCatchesThrowingUnit", transaction = "commit");
				expect(rv).toBeTrue();
				expect(request.$spCaught).toBeTrue("the outer method must see the unit's exception");
				expect(g.model("tag").count(where = "name = 'sp-outer1'")).toBe(1);
				expect(g.model("tag").count(where = "name = 'sp-unit-throw'")).toBe(0);
			});

			it("behaves like commit when no transaction is open", () => {
				expect(g.model("tag").invokeWithTransaction(method = "txnUnitCreateThenFalse", transaction = "savepoint")).toBeFalse();
				expect(g.model("tag").count(where = "name = 'sp-unit'")).toBe(0);
				expect(g.model("tag").invokeWithTransaction(method = "txnUnitCreateOk", transaction = "savepoint")).toBeTrue();
				expect(g.model("tag").count(where = "name = 'sp-unit-ok'")).toBe(1);
			});

			it("rolls back only the failing one of two sibling units", () => {
				g.model("tag").invokeWithTransaction(method = "txnSiblingUnits", transaction = "commit");
				expect(g.model("tag").count(where = "name = 'sp-unit'")).toBe(0);
				expect(g.model("tag").count(where = "name = 'sp-unit-ok'")).toBe(1);
			});

			it("rolls back an inner unit nested in another unit without touching the outer unit", () => {
				g.model("tag").invokeWithTransaction(method = "txnNestedUnits", transaction = "commit");
				expect(g.model("tag").count(where = "name = 'sp-level1'")).toBe(1);
				expect(g.model("tag").count(where = "name = 'sp-unit'")).toBe(0);
			});

			it("flows through the transaction argument of create", () => {
				g.model("tag").invokeWithTransaction(method = "txnOuterWithSavepointCreate", transaction = "commit");
				expect(g.model("tag").count(where = "name = 'sp-crud'")).toBe(1);
			});

			it("fires afterRollback for the unit's records and afterCommit for the outer records", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				g.model("tag").$registerCallback(type = "afterRollback", methods = "recordAfterRollback");
				g.model("tag").invokeWithTransaction(method = "txnOuterThenFailingUnit", transaction = "commit");
				var log = ArrayToList(request.$acLog);
				expect(ListFind(log, "rollback:sp-unit")).toBeGT(0, log);
				expect(ListFind(log, "commit:sp-unit")).toBe(0, log);
				expect(ListFind(log, "commit:sp-outer1")).toBeGT(0, log);
				expect(ListFind(log, "commit:sp-outer2")).toBeGT(0, log);
				// The unit's afterRollback fires when the unit rolls back, before the outer commit.
				expect(ListFind(log, "rollback:sp-unit")).toBeLT(ListFind(log, "commit:sp-outer1"), log);
			});

			it("nests inside a raw transaction block on engines that can detect one", () => {
				if (!g.model("tag").$supportsForeignTransactionCheck()) {
					skip("A raw transaction{} block is not detectable on this engine (RustCFML).");
				}
				transaction {
					g.model("tag").create(name = "sp-outer1", transaction = "none");
					g.model("tag").invokeWithTransaction(method = "txnUnitCreateThenFalse", transaction = "savepoint");
				}
				expect(g.model("tag").count(where = "name = 'sp-outer1'")).toBe(1);
				expect(g.model("tag").count(where = "name = 'sp-unit'")).toBe(0);
			});

			it("does not let a failing savepoint rollback replace the original exception", () => {
				// The quiet rollback is what the throw path calls; a rollback to a
				// savepoint that does not exist fails, and must not throw.
				var state = {threw = false};
				transaction {
					try {
						g.model("tag").$rollbackToSavepointQuietly(
							name = "wsp_does_not_exist",
							connection = g.model("tag").$hashedConnectionArgs(),
							mark = -1
						);
					} catch (any e) {
						state.threw = true;
					}
					transaction action="rollback";
				}
				expect(state.threw).toBeFalse();
			});

			it("still rejects an unknown transaction mode", () => {
				var state = {type = ""};
				try {
					g.model("tag").invokeWithTransaction(method = "txnUnitCreateOk", transaction = "nested");
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels");
				expect(g.model("tag").count(where = "name = 'sp-unit-ok'")).toBe(0);
			});

		});

	}

}
