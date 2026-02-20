component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		application.wheels.assetQueryString = true;
	}

	function teardown() {
		application.wheels.assetQueryString = false;
	}

	function test_returns_empty_string_when_set_false() {
		application.wheels.assetQueryString = false;
		e = _controller.$appendQueryString();
		assert('Len(e) eq 0');
	}

	function test_returns_string_when_set_true() {
		e = _controller.$appendQueryString();
		assert('IsSimpleValue(e) eq true');
	}

	function test_returns_match_when_set_to_string() {
		application.wheels.assetQueryString = "MySpecificBuildNumber";
		e = _controller.$appendQueryString();
		assert('e eq "?MySpecificBuildNumber"');
	}

	function test_returns_same_value_without_reload() {
		iEnd = 100;
		application.wheels.assetQueryString = "MySpecificBuildNumber";
		e = _controller.$appendQueryString();
		for (i = 1; i lte iEnd; i++) {
			assert('_controller.$appendQueryString() eq e');
		}
		assert('e eq "?MySpecificBuildNumber"');
	}

}
