component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.text = "CFWheels test to do see if highlight function works or not.";
		args.phrases = "highlight function";
		args.class = "cfwheels-highlight";
	}

	function test_phrase_found() {
		e = _controller.highlight(argumentcollection = args);
		r = 'CFWheels test to do see if <span class="cfwheels-highlight">highlight function</span> works or not.';
		assert("e eq r");
	}

	function test_phrase_not_found() {
		StructDelete(args, "phrases");
		args.phrase = "xxxxxxxxx";
		e = _controller.highlight(argumentcollection = args);
		r = 'CFWheels test to do see if highlight function works or not.';
		assert("e eq r");
	}

	function test_phrase_found_no_class_defined() {
		StructDelete(args, "class");
		args.phrases = "highlight function";
		e = _controller.highlight(argumentcollection = args);
		r = 'CFWheels test to do see if <span class="highlight">highlight function</span> works or not.';
		assert("e eq r");
	}

	function test_phrase_not_found_no_class_defined() {
		args.phrases = "xxxxxxxxx";
		e = _controller.highlight(argumentcollection = args);
		r = 'CFWheels test to do see if highlight function works or not.';
		assert("e eq r");
	}

	function test_delimiter() {
		args.delimiter = "|";
		args.phrases = "test to|function|or not";
		e = _controller.highlight(argumentcollection = args);
		r = 'CFWheels <span class="cfwheels-highlight">test to</span> do see if highlight <span class="cfwheels-highlight">function</span> works <span class="cfwheels-highlight">or not</span>.';
		assert("e eq r");
	}

	function test_mark_tag() {
		args.tag = "mark";
		e = _controller.highlight(argumentcollection = args);
		r = 'CFWheels test to do see if <mark class="cfwheels-highlight">highlight function</mark> works or not.';
		assert("e eq r");
	}

}
