component extends="wheels.tests.Test" {

	function setup() {
		objectPath = "/wheels/tests/_assets/models/";
		name = "PHOTOGALLERY";
	}

	function teardown() {
	}

	function test_$fileExistsNoCase_returns_filename() {
		expected = "PhotoGallery.cfc";
		actual = $fileExistsNoCase(ExpandPath(objectPath) & name & ".cfc");
		assert("actual EQ expected");
	}

	function test_$objectFileName_returns_model_class_name_in_same_case_as_file_wo_exandpath() {
		actual = $objectFileName(name = "PhotoGallery", objectPath = objectPath, type = "model");
		expected = "PhotoGallery";
		assert("Compare(actual, expected) eq 0", "actual", "expected", "objectPath");
	}

}
