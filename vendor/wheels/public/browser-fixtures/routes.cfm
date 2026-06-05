<cfscript>
/**
 * Browser-test fixture routes
 *
 * Mounted by `vendor/wheels/Global.cfc::$lockedLoadRoutes` when:
 *   - `application.wheels.environment` is `testing` or `development`, AND
 *   - `application.wheels.loadBrowserTestFixtures` is `true` (opt-in)
 *
 * Provides the `/_browser/*` routes used by the browser-testing DSL
 * (`wheels.wheelstest.BrowserTest`) for loginAs / logout / dashboard
 * happy-path specs. The fixture controllers + views live alongside this
 * file at `vendor/wheels/public/browser-fixtures/{controllers,views}/`;
 * the framework's controller/view resolver appends those directories to
 * the search path when the fixtures are active.
 *
 * The `/_browser/login-as` route's handler is configurable. By default
 * it dispatches to the framework's `BrowserTestLogin##create`, which
 * writes a minimal `session.userId` / `session.userEmail` shape. Apps
 * with a richer real-world session shape (e.g.
 * `session.member = { id, email, firstName, lastName }`) can override
 * the handler in `config/settings.cfm`:
 *
 *     set(browserLoginAsHandler = "AuthFixture##loginAs");
 *
 * The app's controller is a normal Wheels controller and has full
 * access to `params`, `session`, `model()`, and `inject()`. Env-gating
 * is handled at the `/_browser/*` scope by
 * `wheels.middleware.BrowserTestFixtureGuard` so the app's handler does
 * not need to re-implement the guard. Issue #2830.
 *
 * Must come before `.wildcard()` in the app's own route table.
 */
local.loginAsHandler = "BrowserTestLogin##create";
if (
	StructKeyExists(application.wheels, "browserLoginAsHandler")
	&& IsSimpleValue(application.wheels.browserLoginAsHandler)
	&& Len(application.wheels.browserLoginAsHandler)
) {
	local.loginAsHandler = application.wheels.browserLoginAsHandler;
}

mapper()
	.scope(path = "/_browser", middleware = ["wheels.middleware.BrowserTestFixtureGuard"])
	.get(name = "browserTestHome", pattern = "/home", to = "BrowserTestHome##index")
	.get(name = "browserTestLogin", pattern = "/login", to = "BrowserTestSessions##new")
	.post(name = "browserTestAuthenticate", pattern = "/login", to = "BrowserTestSessions##create")
	.get(name = "browserTestDashboard", pattern = "/dashboard", to = "BrowserTestHome##dashboard")
	.post(name = "browserTestLogout", pattern = "/logout", to = "BrowserTestSessions##destroy")
	.get(name = "browserTestLoginAs", pattern = "/login-as", to = local.loginAsHandler)
	.end()
	.end();
</cfscript>
