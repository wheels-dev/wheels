/**
 * The framework runners' default datasource in an app (one made with `wheels new`, which
 * sets dataSourceName in config/settings.cfm and no coreTestDataSourceName): the default
 * follows the dataSourceName the settings files set, so the run takes the
 * `<datasource>_test` rule instead of a datasource named after the app's folder. A
 * coreTestDataSourceName that names a datasource that does not exist is refused with a
 * message instead of the engine's error.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("$defaultCoreTestDataSourceName()", () => {

			it("defaults coreTestDataSourceName to the dataSourceName the settings set", () => {
				var settings = {dataSourceName = "app"};
				g.$defaultCoreTestDataSourceName(settings);
				expect(settings.coreTestDataSourceName).toBe("app");
			});

			it("keeps a coreTestDataSourceName the settings set", () => {
				var settings = {dataSourceName = "wheels-dev", coreTestDataSourceName = "wheels-dev"};
				g.$defaultCoreTestDataSourceName(settings);
				expect(settings.coreTestDataSourceName).toBe("wheels-dev");
				var other = {dataSourceName = "app", coreTestDataSourceName = "app_core"};
				g.$defaultCoreTestDataSourceName(other);
				expect(other.coreTestDataSourceName).toBe("app_core");
			});

			it("runs after the settings files load, with no default before them", () => {
				var source = FileRead(ExpandPath("/wheels/events/onapplicationstart.cfc"));
				var settingsLoad = Find('$includeConfig(template = "/config/##application.$wheels.environment##/settings.cfm")', source);
				var defaultCall = Find("application.wo.$defaultCoreTestDataSourceName(application.$wheels)", source);
				expect(settingsLoad).toBeGT(0);
				expect(defaultCall).toBeGT(settingsLoad);
				expect(Find("application.$wheels.coreTestDataSourceName = application.$wheels.dataSourceName", source)).toBe(0);
			});

			it("sends a fresh app's run to <datasource>_test", () => {
				var settings = {dataSourceName = "app"};
				g.$defaultCoreTestDataSourceName(settings);
				var choice = g.$coreTestDataSource(
					primary = settings.dataSourceName,
					coreName = settings.coreTestDataSourceName,
					requestUrl = {},
					candidateRegistered = true
				);
				expect(choice.action).toBe("swap");
				expect(choice.target).toBe("app_test");
			});

		});

		describe("$coreTestDataSource() with a coreTestDataSourceName that does not exist", () => {

			it("refuses with the three remedies", () => {
				var choice = g.$coreTestDataSource(primary = "app", coreName = "public", requestUrl = {}, targetRegistered = false);
				expect(choice.action).toBe("refuse");
				expect(choice.target).toBe("");
				expect(choice.message).toInclude("'public'");
				expect(choice.message).toInclude("coreTestDataSourceName");
				expect(choice.message).toInclude("create 'public'");
				expect(choice.message).toInclude("?db=");
			});

			it("uses it when it exists", () => {
				var choice = g.$coreTestDataSource(primary = "app", coreName = "app_core", requestUrl = {}, targetRegistered = true);
				expect(choice.action).toBe("use");
				expect(choice.target).toBe("app_core");
			});

			it("treats a coreTestDataSourceName differing from dataSourceName only in case as the primary", () => {
				var choice = g.$coreTestDataSource(primary = "app", coreName = "App", requestUrl = {}, candidateRegistered = true, targetRegistered = true);
				expect(choice.action).toBe("swap");
				expect(choice.target).toBe("app_test");
			});

			it("still explains a refusal on the primary datasource", () => {
				var choice = g.$coreTestDataSource(primary = "app", coreName = "app", requestUrl = {}, candidateRegistered = false);
				expect(choice.action).toBe("refuse");
				expect(choice.message).toInclude("primary datasource 'app'");
				expect(choice.message).toInclude("create 'app_test'");
			});

			it("is what both framework runners report", () => {
				for (var path in ["/wheels/tests/runner.cfm", "/wheels/rocketunit_tests/env.cfm"]) {
					var source = FileRead(ExpandPath(path));
					expect(FindNoCase("SerializeJSON(", source) && FindNoCase("$coreTestDataSourceRefusal(choice = ", source)).toBeTrue(path);
				}
			});

		});

		describe("409 bodies of the test runners", () => {

			it("keep their keys lowercase for a refused framework run", () => {
				var choice = g.$coreTestDataSource(primary = "app", coreName = "public", requestUrl = {}, targetRegistered = false);
				var body = SerializeJSON(g.$coreTestDataSourceRefusal(choice = choice));
				// Find() is case-sensitive.
				for (var key in ["success", "error", "message", "datasource", "candidate"]) {
					expect(Find('"' & key & '"', body)).toBeGT(0, body);
					expect(Find('"' & UCase(key) & '"', body)).toBe(0, body);
				}
				expect(DeserializeJSON(body).message).toBe(choice.message);
			});

			it("keep their keys lowercase for a refused app run", () => {
				var body = SerializeJSON(g.$testDataSourceRefusal(decision = {primary = "app", candidate = "app_test"}));
				for (var key in ["success", "error", "message", "datasource", "candidate"]) {
					expect(Find('"' & key & '"', body)).toBeGT(0, body);
					expect(Find('"' & UCase(key) & '"', body)).toBe(0, body);
				}
			});

		});

	}

}
