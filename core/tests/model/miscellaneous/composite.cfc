component extends="wheels.tests.Test" {

	function test_associate_with_a_single_key_from_the_composite() {
		shops = model("shop").findone(include = "city");
		assert("IsObject(shops)");
	}

}
