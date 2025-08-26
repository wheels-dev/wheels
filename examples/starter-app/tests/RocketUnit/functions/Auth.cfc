component extends="tests.Test" {


	function setup() {
		super.setup();
		auth=model("auth.Local").new();
	}
	function teardown() {
		super.teardown();
		params={};
	}

	function Test_Auth_has_Default_Properties(){
		assert("len(auth.name)");
		assert("len(auth.allowPasswordReset)");
		assert("len(auth.allowRememberMe)");
		assert("len(auth.allowUserRegistration)");
	}

	function Test_Auth_has_required_methods(){
		assert( "structKeyExists(auth, 'login')" );
		assert( "structKeyExists(auth, 'authenticate')" );
		assert( "structKeyExists(auth, 'logout')" );
	}

	function Test_Auth_validation_fails(){
		properties={
			password: "bar"
		};
		auth.setProperties(properties);
		auth.valid();
		assert("!auth.valid()");
	}

	function Test_Auth_validation_passes(){
		properties={
			email: "foo@foo.com",
			password: "barbar123!"
		};
		auth.setProperties(properties);
		auth.valid();
		assert("auth.valid()");
	}

	function Test_Authentication_Fails_Invalid_account(){
		properties={
			email: "admin@fakedomain.com",
			password: "doesntmatter"
		};
		auth.setProperties(properties);
		assert("!auth.authenticate()");
	}

	function Test_Login_Fails_Invalid_account(){
		properties={
			email: "admin@fakedomain.com",
			password: "doesntmatter"
		};
		auth.setProperties(properties);
		assert("!auth.login()");
		assert("!structKeyExists(session, 'auth')");
	}
	/*
	function Test_Login_Passes_Valid_account(){
		properties={
			email: "test@test.com",
			password: "validPassword"
		};
		auth.setProperties(properties);
		r=auth.login();
		assert("r");
		assert("structKeyExists(session, 'auth')");
	}
	function Test_Authentication_Passes_Valid_account(){
		properties={
			email: "test@test.com",
			password: "validPassword"
		};
		auth.setProperties(properties);
		assert("auth.authenticate()");
	}
	*/
}
