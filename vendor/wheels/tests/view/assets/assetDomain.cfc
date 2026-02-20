component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		application.wheels.assetPaths = {http = "asset0.localhost, asset2.localhost", https = "secure.localhost"};
	}

	function teardown() {
		application.wheels.assetPaths = false;
	}

	function test_returns_protocol() {
		assetPath = "/javascripts/path/to/my/asset.js";
		e = _controller.$assetDomain(assetPath);
		assert('FindNoCase("http://", e) or FindNoCase("https://", e)');
	}

	function test_returns_secure_protocol() {
		request.cgi.server_port_secure = true;
		assetPath = "/javascripts/path/to/my/asset.js";
		e = _controller.$assetDomain(assetPath);
		assert('FindNoCase("https://", e)');
		request.cgi.server_port_secure = "";
	}

	function test_returns_same_domain_for_asset() {
		assetPath = "/javascripts/path/to/my/asset.js";
		e = _controller.$assetDomain(assetPath);
		iEnd = 100;
		for (i = 1; i lte iEnd; i++) {
			assert('e eq _controller.$assetDomain(assetPath)');
		};
	}

	function test_returns_asset_path_when_set_false() {
		application.wheels.assetPaths = false;
		assetPath = "/javascripts/path/to/my/asset.js";
		e = _controller.$assetDomain(assetPath);
		assert('e eq assetPath');
		application.wheels.assetPaths = {http = "asset0.localhost, asset2.localhost", https = "secure.localhost"};
	}

}
