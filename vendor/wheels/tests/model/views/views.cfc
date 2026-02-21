component extends="wheels.tests.Test" {

	function test_should_be_able_to_query_views_on_a_column() {
		view = model("ViewUserPhotoKeyUserId").findAll(where = "username = 'tonyp'");
		assert('view.recordcount neq 0');
		view = model("ViewUserPhotoKeyPhotoGalleryId").findAll(where = "username = 'tonyp'");
		assert('view.recordcount neq 0');
	}

	function test_should_be_able_to_query_views_on_the_specified_primary_key() {
		view = model("ViewUserPhotoKeyUserId").findOne(order = "userid");
		view = model("ViewUserPhotoKeyUserId").findByKey(view.userid);
		assert('IsObject(view)');
		view = model("ViewUserPhotoKeyPhotoGalleryId").findOne(order = "galleryid");
		view = model("ViewUserPhotoKeyPhotoGalleryId").findByKey(view.galleryid);
		assert('IsObject(view)');
	}

	function test_associations_should_still_work() {
		view = model("ViewUserPhotoKeyPhotoGalleryId").findAll(include = "photos", where = "username = 'tonyp'");
		assert('view.recordcount neq 0');
	}

}
