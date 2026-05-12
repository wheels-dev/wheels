/**
 * Browser-test fixture controller — framework-internal.
 * See `Controller.cfc` in this directory for rendering helper docs.
 * Issues #2135, #2138.
 */
component extends="Controller" {

	function new() {
		variables.flashError = flash("error") ?: "";
		$renderBrowserFixtureView(action = "new");
	}

	function create() {
		if (params.email == "alice@example.com" && params.password == "secret") {
			session.userId = 1;
			session.userEmail = params.email;
			redirectTo(route = "browserTestDashboard");
		} else {
			flashInsert(error = "Invalid credentials");
			redirectTo(route = "browserTestLogin");
		}
	}

	function destroy() {
		StructClear(session);
		redirectTo(route = "browserTestLogin");
	}

}
