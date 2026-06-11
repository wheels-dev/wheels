/**
 * Tests info, doctor, stats, notes, mcp, and other informational commands
 * via Module.cfc. These commands produce output (verified by no-throw)
 * and some have file-system-detectable behavior.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Create vendor/wheels stub
		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		// Create a model for stats/notes tests
		directoryCreate(tempRoot & "/app/models", true, true);
		fileWrite(tempRoot & "/app/models/StatsTest.cfc",
			'component extends="Model" {' & chr(10) &
			'    // TODO: add validations' & chr(10) &
			'    // FIXME: handle edge case' & chr(10) &
			'    function config() {}' & chr(10) &
			'}'
		);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("wheels info", () => {

			it("runs without error", () => {
				mod.info();
				expect(true).toBeTrue();
			});

		});

		describe("wheels mcp", () => {

			it("runs without error", () => {
				mod.mcp();
				expect(true).toBeTrue();
			});

		});

		describe("wheels doctor", () => {

			it("runs without error", () => {
				mod.__arguments = [];
				mod.doctor();
				expect(true).toBeTrue();
			});

			it("accepts --verbose flag", () => {
				mod.__arguments = ["--verbose"];
				mod.doctor();
				expect(true).toBeTrue();
			});

			it("accepts -v shorthand", () => {
				mod.__arguments = ["-v"];
				mod.doctor();
				expect(true).toBeTrue();
			});

		});

		describe("wheels stats", () => {

			it("runs without error", () => {
				mod.__arguments = [];
				mod.stats();
				expect(true).toBeTrue();
			});

			it("accepts --verbose flag", () => {
				mod.__arguments = ["--verbose"];
				mod.stats();
				expect(true).toBeTrue();
			});

		});

		describe("wheels notes", () => {

			it("runs without error", () => {
				mod.__arguments = [];
				mod.notes();
				expect(true).toBeTrue();
			});

			it("accepts --annotations flag", () => {
				mod.__arguments = ["--annotations=TODO,FIXME"];
				mod.notes();
				expect(true).toBeTrue();
			});

			it("accepts --custom flag for custom annotations", () => {
				mod.__arguments = ["--custom=HACK,REVIEW"];
				mod.notes();
				expect(true).toBeTrue();
			});

		});

		describe("wheels analyze", () => {

			it("runs without error", () => {
				mod.__arguments = [];
				mod.analyze();
				expect(true).toBeTrue();
			});

			it("accepts target argument", () => {
				mod.__arguments = ["models"];
				mod.analyze();
				expect(true).toBeTrue();
			});

		});

		describe("wheels validate", () => {

			it("runs without error", () => {
				mod.validate();
				expect(true).toBeTrue();
			});

		});

		describe("wheels upgrade", () => {

			// The swap requires the explicit `apply` verb (#3039 review):
			// bare `wheels upgrade` prints usage steering and exits 0, so
			// an MCP wheels_upgrade call with {} can never mutate. Deeper
			// dispatch coverage lives in UpgradeApplyCommandSpec.

			it("shows help when called with the help subcommand", () => {
				var result = mod.upgrade(arg1 = "help");
				expect(result).toInclude("wheels upgrade");
			});

			it("accepts check subcommand with --to flag", () => {
				mod.upgrade(arg1 = "check", to = "3.0.0");
				expect(true).toBeTrue();
			});

			it("bare verb prints usage steering and never mutates", () => {
				var result = mod.upgrade();
				expect(result).toInclude("wheels upgrade check");
				expect(result).toInclude("wheels upgrade apply");
			});

			it("apply verb refuses over the empty vendor/wheels stub", () => {
				// The stub has no wheels.json/box.json to sniff, so apply
				// must refuse before touching it.
				expect(() => mod.upgrade(arg1 = "apply")).toThrow(type = "Wheels.UpgradeApplyFailed");
			});

		});

	}

}
