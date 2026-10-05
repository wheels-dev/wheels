/**
 * The test-runner actions (wheels.Public testbox / tests_testbox) refuse to run specs against the live
 * application when isolation is configured for the app but the request did not bind the isolated
 * `<name>_wheelsTest` scope (e.g. it arrived through a custom route the path trigger does not cover).
 *
 * This pins the two testable halves of that guard:
 *   - TestContext.testRunnerMustRefuse() — the decision (configured AND not isolated).
 *   - events/testcontext.cfm sets request.$wheelsTestContextConfigured when the include runs, which is
 *     how the runner actions know isolation is configured for this app.
 *
 * The 409 emission itself only fires in a live (non-isolated) application; the core suite always runs
 * inside the isolated app, so it cannot exercise that branch from here. The 409 is thin glue over the
 * decision below, mirroring the existing datasource-refusal 409 in $runProjectTestRunner.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("TestContext.testRunnerMustRefuse — refuse a live-scope test run only when configured", () => {

			variables.tc = new wheels.events.TestContext();

			it("refuses when isolation is configured but the app is NOT the isolated scope (custom route)", () => {
				expect(variables.tc.testRunnerMustRefuse(isolationConfigured = true, applicationName = "myapp")).toBeTrue();
			});

			it("allows when the request is already in the isolated application", () => {
				expect(variables.tc.testRunnerMustRefuse(isolationConfigured = true, applicationName = "myapp_wheelsTest")).toBeFalse();
			});

			it("allows (keeps today's live-scope swap) when isolation is NOT configured for the app", () => {
				// An upgraded app without the events/testcontext.cfm include never sets the marker; it must
				// keep running via the #3373 swap (with the #4354 warning), not get a 409.
				expect(variables.tc.testRunnerMustRefuse(isolationConfigured = false, applicationName = "myapp")).toBeFalse();
				expect(variables.tc.testRunnerMustRefuse(isolationConfigured = false, applicationName = "myapp_wheelsTest")).toBeFalse();
			});

		});

		describe("events/testcontext.cfm marks isolation as configured", () => {

			it("sets request.$wheelsTestContextConfigured for a request that ran the include", () => {
				// This very spec runs through the test runner, whose request went through the include in
				// Application.cfc's constructor, so the marker is present (and request scope was writable
				// in the constructor on this engine).
				expect(StructKeyExists(request, "$wheelsTestContextConfigured")).toBeTrue();
			});

		});

	}

}
