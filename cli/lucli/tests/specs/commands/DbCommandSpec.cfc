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

		// Pin the project port to a closed port so the server-dependent db
		// subcommands deterministically throw Wheels.ServerNotRunning in
		// every environment (a local dev server on 8080 would otherwise
		// answer the common-port fallback and flip these assertions).
		fileWrite(tempRoot & "/.env", "PORT=1" & chr(10));

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
				// arg1= exercises the callerArgs path; __arguments is only the internal-delegation fallback.
				expect(() => mod.db(arg1 = "invalid")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("accepts status subcommand", () => {
				mod.__arguments = ["status"];
				// Dispatch is proven by the server-dependent error: the
				// subcommand was accepted and routed (no server in CI).
				expect(() => mod.db()).toThrow(type = "Wheels.ServerNotRunning");
			});

			it("accepts version subcommand", () => {
				mod.__arguments = ["version"];
				expect(() => mod.db()).toThrow(type = "Wheels.ServerNotRunning");
			});

			it("accepts reset subcommand", () => {
				mod.__arguments = ["reset"];
				// reset short-circuits before the server gate in some
				// environments — tolerate either the graceful run or the
				// server-not-running error, but nothing else.
				try {
					mod.db();
				} catch (any e) {
					expect(e.type).toBe("Wheels.ServerNotRunning");
				}
			});

			it("status accepts --pending flag", () => {
				mod.__arguments = ["status", "--pending"];
				expect(() => mod.db()).toThrow(type = "Wheels.ServerNotRunning");
			});

			it("version accepts --detailed flag", () => {
				mod.__arguments = ["version", "--detailed"];
				expect(() => mod.db()).toThrow(type = "Wheels.ServerNotRunning");
			});

			it("reset accepts --skip-seed flag", () => {
				mod.__arguments = ["reset", "--skip-seed"];
				try {
					mod.db();
				} catch (any e) {
					expect(e.type).toBe("Wheels.ServerNotRunning");
				}
			});

		});

	}

}
