/**
 * Browser-test fixture controller — framework-internal.
 *
 * Mounted via `$lockedLoadRoutes` when `loadBrowserTestFixtures=true`
 * and environment is `testing` or `development`. See issues #2135, #2138.
 *
 * Views live beside this file at `vendor/wheels/public/browser-fixtures/views/`.
 * They are rendered via explicit `cfinclude` rather than the normal Wheels
 * view-path resolver because the framework's `viewPath` setting is a
 * single string pinned to `/app/views`.
 */
component extends="Controller" {

	function config() {
		filters(through = "$requireLogin", except = "index");
	}

	function index() {
		$renderBrowserFixtureView(action = "index");
	}

	function dashboard() {
		variables.user = {email = session.userEmail ?: ""};
		$renderBrowserFixtureView(action = "dashboard");
	}

	private function $requireLogin() {
		if (!StructKeyExists(session, "userId")) {
			redirectTo(route = "browserTestLogin");
		}
	}

}
