component extends="wheels.tests.Test" {

	function setup() {
		cgi_scope = {};
		cgi_scope.request_method = "";
		cgi_scope.http_x_requested_with = "";
		cgi_scope.http_referer = "";
		cgi_scope.server_name = "";
		cgi_scope.query_string = "";
		cgi_scope.remote_addr = "";
		cgi_scope.server_port = "";
		cgi_scope.server_port_secure = "";
		cgi_scope.server_protocol = "";
		cgi_scope.http_host = "";
		cgi_scope.http_accept = "";
		cgi_scope.content_type = "";
		cgi_scope.script_name = "/index.cfm";
		cgi_scope.path_info = "/users/list/index.cfm";
		cgi_scope.http_x_rewrite_url = "/users/list/http_x_rewrite_url/index.cfm?controller=wheels&action=wheels&view=test";
		cgi_scope.http_x_original_url = "/users/list/http_x_original_url/index.cfm?controller=wheels&action=wheels&view=test";
		cgi_scope.request_uri = "/users/list/request_uri/index.cfm?controller=wheels&action=wheels&view=test";
		cgi_scope.redirect_url = "/users/list/redirect_url/index.cfm?controller=wheels&action=wheels&view=test";
		cgi_scope.http_x_forwarded_for = "";
		cgi_scope.http_x_forwarded_proto = "";
	}

	function test_path_info_blank() {
		cgi_scope.path_info = "";
		_cgi = $cgiScope(scope = cgi_scope);
		assert('_cgi.path_info eq "/users/list/http_x_rewrite_url"');
		cgi_scope.http_x_rewrite_url = "";
		_cgi = $cgiScope(scope = cgi_scope);
		assert('_cgi.path_info eq "/users/list/http_x_original_url"');
		cgi_scope.http_x_original_url = "";
		_cgi = $cgiScope(scope = cgi_scope);
		assert('_cgi.path_info eq "/users/list/request_uri"');
		cgi_scope.request_uri = "";
		_cgi = $cgiScope(scope = cgi_scope);
		assert('_cgi.path_info eq "/users/list/redirect_url"');
	}

	function test_path_info_should_remove_trailing_slash() {
		cgi_scope.path_info = "";
		_cgi = $cgiScope(scope = cgi_scope);
		assert('_cgi.path_info eq "/users/list/http_x_rewrite_url"');
	}

	function test_path_info_non_ascii() {
		e = {
			script_name = "/index.cfm",
			path_info = "/wheels/wheels/%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81",
			unencoded_url = "/index.cfm/wheels/wheels/%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81?normal=1&chinese=%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81",
			query_string = "normal=1&chinese=%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81"
		};
		scope = {
			script_name = "/index.cfm",
			path_info = "/wheels/wheels/????",
			unencoded_url = "/index.cfm/wheels/wheels/%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81?normal=1&chinese=%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81",
			query_string = "normal=1&chinese=%E5%A5%B3%E5%A3%AB%E7%94%A8%E5%93%81"
		};
		r = $cgiScope(keys = "script_name,path_info,unencoded_url,query_string", scope = scope);
		assert('r.path_info IS URLDecode(e.path_info)');
	}

}
