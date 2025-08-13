component extends="app.tests.Test" {

	function setup(){
		super.setup();
		m=model("user").new();
	}

	function teardown(){
		super.teardown();
		m={};
	}

	function test_create_validation_passes(){
		params= {
			"firstname": "Joe",
			"lastname": "Bloggs",
			"email": "joe@bloggs.com",
			"password": "validPassword123!",
			"passwordConfirmation": "validPassword123!",
			"terms": 1
		};
		m.setProperties(params);
		v = m.valid();
		assert("v EQ true");
	}
	function test_create_validation_fails_bad_email(){
		params= {
			"firstname": "Joe",
			"lastname": "Bloggs",
			"email": "invalid",
			"password": "validPassword123!",
			"passwordConfirmation": "validPassword123!",
			"terms": 1
		};
		m.setProperties(params);
		v = m.valid();
		err = m.allErrors();
		//debug("err");
		assert("v EQ false");
	}

	function test_validation_fails(){
		params= {
			"firstname": "Joe",
			"password": "validPassword123!",
			"passwordConfirmation": "validPassword123!"
		};
		m.setProperties(params);
		v = m.valid();
		err = m.allErrors();
		assert("arrayLen(err) EQ 4");
		assert("v EQ false");
	}

	function test_create_validation_fails_password_confirmation(){
		params= {
			"firstname": "Joe",
			"lastname": "Bloggs",
			"email": "joe@bloggs.com",
			"password": "validPassword123!",
			"passwordConfirmation": "badlyTyped",
			"terms": 1
		};
		m.setProperties(params);
		v = m.valid();
		err = m.allErrors();
		assert("v EQ false");
		assert("arrayLen(err) EQ 1");
	}

	function test_password_cant_be_in_email(){
		params= {
			"firstname": "Joe",
			"lastname": "Bloggs",
			"email": "avalidString123!@bloggs.com",
			"password": "avalidString123!",
			"passwordConfirmation": "avalidString123!",
			"terms": 1
		};
		m.setProperties(params);
		v = m.valid();
		err = m.allErrors();
		assert("v EQ false");
		assert("arrayLen(err) EQ 1");
	}

	function test_generateRandomPassword(){
		r=m.generateRandomPassword();
		assert("len(r) EQ 12");
	}

	function test_hashPassword(){
		m.password = "validPassword123!";
		m.hashPassword();
		r = m.properties();
		assert("structKeyExists(r, 'passwordHash')");
		assert("len(r.passwordHash) GT len(m.password)");
	}

	function test_checkPassword_fails(){
		attempt = "IncorrectPassword";
		m.password = "validPassword123!";
		m.hashPassword();
		r=m.checkPassword(attempt);
		assert("r EQ false");
	}

	function test_checkPassword_passes(){
		m.password = "validPassword123!";
		m.hashPassword();
		r=m.checkPassword(m.password);
		assert("r EQ true");
	}

	function test_generateVerificationToken(){
		m.generateVerificationToken();
		assert("structKeyExists(m, 'verificationToken')");
		assert("len(m.verificationToken) GT 0");
	}

	function test_verifyUser(){
		m.verifyUser();
		assert("structKeyExists(m, 'verificationToken')");
		assert("len(m.verificationToken) EQ 0");
		assert("m.verified");
	}

	function test_generatePasswordResetToken(){
		m.generatePasswordResetToken();
		assert("structKeyExists(m, 'passwordresettoken')");
		assert("len(m.passwordresettoken) GT 0");
		assert("structKeyExists(m, 'passwordresettokenat')");
		assert("isDate(m.passwordresettokenAt)");
		m.clearPasswordResetToken();
		assert("structKeyExists(m, 'passwordresettoken')");
		assert("len(m.passwordresettoken) EQ 0");
		assert("structKeyExists(m, 'passwordresettokenat')");
		assert("len(m.passwordresettokenAt) EQ 0");
	}
}
