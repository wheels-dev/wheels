/**
 * Env-gates the `/_browser/*` browser-test fixture scope.
 *
 * The fixtures are only mounted when
 * `application.wheels.loadBrowserTestFixtures = true` AND
 * `application.wheels.environment` is `testing` or `development`
 * (see `vendor/wheels/Global.cfc::$lockedLoadRoutes`). This middleware
 * is belt-and-braces: it re-checks the environment at request time so
 * the gate still applies when an app supplies its own handler via
 * `set(browserLoginAsHandler = "AuthFixture##loginAs")` (issue #2830).
 *
 * Without the middleware, an app whose custom handler does not
 * re-implement the env check would expose the fixture in production if
 * `loadBrowserTestFixtures` were ever flipped on by mistake.
 *
 * Attached to the `/_browser` scope in
 * `vendor/wheels/public/browser-fixtures/routes.cfm`.
 *
 * [section: Middleware]
 * [category: Built-in]
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	/**
	 * Required so the dispatcher can instantiate this middleware when it is
	 * registered by component-path string on a route scope —
	 * `Dispatch.cfc::$resolveMiddlewareInstance()` does
	 * `CreateObject("component", name).init()`. Takes no configuration.
	 */
	public BrowserTestFixtureGuard function init() {
		return this;
	}

	public string function handle(required struct request, required any next) {
		if (
			!StructKeyExists(application.wheels, "environment")
			|| !ListFindNoCase("testing,development", application.wheels.environment)
		) {
			Throw(
				type = "Wheels.BrowserTestSecurityError",
				message = "/_browser/* fixture endpoints are only available in testing/development environments"
			);
		}
		return arguments.next(arguments.request);
	}

}
