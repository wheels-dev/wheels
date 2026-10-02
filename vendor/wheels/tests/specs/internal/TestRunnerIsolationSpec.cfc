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

				// Env-gated (dev/testing) + path anchored to path_info/script_name.
				it("treats /wheels/core/tests and /wheels/app/tests paths as test context", () => {
					var ctx = new wheels.events.TestContext();
					expect(
						ctx.requestIsTestContext(cgiScope = {path_info = "/wheels/core/tests"}, environment = "development")
					).toBeTrue();
					expect(
						ctx.requestIsTestContext(cgiScope = {script_name = "/index.cfm", path_info = "/wheels/app/tests"}, environment = "testing")
					).toBeTrue();
					// env gate: production / unknown fails closed
					expect(
						ctx.requestIsTestContext(cgiScope = {path_info = "/wheels/core/tests"}, environment = "production")
					).toBeFalse("the env gate must fail closed in production");
					// anchored: a runner path in the query string must not trigger
					expect(
						ctx.requestIsTestContext(cgiScope = {path_info = "/", script_name = "/index.cfm", query_string = "x=/wheels/core/tests"}, environment = "development")
					).toBeFalse("a query-string runner path is not a test context");
					expect(
						ctx.requestIsTestContext(cgiScope = {path_info = "/", script_name = "/index.cfm"}, environment = "development")
					).toBeFalse();
				});

				// The header/cookie now needs the per-process secret + a loopback peer.
				it("treats the isolation header or cookie as test context only with the secret and a loopback peer", () => {
					var ctx = new wheels.events.TestContext();
					var secret = ctx.testSecret();
					var cgiArgs = {};
					cgiArgs[ctx.cgiHeaderKey()] = secret;
					expect(ctx.requestIsTestContext(cgiScope = cgiArgs, environment = "development", expectedSecret = secret, remoteAddr = "127.0.0.1")).toBeTrue();
					// a bare "1" from loopback is rejected
					var bad = {};
					bad[ctx.cgiHeaderKey()] = "1";
					expect(ctx.requestIsTestContext(cgiScope = bad, environment = "development", expectedSecret = secret, remoteAddr = "127.0.0.1")).toBeFalse();
					// the secret from a non-loopback peer is rejected
					expect(ctx.requestIsTestContext(cgiScope = cgiArgs, environment = "development", expectedSecret = secret, remoteAddr = "203.0.113.7")).toBeFalse();

					var cookieArgs = {};
					cookieArgs[ctx.cookieName()] = secret;
					expect(ctx.requestIsTestContext(cookieScope = cookieArgs, environment = "development", expectedSecret = secret, remoteAddr = "::1")).toBeTrue();
				});

				it("does not treat an empty header or cookie as test context", () => {
					var ctx = new wheels.events.TestContext();
					var secret = ctx.testSecret();
					var cgiArgs = {};
					cgiArgs[ctx.cgiHeaderKey()] = "";
					expect(ctx.requestIsTestContext(cgiScope = cgiArgs, environment = "development", expectedSecret = secret, remoteAddr = "127.0.0.1")).toBeFalse();

					var cookieArgs = {};
					cookieArgs[ctx.cookieName()] = "";
					expect(ctx.requestIsTestContext(cookieScope = cookieArgs, environment = "development", expectedSecret = secret, remoteAddr = "127.0.0.1")).toBeFalse();
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
					// Resolve the demo app via the /config mapping. Do not walk
					// GetDirectoryFromPath() on an already-directory path —
					// a trailing slash is a no-op walk on Lucee, which left
					// repoRoot at vendor/wheels/events/ and missed both files.
					var configDir = GetDirectoryFromPath(ExpandPath("/config/app.cfm"));
					var last = Right(configDir, 1);
					if (last == "/" || last == "\") {
						configDir = Left(configDir, Len(configDir) - 1);
					}
					var repoRoot = GetDirectoryFromPath(configDir);
					var files = [
						repoRoot & "public/Application.cfc",
						ExpandPath("/cli/lucli/templates/app/public/Application.cfc")
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

				// Every sender sends the per-process secret, not a bare "1".
				it("BrowserTest sends the runner secret in both the header and the cookie fallback", () => {
					var source = FileRead(ExpandPath("/wheels/wheelstest/BrowserTest.cfc"));
					expect(FindNoCase("testSecret()", source) > 0).toBeTrue(
						"BrowserTest must send ctx.testSecret() (header AND cookie fallback)"
					);
					// the cookie fallback must send the secret, not a literal "1"
					expect(FindNoCase("setCookie(name = ctx.cookieName(), value = ctx.testSecret()", source) > 0).toBeTrue(
						"BrowserTest cookie fallback must send the secret, not a literal 1"
					);
				});

				// App-runner fails closed when the test DB is requested but absent.
				it("app-runner.cfm fails closed when the requested test database is not registered", () => {
					var source = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
					// the default (omitted flag) is the test DB: true unless explicit false
					expect(FindNoCase("local.useTestDB = !(local.testDBValidBool", source) > 0).toBeTrue(
						"app-runner must default an omitted useTestDB to the test database (false only on explicit valid false)"
					);
					// and there must be an else-branch that refuses (no silent real-DB run)
					var swapPos = FindNoCase("StructKeyExists(local.registered, local.candidate)", source);
					expect(swapPos).toBeGT(0);
					var window = Mid(source, swapPos, 4000);
					expect(FindNoCase("Test database not available", window) > 0).toBeTrue(
						"app-runner must refuse when <datasource>_test is absent"
					);
					expect(FindNoCase("abort", window) > 0).toBeTrue(
						"the refusal must abort before running specs against the primary datasource"
					);
					// Precedence: an explicit useTestDB=true can never be weakened by the
					// compatibility setting; only an omitted flag consults it.
					expect(FindNoCase("testDBExplicitTrue", source) > 0).toBeTrue(
						"app-runner must distinguish an explicit useTestDB=true from an omitted flag"
					);
					// Presence must be separate from validity: a present-but-invalid value
					// is NOT omitted and cannot use the compat fallback.
					expect(FindNoCase("testDBParamPresent", source) > 0).toBeTrue(
						"app-runner must track parameter PRESENCE separately from boolean validity"
					);
					expect(FindNoCase("allowTestsAgainstPrimaryDatasource", window) > 0).toBeTrue(
						"the omitted-flag path must consult allowTestsAgainstPrimaryDatasource"
					);
					expect(FindNoCase("local.testDBOmitted && local.allowPrimary", window) > 0).toBeTrue(
						"run-against-primary must require a TRULY-OMITTED flag AND the opt-out setting"
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

				// Behaviour proof (RED on the earlier code, where any non-empty
				// header bound the isolated app): a non-secret X-Wheels-Test-Context value
				// (not the per-process runner secret) must bind the LIVE application.
				it("a non-secret X-Wheels-Test-Context value binds the live application, not the isolated one", () => {
					var ctx = new wheels.events.TestContext();
					var nonSecret = $testClient(testContext = false);
					nonSecret.withHeader(ctx.headerName(), "1");
					nonSecret.get(path = "/wheels/info", params = {format = "json"});
					expect(nonSecret.statusCode()).toBe(200, "live /wheels/info?format=json must be reachable");
					var payload = nonSecret.json();
					expect(StructKeyExists(payload, "application") && StructKeyExists(payload.application, "name")).toBeTrue();
					expect(ctx.isIsolatedApplicationName(payload.application.name)).toBeFalse(
						"a non-secret `#ctx.headerName()#: 1` (not the runner secret) must bind the LIVE app, not `<name>_wheelsTest` — saw `#payload.application.name#`"
					);
				});

				// Behaviour proof (RED on the earlier code, where the haystack included
				// the query string): the runner path smuggled through the query string
				// must NOT bind the isolated application (the trigger is path-anchored).
				it("a runner path in the query string binds the live application, not the isolated one", () => {
					var ctx = new wheels.events.TestContext();
					var live = $testClient(testContext = false);
					// Raw in the URL so the slashes reach cgi.query_string un-encoded
					// (the runner path appears only in the query string).
					live.get(path = "/wheels/info?format=json&x=/wheels/app/tests");
					expect(live.statusCode()).toBe(200, "live /wheels/info must be reachable");
					var payload = live.json();
					expect(StructKeyExists(payload, "application") && StructKeyExists(payload.application, "name")).toBeTrue();
					expect(ctx.isIsolatedApplicationName(payload.application.name)).toBeFalse(
						"a `/wheels/app/tests` runner path in the QUERY STRING must bind the LIVE app, not `<name>_wheelsTest` — saw `#payload.application.name#`"
					);
				});

			});

		});
	}
}
