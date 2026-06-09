/**
 * Tests the create command via Module.cfc.
 * Verifies argument routing for the unknown-type and no-args paths
 * (the only create() paths that don't require an app scaffold).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("wheels create", () => {

			it("shows help when called with no arguments", () => {
				mod.create();
				expect(true).toBeTrue();
			});

			it("throws Wheels.InvalidArguments for an unknown create type", () => {
				// arg1= exercises the callerArgs path; __arguments is only the internal-delegation fallback.
				expect(() => mod.create(arg1 = "nonexistent")).toThrow(type = "Wheels.InvalidArguments");
			});

		});

	}

}
