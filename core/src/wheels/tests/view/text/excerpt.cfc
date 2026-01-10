component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.text = "CFWheels: testing the excerpt view helper to see if it works or not.";
		args.phrase = "CFWheels: testing the excerpt";
		args.radius = "0";
		args.excerptString = "[more]";
	}

	function test_phrase_at_the_beginning() {
		e = _controller.excerpt(argumentcollection = args);
		r = "CFWheels: testing the excerpt[more]";
		assert("e eq r");
	}

	function test_phrase_not_at_the_beginning() {
		args.phrase = "testing the excerpt";
		e = _controller.excerpt(argumentcollection = args);
		r = "[more]testing the excerpt[more]";
		assert("e eq r");
	}

	function test_phrase_not_at_the_beginning_radius_does_not_reach_start_or_end() {
		args.phrase = "excerpt view helper";
		args.radius = "10";
		e = _controller.excerpt(argumentcollection = args);
		r = "[more]sting the excerpt view helper to see if[more]";
		assert("e eq r");
	}

	function test_phrase_not_at_the_beginning_radius_does_not_reach_start() {
		args.phrase = "excerpt view helper";
		args.radius = "25";
		e = _controller.excerpt(argumentcollection = args);
		r = "CFWheels: testing the excerpt view helper to see if it works or no[more]";
		assert("e eq r");
	}

	function test_phrase_not_at_the_beginning_radius_does_not_reach_end() {
		args.radius = "25";
		args.phrase = "see if it works";
		e = _controller.excerpt(argumentcollection = args);
		r = "[more]e excerpt view helper to see if it works or not.";
		assert("e eq r");
	}

	function test_phrase_not_found() {
		args.radius = "25";
		args.phrase = "jklsduiermobk";
		e = _controller.excerpt(argumentcollection = args);
		r = "";
		assert("e eq r");
	}

}
