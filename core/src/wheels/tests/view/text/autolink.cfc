component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		set(functionName = "autoLink", encode = false);
	}

	function teardown() {
		set(functionName = "autoLink", encode = true);
	}

	function test_link_urls() {
		str = 'blah blah <a href="http://cfwheels.org/download">http://cfwheels.org/download</a> Download CFWheels from http://cfwheels.org/download blah blah';
		r = _controller.autoLink(str, "URLs");
		e = 'blah blah <a href="http://cfwheels.org/download">http://cfwheels.org/download</a> Download CFWheels from <a href="http://cfwheels.org/download">http://cfwheels.org/download</a> blah blah';
		assert('e eq r');
	}

	function test_link_email() {
		str = 'blah blah <a href="mailto:tpetruzzi@gmail.com">tpetruzzi@gmail.com</a> Download CFWheels from tpetruzzi@gmail.com blah blah';
		r = _controller.autoLink(str, "emailAddresses");
		e = 'blah blah <a href="mailto:tpetruzzi@gmail.com">tpetruzzi@gmail.com</a> Download CFWheels from <a href="mailto:tpetruzzi@gmail.com">tpetruzzi@gmail.com</a> blah blah';
		assert('e eq r');
	}

	function test_do_not_include_punctuation() {
		str = 'The best http://cfwheels.org, Framework around. Download CFWheels from http://cfwheels.org/download.?!';
		r = _controller.autoLink(str, "URLs");
		e = 'The best <a href="http://cfwheels.org">http://cfwheels.org</a>, Framework around. Download CFWheels from <a href="http://cfwheels.org/download">http://cfwheels.org/download</a>.?!';
		assert('e eq r');
	}

	function test_overloaded_argument_become_link_attributes() {
		str = 'Download CFWheels from http://cfwheels.org/download';
		r = _controller.autoLink(
			text = str,
			link = "URLs",
			target = "_blank",
			class = "wheels-href"
		);
		e = 'Download CFWheels from <a class="wheels-href" href="http://cfwheels.org/download" target="_blank">http://cfwheels.org/download</a>';
		assert('e eq r');
	}

	function test_issue_560() {
		str = 'http://www.foo.uk';
		r = _controller.autoLink(str);
		e = '<a href="http://www.foo.uk">http://www.foo.uk</a>';
		assert('e eq r');
	}

	function test_issue_656_relative_paths_escaped() {
		str = 'Download CFWheels from <a href="/">http://x.com/x</a> blah blah';
		r = _controller.autoLink(str);
		e = 'Download CFWheels from <a href="/">http://x.com/x</a> blah blah';
		assert('e eq r');
	}

	function test_issue_656_relative_paths_link() {
		str = 'Download CFWheels from /cfwheels.org/download blah blah';
		r = _controller.autoLink(str);
		e = 'Download CFWheels from <a href="/cfwheels.org/download">/cfwheels.org/download</a> blah blah';
		assert('e eq r');
	}

	function test_turn_off_relative_url_linking() {
		str = '155 cals/3.3miles';
		r = _controller.autoLink(text = "#str#", relative = "false");
		e = '155 cals/3.3miles';
		assert('e eq r');
	}

	function test_link_www() {
		str = "www.foo.uk";
		r = _controller.autoLink(str);
		e = "<a href=""http://www.foo.uk"">www.foo.uk</a>";
		assert("e eq r");
	}

}
