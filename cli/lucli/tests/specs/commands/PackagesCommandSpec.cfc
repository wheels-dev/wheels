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
	}
}
