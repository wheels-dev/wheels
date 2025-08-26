component extends="tests.Test" {


	function setup() {
		super.setup();
	}
	function teardown() {
		super.teardown();
	}

	function test_session_new(){
		params= {
			controller="sessions", action="new"
		};
		r=processRequest(params=params, returnAs="struct");
		assert("r.status EQ 200");
		assert("!len(r.redirect)");
		assert("r.body CONTAINS '<form action=""/authenticate"" method=""post"">'");
	}

	/*
	* Removing this for now as it still requires a valid user in the db to pass
	* Might re-add if we add a dedicated DB for testing
	function test_session_create_redirects_after_login(){
		params= {
			controller="sessions", action="create",
			auth = {
				"email" = "admin@domain.com",
				"password" = "Password123!"
			}
		};
		r=processRequest(params=params, returnAs="struct", method="POST");
		debug("r");
		assert("r.redirect EQ '/'");
		assert("r.status EQ 302");
	}*/

	function test_session_create_invalid_rerenders_login_form(){
		params= {
			controller="sessions", action="create",
			auth = {
				"email" = "badstuff",
				"password" = "wrongstuff"
			}
		};
		r=processRequest(params=params, returnAs="struct", method="POST");
		assert("r.body CONTAINS 'Email is invalid'");
		assert("r.body CONTAINS 'Password must be at least 8 characters long and contain a mixture of numbers and letters'");
		assert("r.status EQ 200");
	}
}
