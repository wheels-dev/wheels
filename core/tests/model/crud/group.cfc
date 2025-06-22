component extends="wheels.tests.Test" {

	function test_simple_group_by() {
		r = model("tag").findAll(select = "parentId, COUNT(*) AS groupCount", group = "parentId");
		assert('r.recordcount eq 4');
	}

	function test_group_by_calculated_property() {
		r = model("user2").findAll(select = "firstLetter, groupCount", group = "firstLetter", order = "groupCount DESC");
		assert('r.recordcount eq 2');
	}

	function test_distinct_works_with_group_by() {
		r = model("post").findAll(select = "views", distinct = true);
		assert('r.recordcount eq 4');
		r = model("post").findAll(select = "views", group = "views");
		assert('r.recordcount eq 4');
	}

	function test_max_works_with_group_functionality() {
		r = model("post").findAll(
			select = "id, authorid, title, MAX(posts.views) AS maxView",
			group = "id, authorid, title"
		);
		assert('r.recordcount eq 5');
	}

	function test_group_functionality_works_with_pagination() {
		r = model("post").findAll(
			select = "id, authorid, title, MAX(posts.views) AS maxView",
			group = "id, authorid, title",
			page = 1,
			perPage = 2
		);
		assert('r.recordcount eq 2');
	}

}
