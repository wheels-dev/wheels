component extends="wheels.tests.Test" {

	function test_utc_timestamps() {
		transaction {
			utctime = DateConvert("local2Utc", Now());
			author = model("Author").findOne();
			post = author.createPost(title = "test post", body = "here is some text");
			assert('DateDiff("s", utctime, post.createdAt) lte 2'); // allow 1 second between test value and inserted value
			assert('DateDiff("s", utctime, post.updatedAt) lte 2');
			transaction action="rollback";
		}
	}

	function test_local_timestamps() {
		transaction {
			localtime = Now();
			model("Post").getClass().timeStampMode = "local";
			author = model("Author").findOne();
			post = author.createPost(title = "test post", body = "here is some text");
			assert('DateDiff("s", localtime, post.createdAt) lte 2'); // allow 1 second between test value and inserted value
			assert('DateDiff("s", localtime, post.updatedAt) lte 2');
			transaction action="rollback";
		}
	}

	function test_epoch_timestamps() {
		transaction {
			epochtime = Now().getTime();
			model("Post").getClass().timeStampOnCreateProperty = "createdAtEpoch";
			model("Post").getClass().timeStampOnUpdateProperty = "updatedAtEpoch";
			model("Post").getClass().timeStampMode = "epoch";
			author = model("Author").findOne();
			post = author.createPost(title = "test post", body = "here is some text", createdAt = Now(), updatedAt = Now());
			assert('post.createdAtEpoch - epochtime lte 2000'); // allow 1 second between test value and inserted value
			assert('post.updatedAtEpoch - epochtime lte 2000'); // allow 1 second between test value and inserted value
			transaction action="rollback";
		}
	}

	function test_updatedAt_does_not_change_when_no_changes_to_model() {
		transaction {
			post = model("Post").findOne();
			orgUpdatedAt = post.properties().updatedAt;
			post.update();
			post.reload();
			newUpdatedAt = post.properties().updatedAt;
			assert('orgUpdatedAt eq newUpdatedAt');
			transaction action="rollback";
		}
	}

	function test_createdAt_does_not_change_on_update() {
		transaction {
			post = model("Post").findOne();
			orgCreatedAt = post.properties().createdAt;
			post.update(body = "here is some updated text");
			post.reload();
			newCreatedAt = post.properties().createdAt;
			assert('orgCreatedAt eq newCreatedAt');
			transaction action="rollback";
		}
	}

	function test_explicit_timestamps_are_respected_on_create() {
		transaction {
			author = model("Author").findOne();
			post = author.createPost(
				title = "test_explicit_timestamps_are_respected test post",
				body = "here is some text",
				createdAt = CreateDate(1969, 4, 1),
				updatedAt = CreateDate(1970, 4, 1),
				allowExplicitTimestamps = true
			);
			assert("Year(post.createdAt) eq 1969");
			assert("Year(post.updatedAt) eq 1970");
			transaction action="rollback";
		}
	}

	function test_explicit_timestamps_are_respected_on_update() {
		transaction {
			author = model("Author").findOne();
			author.update(
				city = "Dateville",
				createdAt = CreateDate(1972, 4, 1),
				updatedAt = CreateDate(1974, 4, 1),
				allowExplicitTimestamps = true
			);
			assert("Year(author.createdAt) eq 1972");
			assert("Year(author.updatedAt) eq 1974");
			transaction action="rollback";
		}
	}

	function test_explicit_timestamps_require_allowexplicittimestamps_on_create() {
		transaction {
			utctime = DateConvert("local2Utc", Now());
			author = model("Author").findOne();
			post = author.createPost(
				title = "test_default_timestamps test post",
				body = "here is some text",
				createdAt = CreateDate(1969, 4, 1),
				updatedAt = CreateDate(1970, 4, 1)
			);
			assert('DateDiff("s", utctime, post.createdAt) lte 2');
			assert('DateDiff("s", utctime, post.updatedAt) lte 2');
			transaction action="rollback";
		}
	}

	function teardown() {
		// reset all changes to post model class
		model("Post").getClass().timeStampOnCreateProperty = "createdAt";
		model("Post").getClass().timeStampOnUpdateProperty = "updatedAt";
		model("Post").getClass().timeStampMode = "utc";
	}

}