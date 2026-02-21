component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "dummy", action = "dummy"};
		$$oldCGIScope = request.cgi;
	}

	function teardown() {
		request.cgi = $$oldCGIScope;
	}

	function test_$requestContentType_header_cgi_html() {
		_controller = controller("dummy", params);
		request.cgi.http_accept = "text/html";
		assert("_controller.$requestContentType() eq 'html'");
	}

	function test_$requestContentType_params_html() {
		params.format = "html";
		_controller = controller("dummy", params);
		assert("_controller.$requestContentType() eq 'html'");
	}

	function test_$requestContentType_header_cgi_xml() {
		_controller = controller("dummy", params);
		request.cgi.http_accept = "text/xml";
		assert("_controller.$requestContentType() eq 'xml'");
	}

	function test_$requestContentType_params_xml() {
		params.format = "xml";
		_controller = controller("dummy", params);
		assert("_controller.$requestContentType() eq 'xml'");
	}

	function test_$requestContentType_header_cgi_json() {
		_controller = controller("dummy", params);
		request.cgi.http_accept = "application/json";
		assert("_controller.$requestContentType() eq 'json'");
	}

	function test_$requestContentType_header_cgi_json_and_js() {
		_controller = controller("dummy", params);
		request.cgi.http_accept = "application/json, application/javascript";
		assert("_controller.$requestContentType() eq 'json'");
	}

	function test_$requestContentType_params_json() {
		params.format = "json";
		_controller = controller("dummy", params);
		assert("_controller.$requestContentType() eq 'json'");
	}

	function test_$requestContentType_header_cgi_csv() {
		_controller = controller("dummy", params);
		request.cgi.http_accept = "text/csv";
		assert("_controller.$requestContentType() eq 'csv'");
	}

	function test_$requestContentType_params_csv() {
		params.format = "csv";
		_controller = controller("dummy", params);
		assert("_controller.$requestContentType() eq 'csv'");
	}

	function test_$requestContentType_header_cgi_xls() {
		_controller = controller("dummy", params);
		request.cgi.http_accept = "application/vnd.ms-excel";
		assert("_controller.$requestContentType() eq 'xls'");
	}

	function test_$requestContentType_params_xls() {
		params.format = "xls";
		_controller = controller("dummy", params);
		assert("_controller.$requestContentType() eq 'xls'");
	}

	function test_$requestContentType_header_cgi_pdf() {
		_controller = controller("dummy", params);
		request.cgi.http_accept = "application/pdf";
		assert("_controller.$requestContentType() eq 'pdf'");
	}

	function test_$requestContentType_params_pdf() {
		params.format = "pdf";
		_controller = controller("dummy", params);
		assert("_controller.$requestContentType() eq 'pdf'");
	}

}
