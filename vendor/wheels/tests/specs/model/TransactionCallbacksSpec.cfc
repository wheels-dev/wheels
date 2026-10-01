/**
 * afterCommit / afterRollback model callbacks (v4.2.0).
 * The test runner uses transactionMode="none", so specs pass transaction=
 * explicitly to exercise the commit / rollback / none paths.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("afterCommit / afterRollback", () => {

			beforeEach(() => {
				request.$acLog = [];
			});

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "afterCommit");
				g.model("tag").$clearCallbacks(type = "afterRollback");
				// Clean up committed test records so the shared DB count stays stable
				// for other specs (these specs use transaction="commit"/"none", which persist).
				g.model("tag").deleteAll(
					where = "name LIKE 'txncb-%'",
					instantiate = false,
					callbacks = false,
					transaction = "commit"
				);
			});

			it("fires afterCommit after a committed create", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				var t = g.model("tag").new(name = "txncb-create");
				t.save(transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(1, "afterCommit must fire once after a committed create");
				expect(request.$acLog[1]).toBe("commit:txncb-create");
			});

			it("does NOT fire afterCommit when the transaction rolls back", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				var t = g.model("tag").new(name = "txncb-rb");
				t.save(transaction = "rollback");
				expect(ArrayLen(request.$acLog)).toBe(0, "afterCommit must not fire on rollback");
			});

			it("fires afterRollback on rollback, not afterCommit", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				g.model("tag").$registerCallback(type = "afterRollback", methods = "recordAfterRollback");
				var t = g.model("tag").new(name = "txncb-ar");
				t.save(transaction = "rollback");
				expect(ArrayLen(request.$acLog)).toBe(1);
				expect(request.$acLog[1]).toBe("rollback:txncb-ar");
			});

			it("fires afterCommit on a committed update", () => {
				var t = g.model("tag").new(name = "txncb-upd-orig");
				t.save(transaction = "commit");
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				request.$acLog = [];
				t.update(name = "txncb-upd-new", transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(1);
				expect(request.$acLog[1]).toBe("commit:txncb-upd-new");
			});

			it("fires afterCommit on a committed delete", () => {
				var t = g.model("tag").new(name = "txncb-del");
				t.save(transaction = "commit");
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				request.$acLog = [];
				t.delete(transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(1, "afterCommit must fire after a committed delete");
			});

			it("fires afterCommit immediately per-op when there is no transaction (none mode, B1)", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				var t = g.model("tag").new(name = "txncb-none");
				t.save(transaction = "none");
				expect(ArrayLen(request.$acLog)).toBe(1, "afterCommit fires immediately in none mode (B1)");
			});

		});

	}

}
