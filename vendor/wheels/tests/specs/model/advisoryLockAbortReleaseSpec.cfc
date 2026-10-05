/**
 * #4219: a withAdvisoryLock() callback that ends the request from inside the lock — with a real
 * `abort` or a real `redirectTo()` (which ends in a cflocation) — must still release the database
 * lock. The release runs in a `finally`, which executes on those exit paths (measured on Lucee,
 * Adobe and BoxLang; only a `catch` is skipped by abort). This spec pins that: it drives
 * request-ending actions over HTTP via $testClient and then, from its own separate connection,
 * asserts the named lock is no longer held anywhere. A release that regressed out of the `finally`
 * would leave the lock on the aborting request's pooled connection and red this spec.
 *
 * Covered: the default (session-scoped) path and the transaction = true path, each ending via abort
 * and via redirectTo. Advisory locks only apply to PostgreSQL, MySQL and SQL Server, so other
 * databases skip. The lock-held check uses the adapter's own $isAdvisoryLockHeld (the same
 * canonical free-check the release verification uses), on a fresh adapter/connection.
 *
 * The two transaction = true cases run only on adapters whose transactional advisory lock is
 * SESSION-scoped ($transactionalAdvisoryLockIsSessionScoped() == true: MySQL, SQL Server). On
 * PostgreSQL the transactional lock is pg_advisory_xact_lock, which the database auto-releases when
 * the transaction ends regardless of how the request exits — so there is no session-held lock to
 * leak and the assertion would be vacuous. Those cases skip on PostgreSQL with an explanatory note.
 *
 * Fixtures: vendor/wheels/tests/_assets/controllers/AdvisoryLockProbe.cfc + the /_advisorylock
 * routes in vendor/wheels/tests/routes.cfm.
 */
