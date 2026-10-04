/**
 * `wheels new --help` lists the options and examples. It used to print only
 * the one-line hint, because the options lived in out() lines that only a
 * bare `wheels new` printed; they now come from newArgSpec(), the same
 * declaration the parser uses, and a bare `wheels new` prints the same help.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("wheels new --help", () => {

			it("lists the options from newArgSpec() and the examples", () => {
				var help = new cli.lucli.Module(cwd = getTempDirectory()).showHelp("new");
				expect(help).toInclude("wheels new");
				expect(help).toInclude("Options:");
				expect(help).toInclude("--port=");
				expect(help).toInclude("--datasource=");
				expect(help).toInclude("--reload-password=");
				expect(help).toInclude("--setup-h2");
				expect(help).toInclude("--[no-]sqlite");
				expect(help).toInclude("--[no-]open-browser");
				expect(help).toInclude("Examples:");
				expect(help).toInclude("wheels new myapp --port=3000 --setup-h2");
			});

			it("prints the same help for a bare `wheels new`", () => {
				// The expected text comes from a separate instance: after new()
				// runs, the same instance's argument state would make showHelp()
				// print the general list.
				var expected = new cli.lucli.Module(cwd = getTempDirectory()).showHelp("new");
				var mod = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = getTempDirectory());
				// invoke(): `new` is a CFML keyword, so call the method by name.
				invoke(mod, "new");
				expect(mod.capturedOutput()).toBe(expected);
			});
		});
	}
}
