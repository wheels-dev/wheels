component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_x_mailTo_valid() {
		_controller.mailTo(emailAddress = "webmaster@yourdomain.com", name = "Contact our Webmaster");
	}

}
