component extends="wheels.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_authenticityTokenField() {
		local.token = CsrfGenerateToken();
		tag = _controller.authenticityTokenField();
		authenticityTokenField = '<input name="authenticityToken" type="hidden" value="#local.token#">';
		assert("tag is '#authenticityTokenField#'");
	}

}
