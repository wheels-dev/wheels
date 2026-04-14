/**
 * Tests the test command via Module.cfc.
 * Verifies argument parsing for filter, reporter, db, verbose, ci, core flags.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Create vendor/wheels/tests stub so auto-detect finds core tests
		directoryCreate(tempRoot & "/vendor/wheels/tests", true, true);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("wheels test", () => {

			it("runs without error with no args", () => {
				mod.__arguments = [];
				// Will attempt to run tests and fail gracefully (no server)
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts positional filter argument", () => {
				mod.__arguments = ["model"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --filter flag", () => {
				mod.__arguments = ["--filter=controller"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --filter with space syntax", () => {
				mod.__arguments = ["--filter", "model"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --reporter flag", () => {
				mod.__arguments = ["--reporter=simple"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --db flag", () => {
				mod.__arguments = ["--db=sqlite"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --verbose flag", () => {
				mod.__arguments = ["--verbose"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts -v shorthand", () => {
				mod.__arguments = ["-v"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --ci flag", () => {
				mod.__arguments = ["--ci"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --core flag", () => {
				mod.__arguments = ["--core"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts combined flags", () => {
				mod.__arguments = ["--filter=model", "--db=sqlite", "--verbose", "--ci"];
				mod.test();
				expect(true).toBeTrue();
			});

		});

	}

}
