component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_step_argument() {
		args.name = "countdown";
		args.selected = 15;
		args.minuteStep = 15;
		r = _controller.minuteSelectTag(argumentcollection = args);
		e = '<option selected="selected" value="15">';
		assert('r CONTAINS e');
		matches = ReMatchNoCase("\<option", r);
		assert('arraylen(matches) eq 4');
	}

}
