/**
 * Guards for issue #3374: the web test runner must not mutate the live
 * application's application.wheels. A request-scoped overlay cannot re-bake
 * dialect adapters, the app-scoped model cache, or routes (blockers B1–B9
 * on #3025). Isolation is a second CFML application name, derived in
 * Application.cfc's constructor via events/testcontext.cfm.
 *
 * Coverage:
 *
 * 1. Unit — wheels.events.TestContext path / header / cookie detection
 *    (no HTTP, no second application).
 * 2. Structural — testcontext.cfm, Application.cfc (demo + wheels new
 *    template), WheelsTest.$testClient, and runner.cfm stay wired together.
 * 3. Behavioral — this suite is already inside the isolated application
 *    (name ends with _wheelsTest). A TestClient request WITHOUT the
 *    isolation marker hits /wheels/info on the LIVE application and must
 *    see a different application name.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Web test-runner application isolation (issue ##3374)", () => {

			describe("TestContext detection", () => {

				it("suffixes an application name exactly once", () => {
					var ctx = new wheels.events.TestContext();
					expect(ctx.applicationNameSuffix()).toBe("_wheelsTest");
					expect(ctx.isolatedApplicationName("wheels-dev")).toBe("wheels-dev_wheelsTest");
					expect(ctx.isolatedApplicationName("wheels-dev_wheelsTest")).toBe("wheels-dev_wheelsTest");
					expect(ctx.isIsolatedApplicationName("wheels-dev")).toBeFalse();
					expect(ctx.isIsolatedApplicationName("wheels-dev_wheelsTest")).toBeTrue();
				});

				it("treats /wheels/core/tests and /wheels/app/tests paths as test context", () => {
					var ctx = new wheels.events.TestContext();
					expect(
						ctx.requestIsTestContext(cgiScope = {path_info = "/wheels/core/tests"})
					).toBeTrue();
					expect(
						ctx.requestIsTestContext(cgiScope = {script_name = "/index.cfm", path_info = "/wheels/app/tests"})
					).toBeTrue();
					expect(
						ctx.requestIsTestContext(cgiScope = {query_string = "controller=wheels&view=core/tests"})
					).toBeFalse("a query string without the runner path is not a test context");
					expect(
						ctx.requestIsTestContext(cgiScope = {path_info = "/", script_name = "/index.cfm"})
					).toBeFalse();
				});

				it("treats the isolation header or cookie as test context", () => {
					var ctx = new wheels.events.TestContext();
					var cgiArgs = {};
					cgiArgs[ctx.cgiHeaderKey()] = "1";
					expect(ctx.requestIsTestContext(cgiScope = cgiArgs)).toBeTrue();

					var cookieArgs = {};
					cookieArgs[ctx.cookieName()] = "1";
					expect(ctx.requestIsTestContext(cookieScope = cookieArgs)).toBeTrue();
				});

				it("does not treat an empty header or cookie as test context", () => {
					var ctx = new wheels.events.TestContext();
					var cgiArgs = {};
					cgiArgs[ctx.cgiHeaderKey()] = "";
					expect(ctx.requestIsTestContext(cgiScope = cgiArgs)).toBeFalse();

					var cookieArgs = {};
					cookieArgs[ctx.cookieName()] = "";
					expect(ctx.requestIsTestContext(cookieScope = cookieArgs)).toBeFalse();
				});

			});

			describe("wiring", () => {

				it("testcontext.cfm and TestContext.cfc share suffix, header CGI key, and cookie name", () => {
					var ctx = new wheels.events.TestContext();
					var includeSource = FileRead(ExpandPath("/wheels/events/testcontext.cfm"));
					expect(Find(ctx.applicationNameSuffix(), includeSource) > 0).toBeTrue(
						"testcontext.cfm must use the same application-name suffix as TestContext.cfc"
					);
					expect(FindNoCase(ctx.cgiHeaderKey(), includeSource) > 0).toBeTrue(
						"testcontext.cfm must read the same CGI header key as TestContext.cgiHeaderKey()"
					);
					expect(FindNoCase(ctx.cookieName(), includeSource) > 0).toBeTrue(
						"testcontext.cfm must read the same cookie name as TestContext.cookieName()"
					);
					expect(FindNoCase("/wheels/core/tests", includeSource) > 0).toBeTrue();
					expect(FindNoCase("/wheels/app/tests", includeSource) > 0).toBeTrue();
				});

				it("demo and wheels-new Application.cfc include testcontext.cfm after config/app.cfm", () => {
					// /wheels → vendor/wheels; walk up to the repo root without
					// relying on ExpandPath("..") which some engines refuse.
					var eventsDir = GetDirectoryFromPath(ExpandPath("/wheels/events/testcontext.cfm"));
					var wheelsDir = GetDirectoryFromPath(eventsDir);
					var vendorDir = GetDirectoryFromPath(wheelsDir);
					var repoRoot = GetDirectoryFromPath(vendorDir);
					var files = [
						repoRoot & "public/Application.cfc",
						repoRoot & "cli/lucli/templates/app/public/Application.cfc"
					];
					for (var filePath in files) {
						expect(FileExists(filePath)).toBeTrue("expected Application.cfc at #filePath#");
						var source = FileRead(filePath);
						var appIncludePos = FindNoCase("config/app.cfm", source);
						var testIncludePos = FindNoCase("events/testcontext.cfm", source);
						expect(appIncludePos > 0).toBeTrue("#filePath# must include config/app.cfm");
						expect(testIncludePos > 0).toBeTrue(
							"#filePath# must include vendor/wheels/events/testcontext.cfm (issue ##3374)"
						);
						expect(testIncludePos > appIncludePos).toBeTrue(
							"#filePath# must include testcontext.cfm AFTER config/app.cfm so this.name is finalized"
						);
					}
				});

				it("WheelsTest.$testClient sends the isolation header by default", () => {
					var source = FileRead(ExpandPath("/wheels/WheelsTest.cfc"));
					expect(Find("testContext", source) > 0).toBeTrue(
						"WheelsTest.$testClient must accept a testContext argument"
					);
					expect(FindNoCase("headerName()", source) > 0 || FindNoCase("X-Wheels-Test-Context", source) > 0).toBeTrue(
						"WheelsTest.$testClient must send the isolation header so fixture HTTP binds the test application"
					);
				});

				it("runner.cfm documents the isolated application name and keeps the named-lock fallback", () => {
					var source = FileRead(ExpandPath("/wheels/tests/runner.cfm"));
					expect(FindNoCase("_wheelsTest", source) > 0).toBeTrue(
						"runner.cfm must mention the isolated application-name suffix"
					);
					expect(FindNoCase("wheelsTestRunner_", source) > 0).toBeTrue(
						"runner.cfm must keep the exclusive named lock as the fallback for apps without the Application.cfc snippet"
					);
				});

			});

			describe("in-flight isolation", () => {

				it("the suite itself is bound to the isolated application name", () => {
					var ctx = new wheels.events.TestContext();
					expect(ctx.isIsolatedApplicationName(application.applicationName)).toBeTrue(
						"the web runner request must bind `<this.name>_wheelsTest` so application.wheels here is NOT the live app (issue ##3374). If this fails, Application.cfc is not including events/testcontext.cfm."
					);
				});

				it("a concurrent request without the test marker sees the live application name", () => {
					// This spec runs inside the isolated application. A TestClient
					// with testContext=false omits the header and cookie and hits
					// a non-runner path, so Application.cfc must bind the LIVE
					// application name.
					var live = $testClient(testContext = false);
					live.get(path = "/wheels/info", params = {format = "json"});
					expect(live.statusCode()).toBe(
						200,
						"live /wheels/info?format=json must be reachable (development GUI)"
					);

					var payload = live.json();
					expect(IsStruct(payload)).toBeTrue(" /wheels/info?format=json must return a struct");
					expect(StructKeyExists(payload, "application")).toBeTrue();
					expect(StructKeyExists(payload.application, "name")).toBeTrue();

					var ctx = new wheels.events.TestContext();
					expect(ctx.isIsolatedApplicationName(payload.application.name)).toBeFalse(
						"a normal request must not bind the isolated test application — saw `#payload.application.name#` (issue ##3374)"
					);
					expect(payload.application.name).notToBe(
						application.applicationName,
						"live and test requests must use different CFML application names"
					);
				});

			});

		});
	}
}
