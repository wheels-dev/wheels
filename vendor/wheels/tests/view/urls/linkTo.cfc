component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		oldURLRewriting = application.wheels.URLRewriting;
		application.wheels.URLRewriting = "On";
		oldScriptName = request.cgi.script_name;
		request.cgi.script_name = "/index.cfm";
		set(functionName = "linkTo", encode = false);
	}

	function teardown() {
		application.wheels.URLRewriting = oldURLRewriting;
		request.cgi.script_name = oldScriptName;
		set(functionName = "linkTo", encode = true);
	}

	function test_ampersand_and_equals_sign_encoding() {
		e = '<a href="#application.wheels.webpath#x/x?a=cats%26dogs%3Dtrouble&b=1">x</a>';
		r = _controller.linkTo(
			text = "x",
			controller = "x",
			action = "x",
			params = "a=cats%26dogs%3Dtrouble&b=1"
		);
		assert('e eq r');
	}

	function test_do_not_attribute_encode_href() {
		e = '<a class="we&##x27;re" href="/we&##x25;27re/x?x=1&y=2&##x2b;3">x</a>';
		set(functionName = "linkTo", encode = true);
		r = _controller.linkTo(
			class = "we're",
			text = "x",
			controller = "we're",
			action = "x",
			params = "x=1&y=2 3"
		);
		set(functionName = "linkTo", encode = false);
		assert('e eq r');
	}

	function test_do_not_encode_dash() {
		e = 'ca-ts">x</a>';
		set(functionName = "linkTo", encode = true);
		r = Right(
			_controller.linkTo(
				text = "x",
				controller = "x",
				action = "x",
				params = "cats=ca-ts"
			),
			12
		);
		set(functionName = "linkTo", encode = false);
		assert('e eq r');
	}

	function test_controller_action_only() {
		e = '<a href="#application.wheels.webpath#account/logout">Log Out</a>';
		r = _controller.linkTo(text = "Log Out", controller = "account", action = "logout");
		assert('e eq r');
	}

	function test_external_links() {
		e = '<a href="http://www.cfwheels.com">CFWheels</a>';
		r = _controller.linkTo(href = "http://www.cfwheels.com", text = "CFWheels");
		assert('e eq r');
	}

	function test_linkto_arguments() {
		e = '<a confirm="confirm-value" disabled="disabled-value" href="/">CFWheels</a>';
		r = _controller.linkTo(
			href = "/",
			text = "CFWheels",
			confirm = "confirm-value",
			disabled = "disabled-value"
		);
		assert('e eq r');
	}

}
