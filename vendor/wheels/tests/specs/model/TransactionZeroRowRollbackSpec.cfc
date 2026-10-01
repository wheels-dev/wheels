/**
 * A bulk operation (deleteAll/updateAll) that matches ZERO rows returns a numeric
 * count of 0. A 0 count must NOT be mistaken for a failed operation and trigger a
 * rollback. When such an op is nested inside a raw (non-Wheels) transaction{} block,
 * the spurious nested rollback discards the enclosing transaction on Lucee/Adobe,
 * silently losing every other write in it.
 *
 * Found while porting a reference app. Fix: roll back only on a genuine boolean
 * failure or explicit rollback mode, never on a numeric count. See #3944.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("A 0-row bulk op must not roll back the enclosing transaction", () => {

			afterEach(() => {
				g.model("tag").deleteAll(
					where = "name LIKE 'zrr-%'",
					instantiate = false,
					callbacks = false,
					transaction = "commit"
				);
			});

			it("a nested deleteAll matching 0 rows does not discard an enclosing raw transaction", () => {
				transaction {
					g.model("tag").create(name = "zrr-del-keep", transaction = "none");
					// 0 rows match: the 0 count must not be read as a failed op.
					g.model("tag").deleteAll(where = "name = 'zrr-nomatch'", transaction = "commit");
				}
				expect(g.model("tag").count(where = "name = 'zrr-del-keep'")).toBe(
					1,
					"the row created in the same raw transaction must survive a 0-row deleteAll"
				);
			});

			it("a nested updateAll matching 0 rows does not discard an enclosing raw transaction", () => {
				transaction {
					g.model("tag").create(name = "zrr-upd-keep", transaction = "none");
					g.model("tag").updateAll(name = "zrr-upd-x", where = "name = 'zrr-nomatch'", transaction = "commit");
				}
				expect(g.model("tag").count(where = "name = 'zrr-upd-keep'")).toBe(
					1,
					"the row created in the same raw transaction must survive a 0-row updateAll"
				);
			});

			it("a 0-row deleteAll returns 0 and commits without a spurious rollback", () => {
				var deleted = g.model("tag").deleteAll(where = "name = 'zrr-nomatch'", transaction = "commit");
				expect(deleted).toBe(0, "a 0-row deleteAll reports 0 deleted and does not error");
			});

			it("still rolls back a genuine failure (save returning false) in a committed transaction", () => {
				// Guard against over-correction: a real boolean-false failure must still roll back.
				g.model("tagFalseCallbacks").create(name = "zrr-false", transaction = "commit");
				expect(g.model("tagFalseCallbacks").count(where = "name = 'zrr-false'")).toBe(
					0,
					"a save whose afterSave returns false must still roll its own transaction back"
				);
			});
		});
	}

}
