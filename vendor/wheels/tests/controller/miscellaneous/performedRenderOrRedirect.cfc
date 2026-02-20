component extends="wheels.tests.Test" {

	function packageSetup() {
		variables.counteactual = 1;
	}

	function setup() {
		params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", params);
	}

	function test_redirect_or_render_has_not_been_performed() {
		expected = false;
		actual = _controller.$performedRedirect();
		assert('actual eq expected');
		actual = _controller.$performedRender();
		assert('actual eq expected');
		actual = _controller.$performedRenderOrRedirect();
		assert('actual eq expected');
	}

	function test_only_redirect_was_performed() {
		_controller.redirectTo(controller = "wheels", action = "wheels");
		expected = true;
		actual = _controller.$performedRedirect();
		assert('actual eq expected');
		actual = _controller.$performedRenderOrRedirect();
		assert('actual eq expected');
		expected = false;
		actual = _controller.$performedRender();
		assert('actual eq expected');
	}

	function test_only_render_was_performed() {
		_controller.renderNothing();
		expected = true;
		actual = _controller.$performedRender();
		assert('actual eq expected');
		actual = _controller.$performedRenderOrRedirect();
		assert('actual eq expected');
		expected = false;
		actual = _controller.$performedRedirect();
		assert('actual eq expected');
	}

}
