/**
 * Browser-test fixture controller — framework-internal.
 * `loginAs` endpoint for browser specs. Issues #2135, #2138.
 *
 * Env-gating is enforced by `wheels.middleware.BrowserTestFixtureGuard`
 * on the `/_browser` scope (issue #2830) so an app supplying its own
 * handler via `set(browserLoginAsHandler = "...")` inherits the same
 * gate. The route is only registered in testing/development to begin
 * with — the middleware is belt-and-braces.
 */
component extends="Controller" {

	function config() {
	}

	function create() {
		session.userId = 1;
		session.userEmail = params.identifier;
		$renderBrowserFixtureView(action = "create");
	}

}
