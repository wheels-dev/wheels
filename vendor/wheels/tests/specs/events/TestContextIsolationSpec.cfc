/**
 * S8: TestContext isolation (requestIsTestContext / isolated name) under
 * `wheels test --core --ci --filter=events`.
 *
 * TestRunnerIsolationSpec lives in internal/ and is OUT of this desk.
 * These specs prove the same contract from events/ so a --filter=events
 * run fails if isolation is reverted. Do not move or re-prove the
 * internal/ suite (S10 leftover territory for other leftover specs).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("S8 TestContext isolation (requestIsTestContext / isolated name)", () => {

			it("suffixes an application name exactly once", () => {
				var ctx = new wheels.events.TestContext();
				expect(ctx.applicationNameSuffix()).toBe("_wheelsTest");
				expect(ctx.isolatedApplicationName("wheels-dev")).toBe("wheels-dev_wheelsTest");
				expect(ctx.isolatedApplicationName("wheels-dev_wheelsTest")).toBe("wheels-dev_wheelsTest");
				expect(ctx.isIsolatedApplicationName("wheels-dev")).toBeFalse();
				expect(ctx.isIsolatedApplicationName("wheels-dev_wheelsTest")).toBeTrue();
			});

			// The path trigger is env-gated (development/testing only) AND
			// anchored to the request PATH (path_info/script_name) — a runner path
			// outside the request path is not treated as the runner.
			it("path trigger: honours /wheels/core|app/tests only under development/testing, anchored to the path", () => {
				var ctx = new wheels.events.TestContext();
				expect(
					ctx.requestIsTestContext(cgiScope = {path_info = "/wheels/core/tests"}, environment = "development")
				).toBeTrue();
				expect(
					ctx.requestIsTestContext(cgiScope = {script_name = "/index.cfm", path_info = "/wheels/app/tests"}, environment = "testing")
				).toBeTrue();
				// env gate: same path in production / unknown fails closed
				expect(
					ctx.requestIsTestContext(cgiScope = {path_info = "/wheels/core/tests"}, environment = "production")
				).toBeFalse("the env gate must fail closed in production");
				expect(
					ctx.requestIsTestContext(cgiScope = {path_info = "/wheels/core/tests"}, environment = "")
				).toBeFalse("an unknown environment must fail closed");
				// anchored: a runner path outside the request path is not treated as the runner
				expect(
					ctx.requestIsTestContext(cgiScope = {path_info = "/", script_name = "/index.cfm", query_string = "x=/wheels/core/tests"}, environment = "development")
				).toBeFalse("a runner path outside the request path must not trigger");
				expect(
					ctx.requestIsTestContext(cgiScope = {path_info = "/", script_name = "/index.cfm", request_url = "http://h/app?x=/wheels/app/tests"}, environment = "development")
				).toBeFalse("a runner path outside the request path (full URL) must not trigger");
				expect(
					ctx.requestIsTestContext(cgiScope = {path_info = "/", script_name = "/index.cfm"}, environment = "development")
				).toBeFalse();
			});

			// The header/cookie trigger now requires the per-process runner
			// secret (constant-time compare) AND a loopback socket peer, under
			// development/testing. A bare non-empty value is no longer enough.
			it("header/cookie trigger: requires the per-process secret AND a loopback peer, under dev/testing", () => {
				var ctx = new wheels.events.TestContext();
				var secret = ctx.testSecret();
				expect(Len(secret)).toBeGT(0, "testSecret() must return a non-empty per-process secret");

				var hdr = {};
				hdr[ctx.cgiHeaderKey()] = secret;
				expect(
					ctx.requestIsTestContext(cgiScope = hdr, environment = "development", expectedSecret = secret, remoteAddr = "127.0.0.1")
				).toBeTrue();
				// env gate still applies to the secret path
				expect(
					ctx.requestIsTestContext(cgiScope = hdr, environment = "production", expectedSecret = secret, remoteAddr = "127.0.0.1")
				).toBeFalse("the secret path is still env-gated");
				// correct secret but a non-loopback peer must never switch
				expect(
					ctx.requestIsTestContext(cgiScope = hdr, environment = "development", expectedSecret = secret, remoteAddr = "203.0.113.7")
				).toBeFalse("a non-loopback peer must never switch context");
				// the old bare value is rejected even from loopback
				var bad = {};
				bad[ctx.cgiHeaderKey()] = "1";
				expect(
					ctx.requestIsTestContext(cgiScope = bad, environment = "development", expectedSecret = secret, remoteAddr = "127.0.0.1")
				).toBeFalse("a non-secret header value must not switch context");
				// a wrong secret is rejected
				var wrong = {};
				wrong[ctx.cgiHeaderKey()] = "deadbeefdeadbeef";
				expect(
					ctx.requestIsTestContext(cgiScope = wrong, environment = "development", expectedSecret = secret, remoteAddr = "127.0.0.1")
				).toBeFalse();
				// cookie mirrors header (and ::1 loopback)
				var ck = {};
				ck[ctx.cookieName()] = secret;
				expect(
					ctx.requestIsTestContext(cookieScope = ck, environment = "development", expectedSecret = secret, remoteAddr = "::1")
				).toBeTrue();
				expect(
					ctx.requestIsTestContext(cookieScope = ck, environment = "development", expectedSecret = secret, remoteAddr = "10.0.0.5")
				).toBeFalse();
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

			it("helpers: environment allow-list, loopback detection, constant-time secret compare", () => {
				var ctx = new wheels.events.TestContext();
				expect(ctx.$environmentAllowsTestContext("development")).toBeTrue();
				expect(ctx.$environmentAllowsTestContext("testing")).toBeTrue();
				expect(ctx.$environmentAllowsTestContext("production")).toBeFalse();
				expect(ctx.$environmentAllowsTestContext("maintenance")).toBeFalse();
				expect(ctx.$environmentAllowsTestContext("")).toBeFalse();

				expect(ctx.$isLoopbackPeer("127.0.0.1")).toBeTrue();
				expect(ctx.$isLoopbackPeer("::1")).toBeTrue();
				expect(ctx.$isLoopbackPeer("203.0.113.7")).toBeFalse();
				expect(ctx.$isLoopbackPeer("")).toBeFalse();

				expect(ctx.$secureEquals("abc123", "abc123")).toBeTrue();
				expect(ctx.$secureEquals("abc123", "abc124")).toBeFalse();
				expect(ctx.$secureEquals("", "abc")).toBeFalse();
				expect(ctx.$secureEquals("abc", "")).toBeFalse();
			});

			it("testcontext.cfm and TestContext.cfc share suffix/header/cookie AND carry the test-context gate", () => {
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
				// Gate parity: the include must loopback-check the peer and compare the server secret,
				// and must read the runner path from path_info / script_name.
				expect(FindNoCase("remote_addr", includeSource) > 0).toBeTrue(
					"testcontext.cfm must read cgi.remote_addr for the loopback peer check"
				);
				expect(FindNoCase("isLoopbackAddress", includeSource) > 0).toBeTrue(
					"testcontext.cfm must verify a loopback peer"
				);
				expect(FindNoCase("$wheelsTestContextSecret", includeSource) > 0).toBeTrue(
					"testcontext.cfm must compare the per-process server secret"
				);
				expect(FindNoCase("query_string", includeSource)).toBe(
					0,
					"testcontext.cfm must read the runner path from path_info / script_name"
				);
				expect(FindNoCase("request_url", includeSource)).toBe(
					0,
					"testcontext.cfm must read the runner path from the request path fields"
				);
			});

			// Primary start backstop: an isolated (_wheelsTest) application must be
			// refused at onApplicationStart unless the config-resolved environment
			// is development or testing.
			it("startRefused: refuses an isolated app outside development/testing", () => {
				var ctx = new wheels.events.TestContext();
				expect(ctx.startRefused("blog_wheelsTest", "production")).toBeTrue();
				expect(ctx.startRefused("blog_wheelsTest", "maintenance")).toBeTrue();
				expect(ctx.startRefused("blog_wheelsTest", "")).toBeTrue("unknown env must refuse the isolated app");
				expect(ctx.startRefused("blog_wheelsTest", "development")).toBeFalse();
				expect(ctx.startRefused("blog_wheelsTest", "testing")).toBeFalse();
				// a normal (non-isolated) app is never refused by this gate
				expect(ctx.startRefused("blog", "production")).toBeFalse();
			});

			it("onapplicationstart.cfc carries the test-context start backstop before the app's side effects", () => {
				var src = FileRead(ExpandPath("/wheels/events/onapplicationstart.cfc"));
				// The backstop must key on the isolation suffix and the resolved environment,
				// clear the scope so a second request re-refuses, and abort with a 403.
				var markerPos = FindNoCase("Test-context start backstop", src);
				expect(markerPos).toBeGT(0, "onapplicationstart.cfc must carry the test-context start backstop");
				expect(FindNoCase("_wheelsTest", src) > 0).toBeTrue("backstop must test the isolation suffix");
				expect(FindNoCase("statuscode", Mid(src, markerPos, 1500)) > 0 || FindNoCase("403", Mid(src, markerPos, 1500)) > 0).toBeTrue(
					"backstop must emit a 403"
				);
				expect(FindNoCase("StructDelete(application", Mid(src, markerPos, 1500)) > 0).toBeTrue(
					"backstop must clear the application scope so a second request re-refuses"
				);
				// Ordering: the backstop must run BEFORE the app config/settings include,
				// the migrator, and the app's own onapplicationstart.cfm.
				var settingsPos = FindNoCase("/config/settings.cfm", src);
				expect(settingsPos).toBeGT(0);
				expect(markerPos).toBeLT(settingsPos, "the start backstop must run before the config/settings include");
			});

			it("the suite itself is bound to the isolated application name", () => {
				var ctx = new wheels.events.TestContext();
				expect(ctx.isIsolatedApplicationName(application.applicationName)).toBeTrue(
					"the web runner request must bind `<this.name>_wheelsTest` so application.wheels here is NOT the live app"
				);
			});

		});

	}

}
