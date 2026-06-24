component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that $resolveSubpathInclude (issue 3251)", () => {

			// The app test-runner template ships
			// `<cfinclude template="/wheels/tests/app-runner.cfm">`. The leading
			// `/wheels` resolves only when the app is mounted at the web root.
			// Under a CommandBox multi-subfolder / IIS-subfolder topology the
			// mapping does not resolve, so the include fails. $resolveSubpathInclude
			// rewrites a framework-relative include path against the resolved
			// `webPath` (the same subpath derivation as $resolveFrameworkPaths) so
			// the include works in both root and subfolder installs.

			it("returns the absolute path unchanged for a root install (webPath '/')", () => {
				expect(
					g.$resolveSubpathInclude(
						template = "/wheels/tests/app-runner.cfm",
						webPath   = "/"
					)
				).toBe("/wheels/tests/app-runner.cfm")
			})

			it("prefixes the subpath for a subfolder install", () => {
				expect(
					g.$resolveSubpathInclude(
						template = "/wheels/tests/app-runner.cfm",
						webPath   = "/wheelsproject1/"
					)
				).toBe("/wheelsproject1/wheels/tests/app-runner.cfm")
			})

			it("handles a nested subpath", () => {
				expect(
					g.$resolveSubpathInclude(
						template = "/wheels/tests/app-runner.cfm",
						webPath   = "/team/site/"
					)
				).toBe("/team/site/wheels/tests/app-runner.cfm")
			})

			it("normalizes a webPath missing its trailing slash", () => {
				expect(
					g.$resolveSubpathInclude(
						template = "/wheels/tests/app-runner.cfm",
						webPath   = "/wheelsproject1"
					)
				).toBe("/wheelsproject1/wheels/tests/app-runner.cfm")
			})

			it("falls back to '/' when webPath is empty", () => {
				expect(
					g.$resolveSubpathInclude(
						template = "/wheels/tests/app-runner.cfm",
						webPath   = ""
					)
				).toBe("/wheels/tests/app-runner.cfm")
			})

			it("tolerates a template that omits its leading slash", () => {
				expect(
					g.$resolveSubpathInclude(
						template = "wheels/tests/app-runner.cfm",
						webPath   = "/wheelsproject1/"
					)
				).toBe("/wheelsproject1/wheels/tests/app-runner.cfm")
			})

			it("uses application.wheels.webPath when no webPath argument is passed (the production call shape)", () => {
				// The shipped runner template (cli/lucli/templates/app/tests/runner.cfm)
				// calls this with NO webPath argument, so the fallback branch that reads
				// application.wheels.webPath is the only path real callers take. Pin it by
				// asserting the no-arg result equals an explicit call passing the current
				// webPath — this exercises the previously-uncovered branch without mutating
				// global app state.
				expect(
					g.$resolveSubpathInclude(template = "/wheels/tests/app-runner.cfm")
				).toBe(
					g.$resolveSubpathInclude(template = "/wheels/tests/app-runner.cfm", webPath = application.wheels.webPath)
				)
			})

		})
	}
}
