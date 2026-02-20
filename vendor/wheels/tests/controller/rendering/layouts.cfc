component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
		params = {controller = "test", action = "test"};
		_controller = controller("test", params);
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_rendering_without_layout() {
		_controller.renderView(layout = false);
		assert("_controller.response() IS 'view template content'");
	}

	function test_rendering_with_default_layout_in_controller_folder() {
		tempFile = ExpandPath("/wheels/tests/_assets/views/test/layout.cfm");
		FileWrite(tempFile, "<cfoutput>start:controllerlayout##includeContent()##end:controllerlayout</cfoutput>");
		application.wheels.existingLayoutFiles = "test";
		_controller.renderView();
		r = _controller.response();
		assert(
			"r Contains 'view template content' AND r Contains 'start:controllerlayout' AND r Contains 'end:controllerlayout'"
		);
		application.wheels.existingLayoutFiles = "";
		FileDelete(tempFile);
	}

	function test_rendering_with_default_layout_in_root() {
		_controller.renderView();
		r = _controller.response();
		assert(
			"r Contains 'view template content' AND r Contains 'start:defaultlayout' AND r Contains 'end:defaultlayout'"
		);
	}

	function test_rendering_with_specific_layout() {
		_controller.renderView(layout = "specificLayout");
		r = _controller.response();
		assert(
			"r Contains 'view template content' AND r Contains 'start:specificlayout' AND r Contains 'end:specificlayout'"
		);
	}

	function test_removing_cfm_file_extension_when_supplied() {
		_controller.renderView(layout = "specificLayout.cfm");
		r = _controller.response();
		assert(
			"r Contains 'view template content' AND r Contains 'start:specificlayout' AND r Contains 'end:specificlayout'"
		);
	}

	function test_rendering_with_specific_layout_in_root() {
		_controller.renderView(layout = "/rootLayout");
		r = _controller.response();
		assert("r Contains 'view template content' AND r Contains 'start:rootlayout' AND r Contains 'end:rootlayout'");
	}

	function test_rendering_with_specific_layout_in_sub_folder() {
		_controller.renderView(layout = "sub/layout");
		r = _controller.response();
		assert("r Contains 'view template content' AND r Contains 'start:sublayout' AND r Contains 'end:sublayout'");
	}

	function test_rendering_with_specific_layout_from_folder_path() {
		_controller.renderView(layout = "/shared/layout");
		r = _controller.response();
		assert("r Contains 'view template content' AND r Contains 'start:sharedlayout' AND r Contains 'end:sharedlayout'");
	}

	function test_view_variable_should_be_available_in_layout_file() {
		_controller.$callAction(action = "test");
		_controller.renderView();
		r = _controller.response();
		assert(
			"r Contains 'view template content' AND r Contains 'variableForLayoutContent' AND r Contains 'start:defaultlayout' AND r Contains 'end:defaultlayout'"
		);
	}

	function test_rendering_partial_with_layout() {
		_controller.renderPartial(partial = "partialTemplate", layout = "partialLayout");
		r = _controller.response();
		assert(
			"r Contains 'partial template content' AND r Contains 'start:partiallayout' AND r Contains 'end:partiallayout'"
		);
	}

	function test_rendering_partial_with_specific_layout_in_root() {
		_controller.renderPartial(partial = "partialTemplate", layout = "/partialRootLayout");
		r = _controller.response();
		assert(
			"r Contains 'partial template content' AND r Contains 'start:partialrootlayout' AND r Contains 'end:partialrootlayout'"
		);
	}

}
