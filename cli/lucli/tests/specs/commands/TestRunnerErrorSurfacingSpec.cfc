/**
 * #4408: `wheels test --core` reported "no test bundles ran for this scope"
 * when the runner actually failed (e.g. the core-test datasource is missing).
 * The failure envelope the runner returns — {success:false, error, message} —
 * now drives the summary line, so the real cause reaches the user. The exit
 * was already non-zero; only the message was wrong.
 *
 * Also pins the companion wording fix: the `--db only applies to --core`
 * warning named a non-existent `--useTestDB` flag; the real flag is `--test-db`.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.mod = new cli.lucli.Module(cwd = expandPath("/"));
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {

		describe("$runnerErrorMessage", () => {

			it("prefers the runner's terse error over its longer message", () => {
				expect(mod.$runnerErrorMessage({
					success = false,
					error = "Test database not available",
					message = "The framework test suite would run on this app's primary datasource..."
				})).toBe("Test database not available");
			});

			it("falls back to message when there is no error", () => {
				expect(mod.$runnerErrorMessage({message = "Datasource [wheelstestdb_sqlite] doesn't exist"}))
					.toBe("Datasource [wheelstestdb_sqlite] doesn't exist");
			});

			it("falls back to a nested RootCause.message", () => {
				expect(mod.$runnerErrorMessage({RootCause = {message = "deep cause"}})).toBe("deep cause");
			});

			it("is empty for a normal result with no error carried", () => {
				expect(mod.$runnerErrorMessage({totalPass = 0, totalFail = 0, bundlesDiscovered = 0})).toBe("");
			});

			it("is empty for a whitespace-only error and for a non-struct", () => {
				expect(mod.$runnerErrorMessage({error = "   "})).toBe("");
				expect(mod.$runnerErrorMessage("not a struct")).toBe("");
			});

		});

		describe("$testSummaryLine surfaces the runner error (4408)", () => {

			it("reports the runner error instead of 'no test bundles ran'", () => {
				var line = mod.$testSummaryLine(
					result = {success = false, error = "Test database not available", message = "..."},
					totalPass = 0, totalFail = 0, totalError = 0,
					duration = "", specsFailedToLoad = 0, defaultScope = false, coreTests = true
				);
				expect(line.color).toBe("red");
				expect(line.text).toInclude("Test run failed: Test database not available");
				expect(line.text).notToInclude("no test bundles ran");
			});

			it("still says 'no test bundles ran' when the failed result carries no error text", () => {
				// A genuinely empty non-default scope (user asked for a filter that matched nothing).
				var line = mod.$testSummaryLine(
					result = {totalPass = 0, totalFail = 0, totalError = 0, bundlesDiscovered = 0},
					totalPass = 0, totalFail = 0, totalError = 0,
					duration = "", specsFailedToLoad = 0, defaultScope = false
				);
				expect(line.color).toBe("red");
				expect(line.text).toInclude("no test bundles ran");
			});

		});

		describe("the --db-on-app-suite warning names the real flag (4408)", () => {

			it("says --test-db, never the non-existent --useTestDB", () => {
				var warnIdx = find("only applies to --core tests", variables.moduleSource);
				expect(warnIdx).toBeGT(0);
				var seg = mid(variables.moduleSource, warnIdx, 400);
				expect(seg).toInclude("--test-db");
				expect(findNoCase("--useTestDB", seg)).toBe(0, "the warning must not name a flag that does not exist");
			});

		});

	}

}
