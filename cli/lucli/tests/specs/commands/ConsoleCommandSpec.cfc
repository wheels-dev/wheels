/**
 * Regression for the `/models`, `/routes`, `/version`, `/datasource`
 * console commands. They route through `consoleExec`, which previously
 * declared a `required string url` parameter that the CFML URL scope
 * shadowed — `makeHttpPost(url, body)` then received the URL scope
 * struct and threw "Cannot cast Object type [url] to a value of type
 * [string]".
 *
 * Regression cover is source-level: `consoleExec` is private and makes
 * a real HTTP call, so the cheapest accurate check is asserting the
 * parameter name no longer collides with the reserved scope. See
 * `ReloadCommandSpec.cfc` for the same source-inspection pattern.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("Module.cfc::consoleExec — reserved-scope shadowing", () => {

			it("does not declare a bare `url` parameter that the URL scope would shadow", () => {
				var moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
				var pattern = "function consoleExec\(\s*required\s+string\s+url\b";
				expect(reFind(pattern, moduleSource) > 0).toBeFalse(
					"consoleExec must not use `url` as a parameter name — it collides with the CFML URL scope and breaks /models, /routes, /version, /datasource (issue ##2582)."
				);
			});

			it("does not pass a bare `url` reference into makeHttpPost", () => {
				var moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
				expect(moduleSource).notToInclude(
					"makeHttpPost(url,",
					"makeHttpPost must receive an unshadowed string argument; bare `url` resolves to the URL scope struct on a request."
				);
			});

		});

	}

}
