component extends="wheels.tests.Test" {

	function test_findAllKeys() {
		p = model("post").findAll(select = "id");
		posts = model("post").findAllKeys();
		keys = ValueList(p.id);
		assert('posts eq keys');
		p = model("post").findAll(select = "id");
		posts = model("post").findAllKeys(quoted = true);
		keys = QuotedValueList(p.id);
	}

}
