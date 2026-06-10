component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that $resolveFrameworkPaths", () => {

			it("derives paths from cgi.script_name when no subpath given (root install)", () => {
				rv = g.$resolveFrameworkPaths(scriptName = "/index.cfm")

				expect(rv.webPath).toBe("/")
				expect(rv.rootPath).toBe("/")
				expect(rv.rootcomponentPath).toBe("")
				expect(rv.wheelsComponentPath).toBe("wheels")
			})

			it("derives paths from cgi.script_name when no subpath given (legacy /public/ folding)", () => {
				rv = g.$resolveFrameworkPaths(scriptName = "/wheelsproject1/public/index.cfm")

				expect(rv.webPath).toBe("/wheelsproject1/public/")
				expect(rv.rootPath).toBe("/wheelsproject1/public")
				expect(rv.rootcomponentPath).toBe("wheelsproject1.public")
				expect(rv.wheelsComponentPath).toBe("wheelsproject1.public.wheels")
			})

			it("overrides paths when subpath setting is provided", () => {
				rv = g.$resolveFrameworkPaths(
					scriptName = "/wheelsproject1/public/index.cfm",
					subpath = "/wheelsproject1"
				)

				expect(rv.webPath).toBe("/wheelsproject1/")
				expect(rv.rootPath).toBe("/wheelsproject1")
				expect(rv.rootcomponentPath).toBe("wheelsproject1")
				expect(rv.wheelsComponentPath).toBe("wheelsproject1.wheels")
			})

			it("normalizes subpath with trailing slash", () => {
				rv = g.$resolveFrameworkPaths(
					scriptName = "/wheelsproject1/public/index.cfm",
					subpath = "/wheelsproject1/"
				)

				expect(rv.webPath).toBe("/wheelsproject1/")
				expect(rv.rootPath).toBe("/wheelsproject1")
			})

			it("normalizes subpath missing leading slash", () => {
				rv = g.$resolveFrameworkPaths(
					scriptName = "/anything.cfm",
					subpath = "wheelsproject1"
				)

				expect(rv.webPath).toBe("/wheelsproject1/")
				expect(rv.rootPath).toBe("/wheelsproject1")
				expect(rv.wheelsComponentPath).toBe("wheelsproject1.wheels")
			})

			it("handles nested subpath", () => {
				rv = g.$resolveFrameworkPaths(
					scriptName = "/anything/public/index.cfm",
					subpath = "/team/site"
				)

				expect(rv.webPath).toBe("/team/site/")
				expect(rv.rootPath).toBe("/team/site")
				expect(rv.rootcomponentPath).toBe("team.site")
				expect(rv.wheelsComponentPath).toBe("team.site.wheels")
			})

			it("treats subpath of '/' as a root install", () => {
				rv = g.$resolveFrameworkPaths(
					scriptName = "/wheelsproject1/public/index.cfm",
					subpath = "/"
				)

				expect(rv.webPath).toBe("/")
				expect(rv.rootPath).toBe("/")
				expect(rv.rootcomponentPath).toBe("")
				expect(rv.wheelsComponentPath).toBe("wheels")
			})

			it("falls back to script_name derivation when subpath is empty string", () => {
				rv = g.$resolveFrameworkPaths(
					scriptName = "/wheelsproject1/public/index.cfm",
					subpath = ""
				)

				expect(rv.webPath).toBe("/wheelsproject1/public/")
			})

		})
	}
}
