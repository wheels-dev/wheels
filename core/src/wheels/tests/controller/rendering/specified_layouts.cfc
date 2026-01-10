component extends="wheels.tests.Test" {

	function setup() {
		request.cgi.http_x_requested_with = "";
		params = {controller = "dummy", action = "index"};
		_controller = controller("dummy", params);
	}


	function test_using_method_match() {
		args = {template = "controller_layout_test"};
		_controller.controller_layout_test = controller_layout_test;
		_controller.usesLayout(argumentCollection = args);

		e = "index_layout";
		r = _controller.$useLayout("index");
		assert('e eq r');
	}

	function test_using_method_match2() {
		args = {template = "controller_layout_test"};
		_controller.controller_layout_test = controller_layout_test;
		_controller.usesLayout(argumentCollection = args);

		e = "show_layout";
		r = _controller.$useLayout("show");
		assert('e eq r');
	}

	function test_using_method_no_match() {
		args = {template = "controller_layout_test"};
		_controller.controller_layout_test = controller_layout_test;
		_controller.usesLayout(argumentCollection = args);

		e = "true";
		r = _controller.$useLayout("list");
		assert('e eq r');
	}

	function test_using_method_no_match_no_default() {
		args = {template = "controller_layout_test", usedefault = false};
		_controller.controller_layout_test = controller_layout_test;
		_controller.usesLayout(argumentCollection = args);

		e = "false";
		r = _controller.$useLayout("list");
		assert('e eq r');
	}

	function test_ajax_request_with_no_layout_specified_should_fallback_to_template() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {template = "controller_layout_test"};
		_controller.controller_layout_test = controller_layout_test;
		_controller.usesLayout(argumentCollection = args);

		e = "index_layout";
		r = _controller.$useLayout("index");
		assert('e eq r');
	}

	function test_using_method_ajax_match() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {template = "controller_layout_test", ajax = "controller_layout_test_ajax"};
		_controller.controller_layout_test = controller_layout_test;
		_controller.controller_layout_test_ajax = controller_layout_test_ajax;
		_controller.usesLayout(argumentCollection = args);

		e = "index_layout_ajax";
		r = _controller.$useLayout("index");
		assert('e eq r');
	}

	function test_using_method_ajax_match2() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {template = "controller_layout_test", ajax = "controller_layout_test_ajax"};
		_controller.controller_layout_test = controller_layout_test;
		_controller.controller_layout_test_ajax = controller_layout_test_ajax;
		_controller.usesLayout(argumentCollection = args);

		e = "show_layout_ajax";
		r = _controller.$useLayout("show");
		assert('e eq r');
	}

	function test_using_method_ajax_no_match() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {template = "controller_layout_test", ajax = "controller_layout_test_ajax"};
		_controller.controller_layout_test = controller_layout_test;
		_controller.controller_layout_test_ajax = controller_layout_test_ajax;
		_controller.usesLayout(argumentCollection = args);

		e = "true";
		r = _controller.$useLayout("list");
		assert('e eq r');
	}

	function test_using_method_ajax_no_match_no_default() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {template = "controller_layout_test", ajax = "controller_layout_test_ajax", usedefault = false};
		_controller.controller_layout_test = controller_layout_test;
		_controller.controller_layout_test_ajax = controller_layout_test_ajax;
		_controller.usesLayout(argumentCollection = args);

		e = "false";
		r = _controller.$useLayout("list");
		assert('e eq r');
	}

	function test_should_respect_exceptions_no_match() {
		args = {template = "mylayout", except = "index"};
		_controller.usesLayout(argumentCollection = args);

		e = "mylayout";
		r = _controller.$useLayout("show");
		assert('e eq r');
	}

	function test_should_respect_exceptions_match() {
		args = {template = "mylayout", except = "index"};
		_controller.usesLayout(argumentCollection = args);

		e = "true";
		r = _controller.$useLayout("index");
		assert('e eq r');
	}

	function test_should_respect_exceptions_match_no_default() {
		args = {template = "mylayout", except = "index", usedefault = false};
		_controller.usesLayout(argumentCollection = args);

		e = "false";
		r = _controller.$useLayout("index");
		assert('e eq r');
	}

	function test_should_respect_exceptions_ajax_no_match() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {template = "mylayout", ajax = "mylayout_ajax", except = "index"};
		_controller.usesLayout(argumentCollection = args);

		e = "mylayout_ajax";
		r = _controller.$useLayout("show");
		assert('e eq r');
	}

	function test_should_respect_exceptions_ajax_match() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {template = "mylayout", ajax = "mylayout_ajax", except = "index"};
		_controller.usesLayout(argumentCollection = args);

		e = "true";
		r = _controller.$useLayout("index");
		assert('e eq r');
	}

	function test_should_respect_exceptions_ajax_match_no_default() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {
			template = "mylayout",
			ajax = "mylayout_ajax",
			except = "index",
			usedefault = false
		};
		_controller.usesLayout(argumentCollection = args);

		e = "false";
		r = _controller.$useLayout("index");
		assert('e eq r');
	}

	function test_should_respect_only_no_match() {
		args = {template = "mylayout", only = "index"};
		_controller.usesLayout(argumentCollection = args);

		e = "true";
		r = _controller.$useLayout("show");
		assert('e eq r');
	}

	function test_should_respect_only_match() {
		args = {template = "mylayout", only = "index"};
		_controller.usesLayout(argumentCollection = args);

		e = "mylayout";
		r = _controller.$useLayout("index");
		assert('e eq r');
	}

	function test_should_respect_only_no_match_no_default() {
		args = {template = "mylayout", only = "index", usedefault = false};
		_controller.usesLayout(argumentCollection = args);

		e = "false";
		r = _controller.$useLayout("show");
		assert('e eq r');
	}

	function test_should_respect_only_ajax_no_match() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {template = "mylayout", ajax = "mylayout_ajax", only = "index"};
		_controller.usesLayout(argumentCollection = args);

		e = "true";
		r = _controller.$useLayout("show");
		assert('e eq r');
	}

	function test_should_respect_only_ajax_match() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {template = "mylayout", ajax = "mylayout_ajax", only = "index"};
		_controller.usesLayout(argumentCollection = args);

		e = "mylayout_ajax";
		r = _controller.$useLayout("index");
		assert('e eq r');
	}

	function test_should_respect_only_ajax_no_match_no_default() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		args = {
			template = "mylayout",
			ajax = "mylayout_ajax",
			only = "index",
			usedefault = false
		};
		_controller.usesLayout(argumentCollection = args);

		e = "false";
		r = _controller.$useLayout("show");
		assert('e eq r');
	}

	/**
	 * HELPERS
	 */

	function controller_layout_test() {
		if (arguments.action eq "index") {
			return "index_layout";
		}
		if (arguments.action eq "show") {
			return "show_layout";
		}
	}

	function controller_layout_test_ajax() {
		if (arguments.action eq "index") {
			return "index_layout_ajax";
		}
		if (arguments.action eq "show") {
			return "show_layout_ajax";
		}
	}

}
