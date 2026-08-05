/**
 * A failure to OPEN a transaction must not leave the connection marked as
 * "transaction already open" (#3302).
 *
 * `invokeWithTransaction()` sets `request.wheels.transactions[connectionArgs]`
 * to true *before* it opens the `cftransaction`, and the tag itself sits
 * outside the try/catch that resets the marker. So when the begin tag threw —
 * an unsupported isolation level, Adobe's nested-isolation-mismatch rule, a
 * dead connection — the marker stayed true and every subsequent
 * `invokeWithTransaction` in the same request took the "alreadyopen" branch
 * and ran with no transaction at all. Silent, and it does not recover until
 * the request ends.
 *
 * That is what made one failing spec cascade in the compatibility matrix: the
 * whole core suite runs inside a single request, so a throwing begin in
 * `CockroachDBTransactionSpec` disabled model transaction handling for every
 * bundle after it, and `OuterTransactionSignalSpec`'s rollback assertion
 * failed several bundles later for reasons that had nothing to do with it.
 *
 * An invalid isolation level is the portable way to make the begin tag itself
 * fail on every engine.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("invokeWithTransaction marker reset (##3302)", () => {

			it("clears the open-transaction marker when the transaction fails to begin", () => {
				var tag = application.wo.model("tag");
				var connectionArgs = tag.$hashedConnectionArgs();

				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				if (!StructKeyExists(request.wheels, "transactions")) {
					request.wheels.transactions = {};
				}
				request.wheels.transactions[connectionArgs] = false;

				// Struct, not a scalar, and accessed without the `local.` prefix:
				// anything written through `local.` inside a catch is discarded on
				// BoxLang (cross-engine invariant 11).
				var state = {threw = false};
				try {
					tag.invokeWithTransaction(
						method = "count",
						transaction = "commit",
						isolation = "wheels_not_a_real_isolation_level"
					);
				} catch (any e) {
					state.threw = true;
				}

				expect(state.threw).toBeTrue(
					"An invalid isolation level should make the begin tag fail — if this is false the "
					& "engine accepted the level and the spec needs a different way to fail the open."
				);
				expect(request.wheels.transactions[connectionArgs]).toBeFalse(
					"A transaction that never opened must leave the connection unmarked, otherwise every "
					& "later model call in this request silently skips its own transaction."
				);
			});

		});

	}

}
