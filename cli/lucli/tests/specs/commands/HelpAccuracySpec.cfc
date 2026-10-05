/**
 * Help and hint text that disagreed with what the command does (4418): coverage
 * listed no options, destroy described a confirmation prompt it never shows, new
 * gave the wrong datasource default, the packages synopsis left out remove's --yes,
 * and the seed-data snippet pointed at `wheels seed` for files it doesn't read.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.mod = new cli.lucli.Module(cwd = getTempDirectory());
	}

	function run() {

		describe("help and hint accuracy (4418)", () => {

			it("lists the coverage options", () => {
				var help = mod.showHelp("coverage");
				expect(help).toInclude("--top=<value>");
				expect(help).toInclude("--[no-]test-db");
			});

			it("describes destroy --force as what makes destroy delete", () => {
				var help = mod.showHelp("destroy");
				expect(help).notToInclude("confirmation prompt");
				expect(help).toInclude("only lists");
			});

			it("gives the lowercased app name as the default datasource of new", () => {
				expect(mod.showHelp("new")).toInclude("the app name, lowercased");
			});

			it("shows remove's required --yes in the packages synopsis", () => {
				makePublic(mod, "$packagesHelp");
				expect(mod.$packagesHelp()).toInclude("remove <name> --yes");
			});

			it("names the seed files wheels seed reads in the seed-data hint", () => {
				makePublic(mod, "getSnippetRegistry");
				var hint = mod.getSnippetRegistry()["seed-data"].hint;
				expect(hint).toInclude("app/db/seeds.cfm");
				expect(hint).toInclude("app/db/seeds/development.cfm");
			});

		});

	}

}
