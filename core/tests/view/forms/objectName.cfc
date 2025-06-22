component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithNestedModel");
	}

	function test_$objectName_with_objectName() {
		objectName = _controller.$objectName(objectName = "author");
		assert('objectName eq "author"');
	}

	function test_$objectName_with_objectName_as_struct() {
		struct = {formField = "formValue"};
		objectName = _controller.$objectName(objectName = struct);
		assert('IsStruct(objectName) eq true');
	}

	function test_$objectName_hasOne_association() {
		objectName = _controller.$objectName(objectName = "author", association = "profile");
		assert('objectName eq "author[''profile'']"');
	}

	function test_$objectName_hasMany_association() {
		objectName = _controller.$objectName(objectName = "author", association = "posts", position = "1");
		assert('objectName eq "author[''posts''][1]"');
	}

	function test_$objectName_hasMany_associations_nested() {
		objectName = _controller.$objectName(objectName = "author", association = "posts,comments", position = "1,2");
		assert('objectName eq "author[''posts''][1][''comments''][2]"');
	}

	function test_$objectName_raises_error_without_correct_positions() {
		e = raised('_controller.$objectName(objectName="author", association="posts,comments", position="1")');
		assert('e eq "Wheels.InvalidArgument"');
	}

}