component extends="wheels.WheelsTest" {

	// A separate adapter instance on the test datasource, so the held-check runs on its own
	// connection rather than the model's (mirrors advisoryLockTransactionalSpec.freshAdapter()).
	function freshAdapter() {
		var classData = variables.g.model("author").$classData();
		var folder = Left(variables.adapterName, Len(variables.adapterName) - 5);
		return CreateObject("component", "wheels.databaseAdapters.#folder#.#variables.adapterName#").$init(
			dataSource = classData.dataSource,
			username = classData.username,
			password = classData.password
		);
	}

	// Best-effort: if a scenario failed and left a probe lock held, acquiring+releasing it through the
	// public API clears it when it is free (a no-op) and times out harmlessly when a leaked session
	// still holds it on a pooled connection (only that session could release it). Either way a failure
	// cannot silently hand a held lock to a later spec. Each name is cleaned independently.
	function releaseProbeLocks() {
		var noop = function() {
			return "";
		};
		for (var probe in ListToArray(variables.probeNames)) {
			try {
				variables.g.model("author").withAdvisoryLock(name = probe, timeout = 1, callback = noop);
			} catch (any e) {
				// lock still held by a leaked session, or the DB does not support it — nothing to do.
			}
		}
	}

	function run() {
		// Set at registration time (not beforeAll): the describe callback below reads these while
		// the suite is being built, before any lifecycle method runs.
		variables.g = application.wo;
		variables.adapterName = variables.g.get("adapterName");
		// Databases whose adapter takes real advisory locks (mirrors advisoryLockExclusionSpec /
		// advisoryLockTransactionalSpec). Everything else has no lock to leak, so it skips.
		variables.applies = ListFindNoCase("PostgreSQLModel,MySQLModel,MicrosoftSQLServerModel", variables.adapterName) > 0;
		variables.probeNames = "probe_abort_default,probe_redirect_default,probe_abort_tx,probe_redirect_tx";

		describe("withAdvisoryLock releases the lock when the callback ends the request (4219)", () => {

			if (!variables.applies) {
				it("skips on databases without advisory-lock support", () => {
					skip("Advisory locks apply to PostgreSQL, MySQL and SQL Server only (adapter: " & variables.adapterName & ").");
				});
				return;
			}

			afterEach(() => {
				for (var probe in ListToArray(variables.probeNames)) {
					StructDelete(server, "wheelsAdvisoryProbe_" & probe);
				}
				releaseProbeLocks();
			});

			it("default path: frees the lock after the callback aborts", () => {
				var tc = $testClient();
				StructDelete(server, "wheelsAdvisoryProbe_probe_abort_default");
				tc.get("/_advisorylock/abort-default");
				expect(tc.statusCode()).toBe(200, "the abort probe request did not complete with 200");
				// positive control: the callback ran inside the lock, and a second connection saw it held
				expect(StructKeyExists(server, "wheelsAdvisoryProbe_probe_abort_default")).toBeTrue(
					"the probe callback never ran — the request did not reach withAdvisoryLock"
				);
				expect(server["wheelsAdvisoryProbe_probe_abort_default"]).toBeTrue(
					"the lock was not observably held during the callback — nothing to prove released"
				);
				expect(freshAdapter().$isAdvisoryLockHeld(name = "probe_abort_default")).toBeFalse(
					"a default-path lock stayed held after the callback aborted — the release did not run on abort"
				);
			});

			it("default path: frees the lock after the callback redirects", () => {
				var tc = $testClient();
				StructDelete(server, "wheelsAdvisoryProbe_probe_redirect_default");
				tc.get("/_advisorylock/redirect-default");
				tc.assertRedirect();
				expect(StructKeyExists(server, "wheelsAdvisoryProbe_probe_redirect_default")).toBeTrue(
					"the probe callback never ran — the request did not reach withAdvisoryLock"
				);
				expect(server["wheelsAdvisoryProbe_probe_redirect_default"]).toBeTrue(
					"the lock was not observably held during the callback — nothing to prove released"
				);
				expect(freshAdapter().$isAdvisoryLockHeld(name = "probe_redirect_default")).toBeFalse(
					"a default-path lock stayed held after the callback redirected — the release did not run on cflocation"
				);
			});

			it("transaction = true: frees the lock after the callback aborts", () => {
				if (!freshAdapter().$transactionalAdvisoryLockIsSessionScoped()) {
					skip("transaction=true uses a transaction-scoped advisory lock on " & variables.adapterName & " (PostgreSQL's pg_advisory_xact_lock), auto-released by the database at transaction end — there is no session-held lock to leak when the callback aborts.");
					return;
				}
				var tc = $testClient();
				StructDelete(server, "wheelsAdvisoryProbe_probe_abort_tx");
				tc.get("/_advisorylock/abort-tx");
				expect(tc.statusCode()).toBe(200, "the abort probe request did not complete with 200");
				expect(StructKeyExists(server, "wheelsAdvisoryProbe_probe_abort_tx")).toBeTrue(
					"the probe callback never ran — the request did not reach withAdvisoryLock"
				);
				expect(server["wheelsAdvisoryProbe_probe_abort_tx"]).toBeTrue(
					"the lock was not observably held during the callback — nothing to prove released"
				);
				expect(freshAdapter().$isAdvisoryLockHeld(name = "probe_abort_tx")).toBeFalse(
					"a transaction-path lock stayed held after the callback aborted — the release did not run on abort"
				);
			});

			it("transaction = true: frees the lock after the callback redirects", () => {
				if (!freshAdapter().$transactionalAdvisoryLockIsSessionScoped()) {
					skip("transaction=true uses a transaction-scoped advisory lock on " & variables.adapterName & " (PostgreSQL's pg_advisory_xact_lock), auto-released by the database at transaction end — there is no session-held lock to leak when the callback redirects.");
					return;
				}
				var tc = $testClient();
				StructDelete(server, "wheelsAdvisoryProbe_probe_redirect_tx");
				tc.get("/_advisorylock/redirect-tx");
				tc.assertRedirect();
				expect(StructKeyExists(server, "wheelsAdvisoryProbe_probe_redirect_tx")).toBeTrue(
					"the probe callback never ran — the request did not reach withAdvisoryLock"
				);
				expect(server["wheelsAdvisoryProbe_probe_redirect_tx"]).toBeTrue(
					"the lock was not observably held during the callback — nothing to prove released"
				);
				expect(freshAdapter().$isAdvisoryLockHeld(name = "probe_redirect_tx")).toBeFalse(
					"a transaction-path lock stayed held after the callback redirected — the release did not run on cflocation"
				);
			});
		});
	}
}
