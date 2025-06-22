component extends="wheels.tests.Test" {

	function test_objectids_should_be_sequential_and_norepeating() {
		photos = [];
		s = {};
		for (i = 1; i lte 30; i++) {
			ArrayAppend(photos, model("photo").new());
		};
		gallery = model("gallery").new(photos = photos);
		for (i in gallery.photos) {
			s[i.$objectid()] = "";
		};
		assert('StructCount(s) eq 30');
	}

}
