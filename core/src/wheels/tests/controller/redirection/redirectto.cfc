component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "test", action = "testRedirect"};
		_controller = controller("test", params);
		copies.request.cgi = request.cgi;
		copies.application.wheels.viewPath = application.wheels.viewPath;
	}

	function teardown() {
		request.cgi = copies.request.cgi;
		application.wheels.viewPath = copies.application.wheels.viewPath;
	}

	function test_throw_error_on_double_redirect() {
		_controller.redirectTo(action = "test");
		expected = "Wheels.RedirectToAlreadyCalled";
		actual = raised('_controller.redirectTo(action="test")');
		assert("actual eq expected");
	}

	function test_remaining_action_code_should_run() {
		application.wheels.viewPath = "/wheels/tests/_assets/views";
		_controller.$callAction(action = "testRedirect");
		r = _controller.getRedirect();
		assert("IsDefined('r.url') AND IsDefined('request.setInActionAfterRedirect')");
	}

	function test_redirect_to_action() {
		_controller.redirectTo(action = "test");
		r = _controller.getRedirect();
		assert("_controller.$performedRedirect() IS true AND IsDefined('r.url')");
	}

	function test_passing_through_to_urlfor() {
		args = {
			action = "test",
			onlyPath = false,
			protocol = "https",
			params = "test1=1&test2=2"
		};
		_controller.redirectTo(argumentCollection = args);
		r = _controller.getRedirect();
		assert("r.url Contains args.protocol AND r.url Contains args.params");
	}

	function test_setting_cflocation_attributes() {
		_controller.redirectTo(action = "test", addToken = true, statusCode = "301");
		r = _controller.getRedirect();
		assert("r.addToken IS true AND r.statusCode IS 301");
	}

	function test_redirect_to_referrer() {
		path = "/test-controller/test-action";
		request.cgi.http_referer = "http://" & request.cgi.server_name & path;
		_controller.redirectTo(back = true);
		r = _controller.getRedirect();
		assert("r.url Contains path");
	}

	function test_appending_params_to_referrer() {
		path = "/test-controller/test-action";
		request.cgi.http_referer = "http://" & request.cgi.server_name & path;
		_controller.redirectTo(back = true, params = "x=1&y=2");
		r = _controller.getRedirect();
		assert("r.url Contains path AND r.url Contains '?x=1&y=2'");
	}

	function test_redirect_to_action_on_blank_referrer() {
		request.cgi.http_referer = "";
		_controller.redirectTo(back = true, action = "blankRef");
		r = _controller.getRedirect();
		assert("r.url IS '#uRLFor(action = 'blankRef')#'");
	}

	function test_redirect_to_root_on_blank_referrer() {
		request.cgi.http_referer = "";
		_controller.redirectTo(back = true);
		r = _controller.getRedirect();
		assert("r.url IS application.wheels.webPath");
	}

	function test_redirect_to_root_on_foreign_referrer() {
		request.cgi.http_referer = "http://www.google.com";
		_controller.redirectTo(back = true);
		r = _controller.getRedirect();
		assert("r.url IS application.wheels.webPath");
	}

	function test_redirect_to_url() {
		_controller.redirectTo(url = "http://www.google.com");
		r = _controller.getRedirect();
		assert("_controller.$performedRedirect() IS true AND IsDefined('r.url')");
	}

	function test_redirect_to_url_with_params() {
		_controller.redirectTo(url = "http://www.google.com", params = "foo=bar");

		actual = _controller.getRedirect().url;
		expected = "http://www.google.com?foo=bar";

		assert("actual EQ expected");
	}

	function test_redirect_to_url_with_query_string_and_with_params() {
		_controller.redirectTo(url = "http://www.google.com?foo=bar", params = "baz=qux");

		actual = _controller.getRedirect().url;
		expected = "http://www.google.com?foo=bar&baz=qux";

		assert("actual EQ expected");
	}

}
