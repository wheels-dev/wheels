/**
 * afterCommit / afterRollback model callbacks (v4.2.0).
 * The test runner uses transactionMode="none", so specs pass transaction=
 * explicitly to exercise the commit / rollback / none paths.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;
		// Capability decided once: foreign raw-transaction detection needs IsWithinTransaction()
		// (Lucee/BoxLang). On Adobe CF / RustCFML it is unavailable — those specs skip-with-reason.
		var _foreignDetectable = g.model("tag").$supportsForeignTransactionCheck();

		describe("afterCommit / afterRollback", () => {

			beforeEach(() => {
				request.$acLog = [];
				// Reset the per-request+model foreign-warn guard so warn-once is isolated per spec.
				if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "$txnForeignWarned")) {
					StructDelete(request.wheels, "$txnForeignWarned");
				}
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

			it("the public afterCommit() API registers and honours the on= filter", () => {
				// on=create -> fires on create, NOT on a later update.
				g.model("tag").afterCommit(methods = "recordAfterCommit", on = "create");
				var t = g.model("tag").new(name = "txncb-onfilter");
				t.save(transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(1, "on=create fires for a create");
				request.$acLog = [];
				t.update(name = "txncb-onfilter2", transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(0, "on=create must NOT fire for an update");
			});

			it("nested writes in one outer transaction all fire afterCommit together after the outer commit", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				// invokeWithTransaction(method=...) is Wheels' transaction block: the two
				// nested creates share the outer transaction and fire together on commit.
				g.model("tag").invokeWithTransaction(method = "txnCreateTwoTags", transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(2, "both nested creates fire afterCommit once, after the outer commit");
				expect(request.$acLog[1]).toBe("commit:txncb-nest1");
				expect(request.$acLog[2]).toBe("commit:txncb-nest2");
			});

			it("a nested exception rolls back the outer and fires afterRollback for the enqueued write, then rethrows", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				g.model("tag").$registerCallback(type = "afterRollback", methods = "recordAfterRollback");
				var state = {threw = false};
				try {
					g.model("tag").invokeWithTransaction(method = "txnCreateThenThrow", transaction = "commit");
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeTrue("the nested exception must propagate");
				// no afterCommit (rolled back); afterRollback fires for the enqueued create.
				expect(ArrayLen(request.$acLog)).toBe(1);
				expect(request.$acLog[1]).toBe("rollback:txncb-beforethrow");
			});

			it("a self-vetoed save (afterSave=false) enqueues nothing — neither afterCommit nor afterRollback fires", () => {
				// The op never 'succeeded' ($save returned false), so it never enqueued;
				// the uncommitted insert is rolled back, but afterRollback is reserved for
				// records that DID succeed and were then rolled back by a later failure.
				g.model("tagFalseCallbacks").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				g.model("tagFalseCallbacks").$registerCallback(type = "afterRollback", methods = "recordAfterRollback");
				var t = g.model("tagFalseCallbacks").new(name = "txncb-veto");
				t.save(transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(0, "a self-vetoed save fires neither transaction callback");
				g.model("tagFalseCallbacks").$clearCallbacks(type = "afterCommit");
				g.model("tagFalseCallbacks").$clearCallbacks(type = "afterRollback");
			});

			it("a throwing afterCommit propagates and the commit stands (decision C)", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "callbackThatThrows");
				var state = {threw = false};
				var t = g.model("tag").new(name = "txncb-boom");
				try {
					t.save(transaction = "commit");
				} catch (any e) {
					state.threw = true;
					expect(e.type).toBe("Wheels.TestAfterCommitBoom");
				}
				expect(state.threw).toBeTrue("a throwing afterCommit must propagate");
				// the row is committed (afterCommit runs AFTER commit) — it still exists.
				expect(g.model("tag").count(where = "name = 'txncb-boom'")).toBe(1, "the commit stands");
			});

			it("fires multiple afterCommit callbacks in registration order", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				g.model("tag").$registerCallback(type = "afterCommit", methods = "secondAfterCommit");
				var t = g.model("tag").new(name = "txncb-order");
				t.save(transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(2);
				expect(request.$acLog[1]).toBe("commit:txncb-order");
				expect(request.$acLog[2]).toBe("commit2:txncb-order");
			});

			it("does not leak the queue across sequential transactions (job/CLI-style)", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				var conn = g.model("tag").$hashedConnectionArgs();
				// Three independent committed transactions in one request (as a Job/CLI
				// run performs many): each must resolve + clear its own queue, not accumulate.
				for (var i = 1; i <= 3; i++) {
					var t = g.model("tag").new(name = "txncb-leak" & i);
					t.save(transaction = "commit");
					expect(
						!StructKeyExists(request.wheels, "$txnCallbacks")
						|| !StructKeyExists(request.wheels.$txnCallbacks, conn)
					).toBeTrue("the per-connection queue context must be cleared after each outermost resolve (no leak)");
				}
				expect(ArrayLen(request.$acLog)).toBe(3, "exactly one afterCommit per committed transaction — no accumulation");
			});

			it("a throwing afterRollback on the exception path does not mask the original exception", () => {
				// On the exception-unwinding path an original exception is already propagating;
				// a throwing afterRollback must be logged + swallowed, not replace the original.
				g.model("tag").$registerCallback(type = "afterRollback", methods = "recordRollbackThenThrow");
				var state = {caughtType = ""};
				try {
					g.model("tag").invokeWithTransaction(method = "txnCreateThenThrow", transaction = "commit");
				} catch (any e) {
					state.caughtType = e.type;
				}
				expect(state.caughtType).toBe(
					"Wheels.TestNestedBoom",
					"the original transaction exception must surface, not a throwing afterRollback's exception"
				);
			});

			// --- R1: foreign raw transaction{} detection (capability-guarded) ---

			it("does NOT fire afterCommit for a write inside a raw transaction{} that rolls back [IsWithinTransaction engines]", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				try {
					transaction {
						var t = g.model("tag").new(name = "txncb-foreign-rb");
						t.save(transaction = "commit");
						transaction action="rollback";
					}
				} catch (any e) {
				}
				expect(ArrayLen(request.$acLog)).toBe(
					0,
					"afterCommit must not fire for a write rolled back inside a raw transaction{}"
				);
			}, "", !_foreignDetectable);

			it("does not engage foreign-transaction detection where IsWithinTransaction is unavailable [Adobe/RustCFML]", () => {
				// On engines without IsWithinTransaction, Wheels cannot see a raw transaction{},
				// so it never suppresses the callbacks or writes the foreign-skip warning — the
				// engine's own transaction-nesting semantics decide what fires (not guaranteed,
				// which is why the docs direct users to the Wheels-managed transaction).
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				try {
					transaction {
						var t = g.model("tag").new(name = "txncb-foreign-fb");
						t.save(transaction = "commit");
						transaction action="rollback";
					}
				} catch (any e) {
				}
				expect(
					!StructKeyExists(request, "wheels")
					|| !StructKeyExists(request.wheels, "$txnForeignWarned")
					|| StructCount(request.wheels.$txnForeignWarned) == 0
				).toBeTrue("foreign-skip detection must not engage on engines without IsWithinTransaction");
			}, "", _foreignDetectable);

			it("suppresses BOTH afterCommit and afterRollback inside a raw transaction{} [IsWithinTransaction engines]", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				g.model("tag").$registerCallback(type = "afterRollback", methods = "recordAfterRollback");
				try {
					transaction {
						var t = g.model("tag").new(name = "txncb-foreign-both");
						t.save(transaction = "commit");
						transaction action="rollback";
					}
				} catch (any e) {
				}
				expect(ArrayLen(request.$acLog)).toBe(
					0,
					"neither transaction callback fires when Wheels can't observe the outer outcome"
				);
			}, "", !_foreignDetectable);

			it("warns once per request+model for writes inside a raw transaction{}, not once per write [IsWithinTransaction engines]", () => {
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				try {
					transaction {
						for (var i = 1; i <= 3; i++) {
							var t = g.model("tag").new(name = "txncb-foreign-bulk" & i);
							t.save(transaction = "commit");
						}
						transaction action="rollback";
					}
				} catch (any e) {
				}
				expect(ArrayLen(request.$acLog)).toBe(0, "all three writes suppressed");
				expect(
					StructKeyExists(request, "wheels")
					&& StructKeyExists(request.wheels, "$txnForeignWarned")
					&& StructCount(request.wheels.$txnForeignWarned) == 1
				).toBeTrue("exactly one model warned, once, for three writes");
			}, "", !_foreignDetectable);

		});

	}

}
