/**
 * Guards for issue #3025 (Stage-1 slice): the web test runner
 * (vendor/wheels/tests/runner.cfm) swaps the LIVE application.wheels struct
 * for test configuration (backing it up in application.$$$wheels) and
 * restores it when the suite completes. Two overlapping test requests used
 * to clobber each other's backup, which could restore TEST config as the
 * live config until the next reload=true (issue #2887 "they fight each
 * other"). The fix serializes the swap->run->restore window under an
 * exclusive named lock, with a re-entrancy guard so ParallelRunner
 * partition sub-requests (fresh top-level HTTP GETs issued while the parent
 * request holds the swap) skip BOTH the swap and the shared lock instead of
 * deadlocking parallel mode.
 *
 * Two kinds of coverage:
 *
 * 1. Structural (precedent: security/BareCfabortGuardSpec.cfc) — runner.cfm
 *    must contain the exclusive named-lock acquisition and the
 *    already-swapped detection. The lock itself cannot be observed from
 *    inside the suite (this spec executes while the lock is held), so the
 *    source scan is the practical gate.
 *
 * 2. Behavioral — a completed nested run (same shape as a ParallelRunner
 *    partition request) must leave the parent request's swap fully intact:
 *    application.$$$wheels still present and application.wheels still
 *    pointing at test config. Before the fix the nested run overwrote the
 *    parent's backup with test config, restored it as "live", and deleted
 *    the backup key — erroring the parent's own restore.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Web test-runner swap serialization (issue ##3025)", () => {

			it("runner.cfm acquires an exclusive named lock around the config swap window", () => {
				var source = FileRead(ExpandPath("/wheels/tests/runner.cfm"));
				var fileLines = ListToArray(source, Chr(10), true);
				var foundLock = false;
				var foundGuard = false;
				for (var rawLine in fileLines) {
					var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
					// Skip comment-only lines so a commented-out lock can
					// never satisfy this guard (Anti-Pattern 14 spirit).
					if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
						continue;
					}
					// The exclusive named-lock acquisition on the shared
					// runner lock name.
					if (
						REFindNoCase("(^|[\s;{}])lock\s+[^{]*name\s*=", trimmed)
						&& FindNoCase("wheelsTestRunner_", trimmed)
						&& REFindNoCase("type\s*=\s*[""']exclusive[""']", trimmed)
						&& REFindNoCase("throwontimeout", trimmed)
					) {
						foundLock = true;
					}
					// The re-entrancy detection: sub-requests recognize an
					// already-applied swap via the backup key.
					if (FindNoCase("StructKeyExists(application, ""$$$wheels"")", trimmed)) {
						foundGuard = true;
					}
				}
				expect(foundLock).toBeTrue(
					"runner.cfm must wrap the config swap window in an exclusive named lock ('wheelsTestRunner_...', throwOnTimeout) — issue ##3025"
				);
				expect(foundGuard).toBeTrue(
					"runner.cfm must detect an already-applied swap via StructKeyExists(application, '$$$wheels') so ParallelRunner sub-requests skip the swap and the shared lock"
				);
			});

			it("runner.cfm restores the original config in a finally block", () => {
				var source = FileRead(ExpandPath("/wheels/tests/runner.cfm"));
				expect(Find("finally", source) > 0).toBeTrue(
					"runner.cfm must restore application.wheels from the backup inside a finally block so an erroring suite can no longer leave test config live"
				);
				expect(Find("application.wheels = application.$$$wheels", source) > 0).toBeTrue(
					"runner.cfm must restore application.wheels from application.$$$wheels"
				);
			});

			it("a completed nested run leaves the parent request's swap intact", () => {
				// This spec itself executes inside the swap window, so the
				// backup key must be present right now.
				expect(StructKeyExists(application, "$$$wheels")).toBeTrue(
					"precondition: the suite is running inside the swap window"
				);

				// Same shape as a ParallelRunner partition request: a fresh
				// top-level GET back into the runner while this request holds
				// the swap. Point directory= at a single bundle file so the
				// nested run discovers 0 bundles and completes green in
				// milliseconds (the issue-3083 '0-bundle' shape), and pass
				// populate=false so pre-fix engines do not repopulate the
				// database mid-suite.
				var requestParams = {
					format = "json",
					cli = "true",
					populate = "false",
					directory = "wheels.tests.specs.internal.parallelRunnerSpec"
				};
				if (StructKeyExists(url, "db")) {
					requestParams.db = url.db;
				}
				var tc = $testClient().get(path = "/wheels/core/tests", params = requestParams);
				expect(tc.statusCode()).toBe(200, "the nested runner request must complete green");

				// The nested run must NOT have deleted the parent's backup...
				expect(StructKeyExists(application, "$$$wheels")).toBeTrue(
					"a completed nested run must not delete the parent's application.$$$wheels backup — only the request that created the swap restores it (issue ##3025)"
				);
				// ...and must NOT have restored live config over the
				// in-progress parent run (transactionMode='none' is one of
				// the swapped-in test settings).
				expect(application.wheels.transactionMode).toBe(
					"none",
					"a completed nested run must not restore the live config while the parent run is still executing"
				);
			});

		});
	}
}
