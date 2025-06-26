component extends="wheels.tests.Test" {

	function setup() {
		_params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", _params);
	}

	function test_specfying_positions_overwrite_false() {
		_controller.contentFor(testing = "A");
		_controller.contentFor(testing = "B");
		_controller.contentFor(testing = "C", position = "first");
		_controller.contentFor(testing = "D", position = "2");
		r = _controller.includeContent("testing");
		e = "C#Chr(10)#D#Chr(10)#A#Chr(10)#B";
		assert('e eq r');
	}

	function test_specfying_positions_overwrite_true() {
		_controller.contentFor(testing = "A");
		_controller.contentFor(testing = "B");
		_controller.contentFor(testing = "C", position = "first", overwrite = "true");
		_controller.contentFor(testing = "D", position = "2", overwrite = "true");
		r = _controller.includeContent("testing");
		e = "C#Chr(10)#D";
		assert('e eq r');
	}

	function test_overwrite_all() {
		_controller.contentFor(testing = "A");
		_controller.contentFor(testing = "B");
		_controller.contentFor(testing = "C", overwrite = "all");
		r = _controller.includeContent("testing");
		e = "C";
		assert('e eq r');
	}

	function test_specify_position_outside_of_size_should_not_error() {
		_controller.contentFor(testing = "A");
		_controller.contentFor(testing = "B");
		_controller.contentFor(testing = "C");
		_controller.contentFor(testing = "D", position = "6");
		r = _controller.includeContent("testing");
		e = ["A", "B", "C", "D"];
		e = ArrayToList(e, Chr(10));
		assert('e eq r');
		_controller.contentFor(testing = "D", position = "-5");
		r = _controller.includeContent("testing");
		e = ["D", "A", "B", "C", "D"];
		e = ArrayToList(e, Chr(10));
		assert('e eq r');
	}

}
