/**
 * `wheels browser install` reaches Module.cfc (LuCLI intercepts `install` only
 * as the first argument), and used to print that it was intercepted by LuCLI
 * and would never arrive, then do nothing. It is now an alias of
 * `wheels browser setup`, as `wheels packages install` is of `add` (#4213).
 *
 * browserInstall() downloads Playwright, so it is stubbed: these specs check
 * the routing, not the download.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		// MockBox writes stub templates here; a fresh checkout doesn't have it.
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
	}

	function run() {

		describe("wheels browser install", () => {

			it("runs setup", () => {
				var m = $module();
				m.browser(arg1 = "install");
				expect(m.$count("browserInstall")).toBe(1);
			});

			it("passes setup's options through", () => {
				var m = $module();
				m.browser(arg1 = "install", force = true);
				var call = m.$callLog().browserInstall[1];
				var passed = IsArray(call[1]) ? call[1] : call.args;
				expect(ArrayToList(passed, " ")).toInclude("--force");
			});

			it("no longer says the command is intercepted", () => {
				var m = $module();
				m.browser(arg1 = "install");
				var said = "";
				for (var line in m.$callLog().out) {
					said &= line[1] & chr(10);
				}
				expect(said).notToInclude("intercepted");
			});

			it("leaves setup itself unchanged", () => {
				var m = $module();
				m.browser(arg1 = "setup");
				expect(m.$count("browserInstall")).toBe(1);
			});

		});

	}

	private any function $module() {
		var m = new cli.lucli.Module(cwd = expandPath("/"));
		prepareMock(m);
		m.$("out");
		m.$(method = "browserInstall", returns = "");
		return m;
	}

}
