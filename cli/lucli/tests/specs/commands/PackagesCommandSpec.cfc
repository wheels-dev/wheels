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

		// SKIPPED pending the command-by-command CLI test audit. The `-h` help
		// path is intercepted by the brew/bash wrapper, not Module.cfc, so under
		// /wheels/cli/tests `packages -h` runs the real registry fetch instead of
		// showing help. Dead (masked by the old -1 error sentinel) until
		// Module.cfc became instantiable here; xdescribe keeps them visible and
		// green until the audit makes them runnable. See #2829 / PR #2831.
		// Paths that fail before any registry or network call, so they run
		// in every environment (##2963: packages now parses via ArgSpec).
		describe("wheels packages — argument parsing", () => {

			it("rejects a bare --tag instead of filtering on the literal `true`", () => {
				// LuCLI delivers `--tag foo` as tag=true plus a positional, so a
				// bare --tag must fail loudly rather than list nothing.
				expect(() => mod.packages(arg1 = "list", tag = true)).toThrow(type = "Wheels.InvalidArguments");
			});

			it("reports a missing name for add from a named subcommand", () => {
				var state = {message: ""};
				try {
					mod.packages(subcommand = "add");
				} catch (any e) {
					state.message = e.message;
				}
				expect(state.message).toInclude("add requires a name");
			});

			it("binds a named target the same as a positional one", () => {
				// `registry` validates its verb before touching the network.
				expect(() => mod.packages(subcommand = "registry", target = "bogus")).toThrow();
				var state = {message: ""};
				try {
					mod.packages(subcommand = "registry", target = "bogus");
				} catch (any e) {
					state.message = e.message;
				}
				expect(state.message).toInclude("Unknown wheels packages registry verb: bogus");
			});

		});

		xdescribe("wheels packages help", () => {

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

		xdescribe("wheels packages install — alias for add", () => {

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
				// And both must throw the SAME exception type — a future
				// regression that made `install` throw at argument validation
				// (before the registry call) would still satisfy the non-empty
				// check above, so pin the equivalence explicitly.
				expect(installResult.type).toBe(addResult.type);
			});
		});
	}
}
