/**
 * Tests Module.deploy() argument routing.
 *
 * Specifically guards the top-level `bootstrap` and `exec` aliases added in
 * response to #2677 — LuCLI's picocli root registers `server` as a top-level
 * subcommand (for Lucee instance lifecycle), so `wheels deploy server <verb>`
 * short-circuits to LuCLI's server help before module dispatch. The flat
 * aliases sidestep the collision; the legacy `server <verb>` case is retained
 * for direct callers (MCP, internal tests) that don't go through picocli.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");

		// Create vendor/wheels stub so the module init succeeds.
		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("wheels deploy bootstrap (top-level alias for ##2677)", () => {

			it("dispatches to DeployServerCli.bootstrap via dry-run", () => {
				mod.__arguments = ["bootstrap", "--configPath=#variables.fixture#", "--dry-run"];
				var out = mod.deploy();
				// Dry-run buffers the docker-install one-liner instead of dispatching.
				expect(out).toInclude("get.docker.com");
			});

		});

		describe("wheels deploy exec (top-level alias for ##2677)", () => {

			it("dispatches to DeployServerCli.exec with multi-token commands", () => {
				mod.__arguments = ["exec", "uname", "-a", "--configPath=#variables.fixture#", "--dry-run"];
				var out = mod.deploy();
				expect(out).toInclude("uname -a");
			});

			it("throws when no command follows exec (bare positional)", () => {
				// Truly bare ["exec"] — positional length is 1 directly,
				// independent of any $deployStripFlags behavior. Guards the
				// arrayLen(positional) < 2 check at Module.cfc:1916.
				mod.__arguments = ["exec"];
				expect(() => mod.deploy()).toThrow(regex="requires a command");
			});

			it("throws when only flags follow exec", () => {
				// With flags after `exec`, $deployStripFlags removes them so
				// positional resolves to ["exec"] (length 1), still hitting
				// the guard. This relies on the flag-stripping behavior —
				// the bare-positional test above is the direct guard test.
				mod.__arguments = ["exec", "--configPath=#variables.fixture#"];
				expect(() => mod.deploy()).toThrow(regex="requires a command");
			});

		});

		describe("wheels deploy server <verb> (legacy, direct-call only)", () => {

			it("server bootstrap still routes when called directly", () => {
				// This path works when Module.deploy() is invoked programmatically
				// (MCP, tests). It does NOT work via the LuCLI CLI because
				// picocli intercepts `server` — see #2677.
				mod.__arguments = ["server", "bootstrap", "--configPath=#variables.fixture#", "--dry-run"];
				var out = mod.deploy();
				expect(out).toInclude("get.docker.com");
			});

		});

	}
}
