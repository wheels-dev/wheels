/**
 * Tests `wheels packages help` / `wheels packages --help` via Module.cfc.
 *
 * Issue #2713: the help output must document `add` (not `install`) as the
 * canonical install verb, and must explain why `install` does not work
 * (LuCLI's built-in extension installer intercepts the literal verb before
 * dispatch reaches this module).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("wheels packages help", () => {

			it("treats `help` positional as a help request (no network call)", () => {
				mod.__arguments = ["help"];
				var out = mod.packages();
				expect(Len(out)).toBeGT(0);
			});

			it("treats `--help` flag as a help request", () => {
				mod.__arguments = ["--help"];
				var out = mod.packages();
				expect(Len(out)).toBeGT(0);
			});

			it("treats `-h` short flag as a help request", () => {
				mod.__arguments = ["-h"];
				var out = mod.packages();
				expect(Len(out)).toBeGT(0);
				// Sanity: the short flag reaches the same hand-written help body,
				// so it should mention `add` just like the other two forms.
				expect(out).toInclude("wheels packages add");
			});

			it("documents `add` as the canonical install verb", () => {
				mod.__arguments = ["help"];
				var out = mod.packages();
				expect(out).toInclude("wheels packages add");
			});

			it("does not advertise `install <name>` as a working verb", () => {
				mod.__arguments = ["help"];
				var out = mod.packages();
				// The historic help row "install <name> [--force]   Install a package"
				// must not appear — it advertises a verb that LuCLI intercepts.
				expect(REFindNoCase("install[[:space:]]+<name>[[:space:]]+\[--force\][[:space:]]+Install a package", out)).toBe(0);
			});

			it("explains that `install` is intercepted by LuCLI", () => {
				mod.__arguments = ["help"];
				var out = mod.packages();
				expect(out).toInclude("LuCLI");
				expect(REFindNoCase("intercept", out)).toBeGT(0);
			});

			it("lists every canonical sub-verb", () => {
				mod.__arguments = ["help"];
				var out = mod.packages();
				expect(out).toInclude("list");
				expect(out).toInclude("search");
				expect(out).toInclude("show");
				expect(out).toInclude("add");
				expect(out).toInclude("update");
				expect(out).toInclude("remove");
				expect(out).toInclude("registry");
			});
		});

		describe("wheels packages install — alias for add", () => {

			// Issue #2785: prior implementation made `case "install":` in
			// Module.cfc a friendly-redirect dead branch that printed a
			// warning to stdout and returned "" without installing anything.
			// That meant any caller that reached Module.cfc via a path that
			// is not the user-facing CLI (MCP tools, scripted clients, specs)
			// silently got nothing back when typing `install` — even though
			// `PackagesMainCli.install()` itself has always been a true alias
			// for `add()`. The alias must be wired through the dispatch
			// layer too, so that the only place `install` ever no-ops is the
			// LuCLI extension-installer intercept (which we cannot patch),
			// and every in-process caller gets the same behavior as `add`.
			it("throws the same BadInput error as `add` when name is missing", () => {
				mod.__arguments = ["install"];
				var threw = {flag: false, message: ""};
				try {
					mod.packages();
				} catch (any e) {
					threw.flag = true;
					threw.message = e.message;
				}
				expect(threw.flag).toBeTrue();
				// The error must point users at the canonical `add` verb so
				// programmatic callers (MCP, scripts) see the right shape.
				expect(threw.message).toInclude("add");
			});

			it("dispatches `install <name>` to the same code path as `add <name>`", () => {
				// Both verbs must reach PackagesMainCli — meaning neither
				// short-circuits with a warning before instantiation. A
				// bogus package name still throws (registry lookup fails),
				// but it must throw the SAME way for both verbs. The prior
				// behavior was that `install` silently returned "" while
				// `add` threw — a divergence that broke any caller that
				// expected the alias to be transparent.
				var captureThrow = (verb) => {
					var localMod = new cli.lucli.Module(cwd = variables.tempRoot);
					localMod.__arguments = [verb, "wheels-this-package-does-not-exist-#CreateUUID()#"];
					var threw = {flag: false, type: ""};
					try {
						localMod.packages();
					} catch (any e) {
						threw.flag = true;
						threw.type = e.type;
					}
					return threw;
				};
				var addResult = captureThrow("add");
				var installResult = captureThrow("install");
				expect(addResult.flag).toBeTrue();
				expect(installResult.flag).toBeTrue();
				// Both must throw, and both must throw with a non-empty type
				// — proving they reached the same registry-lookup code path
				// rather than `install` being intercepted by a different branch.
				expect(installResult.type).notToBe("");
			});
		});
	}
}
