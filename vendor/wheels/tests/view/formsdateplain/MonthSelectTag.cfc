component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_selected_value() {
		args.name = "birthday";
		args.selected = 2;
		args.$now = "01/31/2011";
		r = _controller.monthSelectTag(argumentcollection = args);
		e = '<option selected="selected" value="2">';
		assert('r CONTAINS e');
	}

}
