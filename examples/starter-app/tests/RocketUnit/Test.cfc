/**
 * This is the parent test component that all your test components should extend.
 * Do not delete this file (the functions can be safely deleted though).
 */
component extends="wheels.Test" {

	/**
	 * Executes once before the test suite runs.
	 *
	 * [section: Test Model Configuration]
	 * [category: Callback Functions]
	 *
	 */
	function beforeAll() {
	}

	/**
	 * Executes before every test case (unless overridden in a package without calling super.setup()).
	 *
	 * [section: Test Model Configuration]
	 * [category: Callback Functions]
	 */
	function setup() {
		// NOTE: These tests require URL rewriting to work as they occasionally test for strings like /login (as opposed to /index.cfm/login/)
		// Add a flag so that we know we're in testing mode; this is used to swap out scopes such as sessions and the
		// main application settings
		request.isTestingMode=true;
		request.mockSession={};
		request.mockApplication={
			"authentication_gateway" = "Local",
			"permissions_cascade" = true,
			"authentication_allowRegistration" = true,
			"authentication_allowPasswordResets" = true,
			"general_sitename" = "Example App (TESTING)",
			"general_copyright" = ""
		};
	}

	/**
	 * Executes after every test case (unless overridden in a package without calling super.teardown()).
	 *
	 * [section: Test Model Configuration]
	 * [category: Callback Functions]
	 */
	function teardown() {
		request.isTestingMode=false;
		request.mockSession={};
		request.mockApplication={};
	}

	/**
	 * Executes once after the test suite runs.
	 *
	 * [section: Test Model Configuration]
	 * [category: Callback Functions]
	 */
	function afterAll() {
	}

	/**
	* Helpers:
	**/
	function loginFakeUser(){
		request.mockSession.user={
			"properties" = {
				"id": 1,
				"email": "admin@domain.com"
			},
			"permissions" = {
				"accounts" = true
			}
		};
	}

	function logoutFakeUser(){
		request.mockSession={};
	}

}
