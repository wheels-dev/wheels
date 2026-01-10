component extends="wheels.tests.Test" {

	function setup() {
		params.controller = "blog";
		params.action = "edit";
		params.key = "1";
		_controller = controller(params.controller, params);
		args = {};
		args.controller = "blog";
		args.action = "edit";
		args.key = "1";
		args.params = "param1=foo&param2=bar";
		args.$URLRewriting = "On";
		oldScriptName = request.cgi.script_name;
	}

	function teardown() {
		request.cgi.script_name = oldScriptName;
	}

	function test_ampersand_in_params_with_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		e = '#application.wheels.webpath#x/x?a=c+ats%26dogs&b=a+c';
		r = _controller.URLFor(
			controller = "x",
			action = "x",
			params = "a=c ats%26dogs&b=a c",
			encode = true
		);
		assert('e eq r');
	}

	function test_all_arguments_with_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		e = "#application.wheels.webpath#blog/edit/1?param1=foo&param2=bar";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

	function test_missing_controller_with_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		StructDelete(args, "controller");
		e = "#application.wheels.webpath#blog/edit/1?param1=foo&param2=bar";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

	function test_missing_action_with_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		StructDelete(args, "action");
		e = "#application.wheels.webpath#blog/index/1?param1=foo&param2=bar";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

	function test_missing_controller_and_action_with_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		StructDelete(args, "controller");
		StructDelete(args, "action");
		e = "#application.wheels.webpath#blog/edit/1?param1=foo&param2=bar";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

	function test_missing_controller_action_and_key_with_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		StructDelete(args, "controller");
		StructDelete(args, "action");
		StructDelete(args, "key");
		e = "#application.wheels.webpath#blog/edit?param1=foo&param2=bar";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

	function test_missing_controller_action_key_and_params_with_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		StructDelete(args, "controller");
		StructDelete(args, "action");
		StructDelete(args, "key");
		StructDelete(args, "params");
		e = "#application.wheels.webpath#blog/edit";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

	function test_all_arguments_without_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		args.$URLRewriting = "Off";
		webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/");
		e = "#webRoot#?controller=blog&action=edit&key=1&param1=foo&param2=bar";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

	function test_ampersand_in_params_without_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/");
		e = "#webRoot#?controller=x&action=x&a=c+ats%26dogs&b=a+c";
		r = _controller.urlFor(
			controller = "x",
			action = "x",
			params = "a=c ats%26dogs&b=a c",
			encode = true,
			$URLRewriting = "Off"
		);
		assert("e eq r");
	}

	function test_missing_controller_without_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		args.$URLRewriting = "Off";
		StructDelete(args, "controller");
		webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/");
		e = "#webRoot#?controller=blog&action=edit&key=1&param1=foo&param2=bar";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

	function test_missing_action_without_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		args.$URLRewriting = "Off";
		StructDelete(args, "action");
		webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/");
		e = "#webRoot#?controller=blog&action=index&key=1&param1=foo&param2=bar";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

	function test_missing_controller_and_action_without_url_rewriting() {
		request.cgi.script_name = "/index.cfm";
		args.$URLRewriting = "Off";
		StructDelete(args, "controller");
		StructDelete(args, "action");
		webRoot = Replace("#application.wheels.webpath##ListLast(request.cgi.script_name, '/')#", "//", "/");
		e = "#webRoot#?controller=blog&action=edit&key=1&param1=foo&param2=bar";
		r = _controller.urlFor(argumentcollection = args);
		assert("e eq r");
	}

}
