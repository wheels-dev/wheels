/**
 * A long app test run keeps the runner's own request timeout, and a run that is
 * stopped before it finishes reports an error, never 0 passed / 0 failed / 0 errors.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("app test run timeout", () => {

			it("re-applies the runner's request timeout after tests/populate.cfm", () => {
				var source = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				var capturePos = FindNoCase("local.runnerRequestTimeout = Max(1800, application.wo.$getRequestTimeout());", source);
				var populatePos = FindNoCase("include ""/tests/populate.cfm"";", source);
				var reapplyPos = FindNoCase("setting requestTimeout = local.runnerRequestTimeout;", source);
				var runPos = FindNoCase("testBox.run(", source);
				expect(capturePos).toBeGT(0);
				expect(populatePos).toBeGT(capturePos);
				expect(reapplyPos).toBeGT(populatePos);
				expect(runPos).toBeGT(reapplyPos);
			});

			it("does not lower the request timeout in any tests/populate.cfm the repo ships", () => {
				// the `wheels new` template, the starter app, and this repo's demo app
				var paths = [
					ExpandPath("/cli/lucli/templates/app/tests/populate.cfm"),
					ExpandPath("/wheels/../..") & "/examples/starter-app/tests/populate.cfm",
					ExpandPath("/wheels/../..") & "/tests/populate.cfm"
				];
				for (var path in paths) {
					expect(FileExists(path)).toBeTrue(path);
					expect(FindNoCase("requestTimeOut", FileRead(path))).toBe(0, path);
				}
			});

			it("reports a run that did not finish as an error", () => {
				var source = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				var failurePos = FindNoCase("error: ""TestBox run failed""", source);
				expect(failurePos).toBeGT(0);
				var window = Mid(source, failurePos, 800);
				expect(FindNoCase("totalError: 1", window)).toBeGT(0);
				expect(FindNoCase("$testRunFailureMessage(runErr = runErr)", window)).toBeGT(0);
			});

		});

		describe("$testRunFailureMessage()", () => {

			it("says when the run was stopped by the request timeout", () => {
				var message = g.$testRunFailureMessage(runErr = {
					type = "expression",
					message = "request /index.cfm has run into a timeout (timeout: 300 seconds) and has been stopped."
				});
				expect(message).toInclude("hit the request timeout");
				expect(message).toInclude("has run into a timeout");
			});

			it("passes any other error message through", () => {
				var message = g.$testRunFailureMessage(runErr = {type = "database", message = "table not found"});
				expect(message).toBe("table not found");
			});

		});

	}

}
