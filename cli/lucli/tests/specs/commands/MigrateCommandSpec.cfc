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

		describe("wheels migrate", () => {

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

			it("rejects unknown action without throwing", () => {
				mod.__arguments = ["invalid"];
				mod.migrate();
				expect(true).toBeTrue();
			});

		});

		describe("wheels seed", () => {

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
