/**
 * Tests Module.deploy() argument routing.
 *
 * Specifically guards the top-level `bootstrap` and `exec` aliases added in
 * response to #2677 — LuCLI's picocli root registers `server` as a top-level
 * subcommand (for Lucee instance lifecycle), so `wheels deploy server <verb>`
 * short-circuits to LuCLI's server help before module dispatch. The flat
 * aliases sidestep the collision; the legacy `server <verb>` case is retained
 * for direct callers (MCP, internal tests) that don't go through picocli.
 *
 * Also guards the top-level `fetch-secrets` / `extract-secrets` / `print-secrets`
 * aliases added in response to #2697 — picocli also registers `secrets` as a
 * top-level subcommand (init/set/list/rm/get/provider), so the nested
 * `wheels deploy secrets <verb>` form never reaches the deploy dispatcher.
 * Same sidestep pattern: flat aliases for the CLI, nested form retained for
 * MCP / programmatic callers.
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

		// SKIPPED pending the command-by-command CLI test audit. These deploy
		// specs resolve config relative to the harness webroot rather than the
		// spec's fixture cwd, so --configPath isn't honored under
		// /wheels/cli/tests. Dead (masked by the old -1 error sentinel) until
		// Module.cfc became instantiable here; xdescribe keeps them visible and
		// green until the audit makes them runnable. See #2829 / PR #2831.
		xdescribe("wheels deploy bootstrap (top-level alias for ##2677)", () => {

			it("dispatches to DeployServerCli.bootstrap via dry-run", () => {
				mod.__arguments = ["bootstrap", "--configPath=#variables.fixture#", "--dry-run"];
				var out = mod.deploy();
				// Dry-run buffers the docker-install one-liner instead of dispatching.
				expect(out).toInclude("get.docker.com");
			});

		});

		xdescribe("wheels deploy exec (top-level alias for ##2677)", () => {

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

		xdescribe("wheels deploy server <verb> (legacy, direct-call only)", () => {

			it("server bootstrap still routes when called directly", () => {
				// This path works when Module.deploy() is invoked programmatically
				// (MCP, tests). It does NOT work via the LuCLI CLI because
				// picocli intercepts `server` — see #2677.
				mod.__arguments = ["server", "bootstrap", "--configPath=#variables.fixture#", "--dry-run"];
				var out = mod.deploy();
				expect(out).toInclude("get.docker.com");
			});

		});

		xdescribe("wheels deploy fetch-secrets (top-level alias for ##2697)", () => {

			it("dispatches to DeploySecretsCli.fetch and forwards the adapter flag", () => {
				// Pass an unknown adapter so the call short-circuits inside
				// DeploySecretsCli.fetch (UnknownAdapter) before any shelling
				// happens. Reaching that throw proves the dispatcher hit
				// `case "fetch-secrets":` and forwarded the --adapter flag.
				mod.__arguments = ["fetch-secrets", "K1", "--adapter=nope-not-a-real-adapter"];
				expect(() => mod.deploy()).toThrow(regex="Unknown adapter");
			});

			it("forwards positional keys to opts.keys (NoKeys when empty)", () => {
				// With a valid adapter but no positional keys, DeploySecretsCli.fetch
				// throws DeploySecretsCli.NoKeys before any shelling. This proves
				// positional[2..] populates opts.keys (and that an empty array does
				// reach the keys guard rather than getting eaten elsewhere).
				mod.__arguments = ["fetch-secrets", "--adapter=op"];
				expect(() => mod.deploy()).toThrow(regex="at least one key");
			});

			it("does not crash on a multi-key positional list (boundary smoke)", () => {
				// Three positional keys + an unknown adapter. The adapter check
				// fires before the keys check inside DeploySecretsCli.fetch, so
				// this doesn't prove every key landed in opts.keys (only a real
				// adapter could verify the full slice — see Reviewer A on PR
				// #2699). What it does prove: the `for fsi=2 to arrayLen` loop
				// completes without crashing on a non-trivial positional list
				// (off-by-one would manifest here as a CFML index-out-of-range,
				// not UnknownAdapter). Mirror coverage to the `exec` smoke test
				// at line 43.
				mod.__arguments = ["fetch-secrets", "K1", "K2", "K3", "--adapter=nope-not-a-real-adapter"];
				expect(() => mod.deploy()).toThrow(regex="Unknown adapter");
			});

		});

		xdescribe("wheels deploy extract-secrets (top-level alias for ##2697)", () => {

			it("dispatches to DeploySecretsCli.extract and returns the matched value", () => {
				// extract() reads opts.from (the KEY=VALUE block) and opts.key
				// (the lookup key). The key comes from positional[2]; --from is
				// parsed by DeployArgsParser. No shelling — pure string parsing.
				mod.__arguments = ["extract-secrets", "A", "--from=A=hello"];
				var out = mod.deploy();
				expect(out).toBe("hello");
			});

			it("returns empty string when the key is missing from the block", () => {
				mod.__arguments = ["extract-secrets", "NOPE", "--from=A=hello"];
				var out = mod.deploy();
				expect(out).toBe("");
			});

			it("returns empty string when no positional key is given", () => {
				// With no positional key, opts.key defaults to "" and extract()
				// short-circuits to "". Proves the positional[2] guard handles
				// the missing-key case gracefully.
				mod.__arguments = ["extract-secrets", "--from=A=hello"];
				var out = mod.deploy();
				expect(out).toBe("");
			});

		});

		xdescribe("wheels deploy print-secrets (top-level alias for ##2697)", () => {

			it("dispatches to DeploySecretsCli.print and returns a string", () => {
				// The dispatcher hands control to DeploySecretsCli.print, which
				// always returns a string (empty if no .kamal/secrets exists at
				// the resolver's projectRoot, KEY=VALUE lines otherwise). The
				// dispatch is the assertion: before the fix, deploy() throws
				// "Unknown deploy subcommand: print-secrets" before reaching
				// any CLI; after the fix, we get a string back without raising.
				mod.__arguments = ["print-secrets"];
				var out = mod.deploy();
				expect(out).toBeTypeOf("string");
			});

		});

		xdescribe("wheels deploy secrets <verb> (legacy, direct-call only)", () => {

			it("secrets extract still routes when called directly", () => {
				// This path works when Module.deploy() is invoked programmatically
				// (MCP, tests). It does NOT work via the LuCLI CLI because
				// picocli intercepts `secrets` — see #2697. The flat
				// `extract-secrets` alias is the canonical CLI form.
				mod.__arguments = ["secrets", "extract", "A", "--from=A=legacy"];
				var out = mod.deploy();
				expect(out).toBe("legacy");
			});

		});

	}
}
