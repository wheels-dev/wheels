component extends="wheels.WheelsTest" {

	function run() {

		describe("Generated app templates — package install verb", () => {

			// Regression guard for issue #2610: on older LuCLI runtimes
			// `wheels packages install <name>` is intercepted by the built-in
			// extension installer and never reaches Module.cfc. The current
			// runtime passes it through as an alias of `add` (#4206), but
			// `wheels packages add` works on every CLI version, so templates
			// that ship with every new app (via `wheels new`) advertise `add`.

			it("the generated app's _gitignore does not reference `wheels install`", () => {
				$requireRepoPath("cli/lucli/templates/app");
				var path = ExpandPath("/cli/lucli/templates/app/_gitignore");
				expect(FileExists(path)).toBeTrue();
				var contents = FileRead(path);
				expect(contents).notToInclude("wheels install");
			});

			it("the generated app's plugins/README does not reference `wheels packages install`", () => {
				$requireRepoPath("cli/lucli/templates/app");
				var path = ExpandPath("/cli/lucli/templates/app/plugins/README.md");
				expect(FileExists(path)).toBeTrue();
				var contents = FileRead(path);
				expect(contents).notToInclude("wheels packages install");
			});

			it("the generated app's plugins/README points at the canonical `wheels packages add` verb", () => {
				$requireRepoPath("cli/lucli/templates/app");
				var path = ExpandPath("/cli/lucli/templates/app/plugins/README.md");
				var contents = FileRead(path);
				expect(contents).toInclude("wheels packages add");
			});

		});

	}
}
