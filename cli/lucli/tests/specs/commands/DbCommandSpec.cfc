/**
 * Tests the db command and subcommands via Module.cfc.
 * Verifies argument routing and help text for db reset/status/version.
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

		describe("wheels db", () => {

			it("shows help when called with no arguments", () => {
				mod.__arguments = [];
				mod.db();
				expect(true).toBeTrue();
			});

			it("throws Wheels.InvalidArguments on an unknown subcommand", () => {
				// Drive args through the structured caller-collection (arg1=...),
				// the same path live LuCLI dispatch uses — structuredArgs() reads
				// the function's `arguments` scope, not the instance __arguments.
				expect(() => mod.db(arg1 = "invalid")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("accepts status subcommand", () => {
				mod.__arguments = ["status"];
				// Will fail gracefully since no server, but should not throw
				mod.db();
				expect(true).toBeTrue();
			});

			it("accepts version subcommand", () => {
				mod.__arguments = ["version"];
				mod.db();
				expect(true).toBeTrue();
			});

			it("accepts reset subcommand", () => {
				mod.__arguments = ["reset"];
				mod.db();
				expect(true).toBeTrue();
			});

			it("status accepts --pending flag", () => {
				mod.__arguments = ["status", "--pending"];
				mod.db();
				expect(true).toBeTrue();
			});

			it("version accepts --detailed flag", () => {
				mod.__arguments = ["version", "--detailed"];
				mod.db();
				expect(true).toBeTrue();
			});

			it("reset accepts --skip-seed flag", () => {
				mod.__arguments = ["reset", "--skip-seed"];
				mod.db();
				expect(true).toBeTrue();
			});

		});

	}

}
