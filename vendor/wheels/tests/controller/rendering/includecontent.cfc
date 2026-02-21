component extends="wheels.tests.Test" {

	function setup() {
		_params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", _params);
	}

	function test_contentFor_and_includeContent_assigning_section() {
		a = ["head1", "head2", "head3"];
		for (i in a) {
			_controller.contentFor(head = i);
		};
		expected = ArrayToList(a, Chr(10));
		actual = _controller.includeContent("head");
		assert('actual eq expected');
	}

	function test_contentFor_and_includeContent_default_section() {
		a = ["layout1", "layout2", "layout3"];
		for (i in a) {
			_controller.contentFor(body = i);
		};
		expected = ArrayToList(a, Chr(10));
		actual = _controller.includeContent();
		assert('actual eq expected');
	}

	function test_includeContent_invalid_section_returns_blank() {
		actual = _controller.includeContent("somethingstupid");
		assert('actual eq ""');
	}

	function test_includeContent_returns_default() {
		actual = _controller.includeContent("somethingstupid", "my default value");
		assert('actual eq "my default value"');
	}

}
