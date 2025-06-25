component extends="wheels.tests.Test" {

	function test_getting_children() {
		author = model("author").findOne(order = "id");
		dynamicResult = author.posts();
		coreResult = model("post").findAll(where = "authorId=#author.id#");
		assert("dynamicResult['title'][1] IS coreResult['title'][1]");
	}

	function test_getting_children_with_include() {
		author = model("author").findOne(order = "id", include = "posts");
		assert("IsObject(author) && ArrayLen(author.posts) eq 3");
		author = model("author").findOne(order = "id", include = "posts", returnAs = "query");
		assert("author.recordcount eq 3");
	}

	function test_counting_children() {
		author = model("author").findOne(order = "id");
		dynamicResult = author.postCount();
		coreResult = model("post").count(where = "authorId=#author.id#");
		assert("dynamicResult IS coreResult");
	}

	function test_checking_if_children_exist() {
		author = model("author").findOne(order = "id");
		dynamicResult = author.hasPosts();
		coreResult = model("post").exists(where = "authorId=#author.id#");
		assert("dynamicResult IS coreResult");
	}

	function test_getting_one_child() {
		author = model("author").findOne(order = "id");
		dynamicResult = author.findOnePost();
		coreResult = model("post").findOne(where = "authorId=#author.id#");
		assert("dynamicResult.title IS coreResult.title");
	}

	function test_adding_child_by_setting_foreign_key() {
		author = model("author").findOne(order = "id");
		post = model("post").findOne(order = "id DESC");
		transaction {
			author.addPost(post = post, transaction = "none");
			/* we need to test if authorId is set on the post object as well and not just in the database!*/
			post.reload();
			transaction action="rollback";
		}
		assert("author.id IS post.authorId");
		post.reload();
		transaction {
			author.addPost(key = post.id, transaction = "none");
			post.reload();
			transaction action="rollback";
		}
		assert("author.id IS post.authorId");
		post.reload();
		transaction {
			model("post").updateByKey(key = post.id, authorId = author.id, transaction = "none");
			post.reload();
			transaction action="rollback";
		}
		assert("author.id IS post.authorId");
	}

	function test_removing_child_by_nullifying_foreign_key() {
		author = model("author").findOne(order = "id");
		post = model("post").findOne(order = "id DESC");
		transaction {
			author.removePost(post = post, transaction = "none");
			/* we need to test if authorId is set to blank on the post object as well and not just in the database!*/
			post.reload();
			transaction action="rollback";
		}
		assert("post.authorId IS ''");
		post.reload();
		transaction {
			author.removePost(key = post.id, transaction = "none");
			post.reload();
			transaction action="rollback";
		}
		assert("post.authorId IS ''");
		post.reload();
		transaction {
			model("post").updateByKey(key = post.id, authorId = "", transaction = "none");
			post.reload();
			transaction action="rollback";
		}
		assert("post.authorId IS ''");
	}

	function test_deleting_child() {
		author = model("author").findOne(order = "id");
		post = model("post").findOne(order = "id DESC");
		transaction {
			author.deletePost(post = post, transaction = "none");
			/* should we also set post to false here? */
			assert("NOT model('post').exists(post.id)");
			transaction action="rollback";
		}
		transaction {
			author.deletePost(key = post.id, transaction = "none");
			assert("NOT model('post').exists(post.id)");
			transaction action="rollback";
		}
		transaction {
			model("post").deleteByKey(key = post.id, transaction = "none");
			assert("NOT model('post').exists(post.id)");
			transaction action="rollback";
		}
	}

	function test_removing_all_children_by_nullifying_foreign_keys() {
		author = model("author").findOne(order = "id");
		transaction {
			author.removeAllPosts(transaction = "none");
			dynamicResult = author.postCount();
			remainingCount = model("post").count();
			transaction action="rollback";
		}
		transaction {
			model("post").updateAll(authorId = "", where = "authorId=#author.id#", transaction = "none");
			coreResult = author.postCount();
			transaction action="rollback";
		}
		assert("dynamicResult IS 0 AND coreResult IS 0 AND remainingCount IS 5");
	}

	function test_deleting_all_children() {
		author = model("author").findOne(order = "id");
		transaction {
			author.deleteAllPosts(transaction = "none");
			dynamicResult = author.postCount();
			remainingCount = model("post").count();
			transaction action="rollback";
		}
		transaction {
			model("post").deleteAll(where = "authorId=#author.id#", transaction = "none");
			coreResult = author.postCount();
			transaction action="rollback";
		}
		assert("dynamicResult IS 0 AND coreResult IS 0 AND remainingCount IS 2");
	}

	function test_creating_new_child() {
		author = model("author").findOne(order = "id");
		newPost = author.newPost(title = "New Title");
		dynamicResult = newPost.authorId;
		newPost = model("post").new(authorId = author.id, title = "New Title");
		coreResult = newPost.authorId;
		assert("dynamicResult IS coreResult");
	}

	function test_creating_new_child_and_saving_it() {
		author = model("author").findOne(order = "id");
		transaction {
			newPost = author.createPost(title = "New Title", body = "New Body", transaction = "none");
			dynamicResult = newPost.authorId;
			transaction action="rollback";
		}
		transaction {
			newPost = model("post").create(
				authorId = author.id,
				title = "New Title",
				body = "New Body",
				transaction = "none"
			);
			coreResult = newPost.authorId;
			transaction action="rollback";
		}
		assert("dynamicResult IS coreResult");
	}

	function test_dependency_delete() {
		transaction {
			postWithAuthor = model("post").findOne(order = "id");
			author = model("author").findByKey(key = postWithAuthor.authorId);
			author.hasMany(name = "posts", dependent = "delete");
			author.delete();
			posts = model("post").findAll(where = "authorId=#author.id#");
			transaction action="rollback";
		}
		assert("posts.recordcount eq 0");
	}

	function test_dependency_deleteAll() {
		transaction {
			postWithAuthor = model("post").findOne(order = "id");
			author = model("author").findByKey(key = postWithAuthor.authorId);
			author.hasMany(name = "posts", dependent = "deleteAll");
			author.delete();
			posts = model("post").findAll(where = "authorId=#author.id#");
			transaction action="rollback";
		}
		assert("posts.recordcount eq 0");
	}

	function test_dependency_removeAll() {
		transaction {
			postWithAuthor = model("post").findOne(order = "id");
			author = model("author").findByKey(key = postWithAuthor.authorId);
			author.hasMany(name = "posts", dependent = "removeAll");
			author.delete();
			posts = model("post").findAll(where = "authorId=#author.id#");
			transaction action="rollback";
		}
		assert("posts.recordcount eq 0");
	}

	function test_getting_children_with_join_key() {
		obj = model("user").findOne(order = "id", include = "authors");
		assert('obj.firstName eq obj.authors[1].firstName');
	}

	function test_calculated_property_without_distinct() {
		authors = model("author").findAll(select = "id, firstName, lastName, numberofitems");
		assert('authors.recordCount IS 10');
	}

	function test_select_aggregate_calculated_property_with_distinct() {
		authors = model("author").findAll(select = "id, firstName, lastName, numberofitems", distinct = true);
		assert('authors.recordCount IS 10');
	}

	function test_aggregate_calculated_property_with_distinct() {
		posts = model("post").findAll(select = "id, authorId, firstId", distinct = true);
		assert('posts.recordCount IS 5');
	}

	function test_non_aggregate_calculated_property_with_distinct() {
		posts = model("post").findAll(select = "id, authorId, titleAlias", distinct = true);
		assert('posts.recordCount IS 5');
	}

	function test_calculated_properties_with_included_model_with_distinct() {
		authors = model("author").findAll(
			select = "id, firstName, lastName, numberofitems, titlealias",
			include = "posts",
			distinct = true
		);
		assert('authors.recordCount IS 13');
	}

}
