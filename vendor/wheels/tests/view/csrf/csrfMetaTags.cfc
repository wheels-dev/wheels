component extends="wheels.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_contains_csrfparam_meta_tag() {
		tags = _controller.csrfMetaTags();
		csrfParamTag = '<meta content="authenticityToken" name="csrf-param">';
		assert("tags contains '#csrfParamTag#'");
	}

	function test_contains_csrftoken_meta_tag() {
		local.token = CsrfGenerateToken();
		tags = _controller.csrfMetaTags();
		csrfTokenTag = '<meta content="#local.token#" name="csrf-token">';
		assert("tags contains '#csrfTokenTag#'");
	}

}
