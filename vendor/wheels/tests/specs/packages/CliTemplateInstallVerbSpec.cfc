component extends="wheels.WheelsTest" {

	function run() {

		describe("Generated app templates — package install verb", () => {

			// Regression guard for issue #2610: `wheels packages install <name>`
			// is intercepted by LuCLI's built-in extension installer and never
			// reaches Module.cfc, so it prints "No git or extension
			// dependencies to install" and exits without installing anything.
			// The canonical install verb is `wheels packages add`. Templates
			// that ship with every new app (via `wheels new`) must not
			// advertise the broken verb.

			it("the generated app's _gitignore does not reference `wheels install`", () => {
				var path = ExpandPath("/cli/lucli/templates/app/_gitignore");
				expect(FileExists(path)).toBeTrue();
				var contents = FileRead(path);
				expect(contents).notToInclude("wheels install");
			});

			it("the generated app's plugins/README does not reference `wheels packages install`", () => {
				var path = ExpandPath("/cli/lucli/templates/app/app/plugins/README.md");
				expect(FileExists(path)).toBeTrue();
				var contents = FileRead(path);
				expect(contents).notToInclude("wheels packages install");
			});

			it("the generated app's plugins/README points at the canonical `wheels packages add` verb", () => {
				var path = ExpandPath("/cli/lucli/templates/app/app/plugins/README.md");
				var contents = FileRead(path);
				expect(contents).toInclude("wheels packages add");
			});

		});

	}
}
