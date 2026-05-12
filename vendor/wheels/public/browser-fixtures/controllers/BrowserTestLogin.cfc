/**
 * Browser-test fixture controller — framework-internal.
 * Env-gated `loginAs` endpoint for browser specs. Issues #2135, #2138.
 */
component extends="Controller" {

	function config() {
	}

	function create() {
		if (!ListFindNoCase("testing,development", application.wheels.environment)) {
			Throw(
				type = "Wheels.BrowserTestSecurityError",
				message = "loginAs endpoint is only available in testing/development environments"
			);
		}

		session.userId = 1;
		session.userEmail = params.identifier;
		$renderBrowserFixtureView(action = "create");
	}

}
