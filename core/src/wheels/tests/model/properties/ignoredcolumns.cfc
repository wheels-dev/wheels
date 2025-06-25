component extends="wheels.tests.Test" {

	function test_ignoredColumns() {
		shop = model("shop").findOne();
		assert('StructKeyExists(shop, "isblackmarket") eq false');
	}

}
