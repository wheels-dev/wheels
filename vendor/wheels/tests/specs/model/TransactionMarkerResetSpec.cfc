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

			it("clears the open-transaction marker when a transaction='none' call throws", () => {
				// transaction="none" still sets the marker (so nested calls skip their own
				// transaction), and used to leave it set when the method threw. The core
				// runner runs with transactionMode="none", so one create() that hit a
				// database error broke OuterTransactionSignalSpec's rollback bundles later.
				var tag = application.wo.model("tag");
				var connectionArgs = tag.$hashedConnectionArgs();

				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				if (!StructKeyExists(request.wheels, "transactions")) {
					request.wheels.transactions = {};
				}
				request.wheels.transactions[connectionArgs] = false;

				var state = {threw = false};
				try {
					// An unknown select column makes findAll() throw Wheels.ColumnNotFound
					// inside the invoked method, after the marker has been set, before any
					// query runs. A Wheels Throw() rather than a missing required argument,
					// which RustCFML does not enforce through cfinvoke.
					tag.invokeWithTransaction(method = "findAll", transaction = "none", select = "wheelsNoSuchColumn");
				} catch (any e) {
					state.threw = true;
				}

				expect(state.threw).toBeTrue("findAll() with an unknown select column should have thrown.");
				expect(request.wheels.transactions[connectionArgs]).toBeFalse(
					"A throwing transaction='none' call must clear the marker it set, otherwise every "
					& "later model call in this request silently skips its own transaction."
				);
			});

			it("rejects an invalid transaction mode without leaving the marker set, so a later rollback still rolls back", () => {
				// An invalid mode used to be rejected only in the switch's default branch,
				// AFTER the marker was set and outside both catches: the marker stayed true
				// and the next save(transaction="rollback") ran as "alreadyopen", with no
				// transaction at all, and persisted.
				var tagModel = application.wo.model("tag");
				var connectionArgs = tagModel.$hashedConnectionArgs();

				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				if (!StructKeyExists(request.wheels, "transactions")) {
					request.wheels.transactions = {};
				}
				request.wheels.transactions[connectionArgs] = false;

				var uniqueName = "txmode-" & Left(Hash(CreateUUID()), 12);
				var state = {threw = false, type = ""};
				try {
					tagModel.new(name = "txmode-invalid").save(transaction = "commti");
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				var markerAfterInvalid = request.wheels.transactions[connectionArgs];

				var rolledBack = tagModel.new(name = uniqueName);
				rolledBack.save(transaction = "rollback");
				var persisted = tagModel.findOne(where = "name = '#uniqueName#'");
				// Clean up before asserting, in case the rollback didn't happen.
				tagModel.deleteAll(where = "name IN ('#uniqueName#', 'txmode-invalid')");
				request.wheels.transactions[connectionArgs] = false;

				expect(state.threw).toBeTrue("save(transaction=""commti"") should throw.");
				expect(markerAfterInvalid).toBeFalse(
					"An invalid transaction mode must not leave the connection marked as having an open transaction."
				);
				expect(IsObject(persisted)).toBeFalse(
					"save(transaction=""rollback"") after an invalid mode must still roll back; the row was persisted."
				);
			});

			it("leaves an outer owner's marker set when a nested call throws", () => {
				var tag = application.wo.model("tag");
				var connectionArgs = tag.$hashedConnectionArgs();

				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				if (!StructKeyExists(request.wheels, "transactions")) {
					request.wheels.transactions = {};
				}
				request.wheels.transactions[connectionArgs] = true;

				var state = {threw = false};
				try {
					tag.invokeWithTransaction(method = "findAll", transaction = "commit", select = "wheelsNoSuchColumn");
				} catch (any e) {
					state.threw = true;
				}
				var stillOpen = request.wheels.transactions[connectionArgs];
				// Restore before asserting, so a failure here cannot leak into later bundles.
				request.wheels.transactions[connectionArgs] = false;

				expect(state.threw).toBeTrue("findAll() with an unknown select column should have thrown.");
				expect(stillOpen).toBeTrue(
					"A nested ('alreadyopen') call does not own the marker; the outer owner clears it."
				);
			});

		});

	}

}
