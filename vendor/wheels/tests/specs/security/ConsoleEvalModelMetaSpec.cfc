/**
 * consoleeval model payloads must carry validation state so the CLI can
 * fail a piped `wheels console` session when `.create()` returns an
 * unsaved invalid model (the tutorial e2e flake: exit 0, then /posts
 * missing the title).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("consoleeval model result metadata", () => {

			it("attaches _hasErrors and _errors on model results", () => {
				var src = fileRead(expandPath("/wheels/public/views/consoleeval.cfm"));
				expect(src).toInclude("_hasErrors");
				expect(src).toInclude("_errors");
				expect(src).toInclude("hasErrors");
				expect(src).toInclude("allErrors");
			});

		});

	}

}
