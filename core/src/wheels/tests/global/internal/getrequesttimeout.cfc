component extends="wheels.tests.Test" {

	function teardown() {
		setting requestTimeout=10000;
	}

	function test_$getrequesttimeout() {
		setting requestTimeout=666;
		actual = $getRequestTimeout();
		expected = 666;
		assert("actual eq expected");
	}

}
