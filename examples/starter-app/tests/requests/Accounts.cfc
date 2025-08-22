component extends="tests.Test" {


	function setup() {
		super.setup();
	}
	function teardown() {
		super.teardown();
	}

	function test_AccessAccount_with_Auth(){
		loginFakeUser();
		params= {
			controller="accounts", action="show"
		};
		r=processRequest(params=params, returnAs="struct");
		assert("r.body CONTAINS 'Your Account'");
		assert("r.status EQ 200");
		assert("r.redirect EQ ''");
	}

	function test_AccessAccount_withOut_Auth(){
		logoutFakeUser();
		params= {
			controller="accounts", action="show"
		};
		r=processRequest(params=params, returnAs="struct");
		shouldLoginRedirect();
	}

	function shouldLoginRedirect(){
		assert("r.status EQ 302");
		assert("r.redirect EQ '/login'");
		assert("r.flash.error EQ 'Login Required'");
	}


}
