component extends="app.tests.Test" {

	function setup(){
		super.setup();
		m=model("user").new();
	}

	function teardown(){
		super.teardown();
		m={};
	}

	function test_role_must_be_unique(){
		m.name="admin";
		assert("!m.valid()");
	}
}
