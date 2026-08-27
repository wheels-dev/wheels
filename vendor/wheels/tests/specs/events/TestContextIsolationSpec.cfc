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

			it("the suite itself is bound to the isolated application name", () => {
				var ctx = new wheels.events.TestContext();
				expect(ctx.isIsolatedApplicationName(application.applicationName)).toBeTrue(
					"the web runner request must bind `<this.name>_wheelsTest` so application.wheels here is NOT the live app"
				);
			});

		});

	}

}
