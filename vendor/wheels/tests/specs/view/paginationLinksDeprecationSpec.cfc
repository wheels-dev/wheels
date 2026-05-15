/**
 * Regression for issue ##2714: `paginationLinks()` is documented as
 * deprecated in favor of `paginationNav()` (per ##1930), but emits no
 * runtime warning and is invisible to `wheels upgrade check`.
 *
 * Two assertions:
 *
 *   1. The first call to `paginationLinks()` within a request sets a
 *      request-scoped guard flag (`request.wheels.$paginationLinksDeprecationLogged`).
 *      The flag is what gates the one-time `WriteLog(type="warning", ...)`
 *      call so the deprecation surfaces once per request, not on every
 *      render in a loop.
 *
 *   2. The 3.x -> 4.x scan rules in `cli/lucli/Module.cfc` include a
 *      `paginationLinks` grep so `wheels upgrade check --to=4.0.0`
 *      flags apps still calling the deprecated helper. Mirrors the
 *      static-inspection pattern used by `UpgradeCheckCoverageSpec`.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("paginationLinks deprecation surface", () => {

			beforeEach(() => {
				_params = {controller = "dummy", action = "dummy"}
				_controller = g.controller("dummy", _params)
				g.set(functionName = "paginationLinks", encode = false)
				structDelete(request.wheels, "$paginationLinksDeprecationLogged")
			})

			afterEach(() => {
				g.set(functionName = "paginationLinks", encode = true)
				structDelete(request.wheels, "$paginationLinksDeprecationLogged")
			})

			describe("runtime warning", () => {

				it("sets a request-scoped guard flag on first call", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					expect(structKeyExists(request.wheels, "$paginationLinksDeprecationLogged")).toBeFalse()
					_controller.paginationLinks()
					expect(structKeyExists(request.wheels, "$paginationLinksDeprecationLogged")).toBeTrue()
					expect(request.wheels.$paginationLinksDeprecationLogged).toBeTrue()
				})

				it("does not re-log when called multiple times in the same request", () => {
					g.model("author").findAll(page = 2, perPage = 3, order = "lastName")
					_controller.paginationLinks()
					request.wheels.$paginationLinksDeprecationLogged = "first"
					_controller.paginationLinks()
					expect(request.wheels.$paginationLinksDeprecationLogged).toBe("first")
				})

			})

			describe("upgrade-check coverage", () => {

				it("3.x -> 4.x scan rules in Module.cfc grep for paginationLinks", () => {
					// expandPath("/wheels") resolves to vendor/wheels via the
					// configured Lucee mapping; the repo root is two levels above.
					var repoRoot = expandPath("/wheels/../..")
					var modulePath = repoRoot & "/cli/lucli/Module.cfc"
					expect(fileExists(modulePath)).toBeTrue("Missing: " & modulePath)

					var moduleSource = fileRead(modulePath)
					var start = find("currentMajor <= 3 && targetMajor >= 4", moduleSource)
					expect(start > 0).toBeTrue("3.x -> 4.x branch not found in Module.cfc")

					var endIdx = find("// Run checks", moduleSource, start)
					var sliceLen = endIdx > 0 ? endIdx - start : len(moduleSource) - start + 1
					var block = sliceLen > 0 ? mid(moduleSource, start, sliceLen) : ""

					expect(findNoCase("paginationLinks", block) > 0).toBeTrue(
						"3.x -> 4.x checks should grep app views for paginationLinks( so apps still using the deprecated helper get flagged by 'wheels upgrade check --to=4.0.0'. See issue ##2714."
					)
				})

			})

		})

	}

}
