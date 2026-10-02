/**
 * $settingsDataSourceName() reads the datasource out of config/settings.cfm for
 * `wheels info` and the `wheels test` preamble. CFML accepts single quotes, but
 * only the double-quoted forms were read (#3952).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		if (fileExists(variables.tempRoot & "/.env")) fileDelete(variables.tempRoot & "/.env");
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {
		describe("datasource name in config/settings.cfm", () => {
			it("reads a double-quoted literal", () => {
				expect(mod.$settingsDataSourceName('set(dataSourceName="live");')).toBe("live");
			});

			it("reads a single-quoted literal", () => {
				expect(mod.$settingsDataSourceName("set(dataSourceName='live');")).toBe("live");
			});

			it("reads the env() default in either quote style", () => {
				expect(mod.$settingsDataSourceName('set(dataSourceName=env("WHEELS_DATASOURCE", "fallback"));')).toBe("fallback");
				expect(mod.$settingsDataSourceName("set(dataSourceName=env('WHEELS_DATASOURCE', 'fallback'));")).toBe("fallback");
				expect(mod.$settingsDataSourceName("set(dataSourceName=env('WHEELS_DATASOURCE', ""fallback""));")).toBe("fallback");
			});

			it("prefers the .env value for the env() form, in either quote style", () => {
				fileWrite(variables.tempRoot & "/.env", "WHEELS_DATASOURCE=fromenv" & chr(10));
				try {
					expect(mod.$settingsDataSourceName("set(dataSourceName=env('WHEELS_DATASOURCE', 'fallback'));")).toBe("fromenv");
				} finally {
					fileDelete(variables.tempRoot & "/.env");
				}
			});

			it("does not read mismatched quotes", () => {
				expect(mod.$settingsDataSourceName("set(dataSourceName=""live');")).toBe("");
			});
		});
	}

}
