/**
 * `wheels <command> --help` lists the command's options (issue 3962).
 *
 * The options come from the command's ArgSpec, the same declaration the
 * parser and the MCP input schema use, so help cannot drift from what the
 * command accepts. `wheels test --help` also shows worked examples.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.mod = new cli.lucli.Module(cwd = getTempDirectory());
	}

	function run() {

		describe("wheels test --help (issue 3962)", () => {

			it("lists every option the test command declares", () => {
				var help = mod.showHelp("test");
				expect(help).toInclude("Options:");
				for (var label in ["--filter=<value>", "--directory=<value>", "--reporter=<value>", "--db=<value>", "--base-path=<value>", "--timeout=<value>", "--verbose", "--ci", "--core", "--[no-]test-db"]) {
					expect(help).toInclude(label);
				}
				expect(help).toInclude("[simple, json, tap]");
				expect(help).toInclude("(default: simple)");
			});

			it("lists the options in declaration order", () => {
				var help = mod.showHelp("test");
				expect(Find("--filter=", help)).toBeLT(Find("--directory=", help));
				expect(Find("--directory=", help)).toBeLT(Find("--reporter=", help));
				expect(Find("--reporter=", help)).toBeLT(Find("--verbose", help));
			});

			it("shows how to run one spec and one directory", () => {
				var help = mod.showHelp("test");
				expect(help).toInclude("Examples:");
				expect(help).toInclude("wheels test --filter=UserSpec");
				expect(help).toInclude("wheels test tests.specs.models");
			});

			it("still falls back to the global listing for an unknown command", () => {
				expect(mod.showHelp("no-such-command")).toInclude("wheels <command> [options]");
			});

		});

		describe("ArgSpec.toHelpLines", () => {

			it("renders positionals, options and flags in declaration order", () => {
				var lines = new cli.lucli.services.ArgSpec()
					.positional(name = "target", description = "What to run")
					.option(name = "zeta", default = "z", description = "Zeta option")
					.flag(name = "alpha", description = "Alpha flag")
					.flag(name = "beta", default = true, description = "Beta flag, on by default")
					.accept("hidden")
					.toHelpLines();
				var text = arrayToList(lines, chr(10));
				expect(Find("<target>", text)).toBeLT(Find("--zeta=<value>", text));
				expect(Find("--zeta=<value>", text)).toBeLT(Find("--alpha", text));
				expect(Find("--alpha", text)).toBeLT(Find("--[no-]beta", text));
				expect(text).toInclude("(on by default)");
				expect(text).toInclude("(default: z)");
				expect(text).notToInclude("hidden");
			});

			it("wraps a long description under its option", () => {
				var lines = new cli.lucli.services.ArgSpec()
					.option(name = "long", description = repeatString("word ", 40))
					.toHelpLines(width = 60);
				expect(arrayLen(lines)).toBeGT(1);
				for (var line in lines) {
					expect(len(line)).toBeLTE(60);
				}
			});

		});

	}

}
