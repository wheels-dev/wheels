component extends="Model" {

	function config() {
		table(false);
		property(name = "username");
		property(name = "password");
		property(name = "firstname");
		property(name = "lastname");
		property(name = "birthday");
	}

	function validateCalled() {
		this._validateCalled = true;
	}

	function validateOnCreateCalled() {
		this._validateOnCreateCalled = true;
	}

	function validateOnUpdateCalled() {
		this._validateOnUpdateCalled = true;
	}

}
