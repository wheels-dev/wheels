component extends="wheels.tests.Test" {

	function test_getting_parent() {
		obj = model("post").findOne(order = "id");
		dynamicResult = obj.author();
		coreResult = model("author").findByKey(obj.authorId);
		assert("dynamicResult.key() IS coreResult.key()");
		dynamicResult = obj.author(select = "lastName", returnAs = "query");
		coreResult = model("author").findByKey(key = obj.authorId, select = "lastName", returnAs = "query");
		assert(
			"IsQuery(dynamicResult) AND ListLen(dynamicResult.columnList) IS 1 AND IsQuery(coreResult) AND ListLen(coreResult.columnList) IS 1 AND dynamicResult.lastName IS coreResult.lastName"
		);
	}

	function test_checking_if_parent_exists() {
		obj = model("post").findOne(order = "id");
		dynamicResult = obj.hasAuthor();
		coreResult = model("author").exists(obj.authorId);
		assert("dynamicResult IS coreResult");
	}

	function test_getting_parent_on_new_object() {
		authorByFind = model("author").findOne(order = "id");
		newPost = model("post").new(authorId = authorByFind.id);
		authorByAssociation = newPost.author();
		assert("authorByFind.key() IS authorByAssociation.key()");
	}

	function test_checking_if_parent_exists_on_new_object() {
		authorByFind = model("author").findOne(order = "id");
		newPost = model("post").new(authorId = authorByFind.id);
		authorExistsByAssociation = newPost.hasAuthor();
		assert("authorExistsByAssociation IS true");
	}

	function test_getting_parent_with_join_key() {
		obj = model("author").findOne(order = "id", include = "user");
		assert('obj.firstName eq obj.user.firstName');
	}

}
