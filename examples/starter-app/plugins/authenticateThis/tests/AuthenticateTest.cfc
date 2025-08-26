component extends="wheels.Test"  hint="Unit Tests" {
	function setup(){
		$oldmodelpath = application.wheels.modelPath;
		application.wheels.modelPath = "/plugins/authenticateThis/tests/_assets/models/";
		m = model("dummy").new();
	}
	function teardown(){
		application.wheels.modelPath = $oldmodelpath;
	}

	function test_generateRandomPassword(){
		r=m.generateRandomPassword();
		assert("len(r) EQ 12");
	}

	function test_hashPassword(){
		m.password = "abc123";
		m.hashPassword();
		r = m.properties();
		assert("structKeyExists(r, 'passwordHash')");
		assert("len(r.passwordHash) GT len(m.password)");
	}

	function test_checkPassword_fails(){
		attempt = "IncorrectPassword";
		m.password = "abc123";
		m.hashPassword();
		r=m.checkPassword(attempt);
		assert("r EQ false");
	}

	function test_checkPassword_passes(){
		m.password = "abc123";
		m.hashPassword();
		r=m.checkPassword(m.password);
		assert("r EQ true");
	}
	//function test_resetPassword(){
	//	m.password = "abc123";
	//	m.hashPassword();
	//	r=m.resetPassword();
	//	debug("m.properties()");
	//	assert("r EQ true");
	//}
}
