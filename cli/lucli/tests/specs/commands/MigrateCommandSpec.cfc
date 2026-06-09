/**
 * Tests the migrate and seed commands via Module.cfc.
 * Verifies argument parsing and subcommand routing.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Create vendor/wheels stub
		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		// SKIPPED pending the command-by-command CLI test audit. `migrate` and
		// `seed` invoke commands that require a *running* Wheels server (server
		// detection via lucee.json/.env ports); the stateless TestBox harness has
		// none on the expected port, so every case errors with "No running Wheels
		// server detected". (These passed against a local dev server but fail in
		// CI — server-dependent, not unit-testable here.) See #2829 / PR #2831.
		xdescribe("wheels migrate", () => {

			it("defaults to latest when no args", () => {
				mod.__arguments = [];
				// Will attempt migration and fail gracefully (no server/migrator)
				mod.migrate();
				expect(true).toBeTrue();
			});

			it("accepts latest action", () => {
				mod.__arguments = ["latest"];
				mod.migrate();
				expect(true).toBeTrue();
			});

			it("accepts up action", () => {
				mod.__arguments = ["up"];
				mod.migrate();
				expect(true).toBeTrue();
			});

			it("accepts down action", () => {
				mod.__arguments = ["down"];
				mod.migrate();
				expect(true).toBeTrue();
			});

			it("accepts info action", () => {
				mod.__arguments = ["info"];
				mod.migrate();
				expect(true).toBeTrue();
			});

			it("throws Wheels.InvalidArguments on an unknown action", () => {
				expect(() => mod.migrate(arg1 = "invalid")).toThrow(type = "Wheels.InvalidArguments");
			});

		});

		xdescribe("wheels seed", () => {

			it("runs without error with no args", () => {
				mod.__arguments = [];
				mod.seed();
				expect(true).toBeTrue();
			});

			it("accepts --environment flag", () => {
				mod.__arguments = ["--environment=development"];
				mod.seed();
				expect(true).toBeTrue();
			});

			it("accepts --generate flag", () => {
				mod.__arguments = ["--generate"];
				mod.seed();
				expect(true).toBeTrue();
			});

			it("accepts --mode flag", () => {
				mod.__arguments = ["--mode=auto"];
				mod.seed();
				expect(true).toBeTrue();
			});

		});

	}

}
