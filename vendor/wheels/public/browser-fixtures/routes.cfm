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
 * Must come before `.wildcard()` in the app's own route table.
 */
mapper()
	.scope(path = "/_browser")
	.get(name = "browserTestHome", pattern = "/home", to = "BrowserTestHome##index")
	.get(name = "browserTestLogin", pattern = "/login", to = "BrowserTestSessions##new")
	.post(name = "browserTestAuthenticate", pattern = "/login", to = "BrowserTestSessions##create")
	.get(name = "browserTestDashboard", pattern = "/dashboard", to = "BrowserTestHome##dashboard")
	.post(name = "browserTestLogout", pattern = "/logout", to = "BrowserTestSessions##destroy")
	.get(name = "browserTestLoginAs", pattern = "/login-as", to = "BrowserTestLogin##create")
	.end()
	.end();
</cfscript>
