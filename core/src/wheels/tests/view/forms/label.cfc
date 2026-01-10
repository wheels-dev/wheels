component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
		set(functionName = "checkBoxTag", encode = false);
		set(functionName = "textField", encode = false);
		set(functionName = "textFieldTag", encode = false);
	}

	function teardown() {
		set(functionName = "checkBoxTag", encode = true);
		set(functionName = "textField", encode = true);
		set(functionName = "textFieldTag", encode = true);
	}

	/* plain helpers */

	function test_label_to_the_left() {
		actual = _controller.checkBoxTag(name = "the-name", label = "The Label:");
		expected = '<label for="the-name-1">The Label:<input id="the-name-1" name="the-name" type="checkbox" value="1"></label>';
		assert('actual eq expected');
		actual = _controller.checkBoxTag(name = "the-name", label = "The Label:", labelPlacement = "around");
		assert('actual eq expected');
		actual = _controller.checkBoxTag(name = "the-name", label = "The Label:", labelPlacement = "aroundLeft");
		assert('actual eq expected');
	}

	function test_label_to_the_right() {
		actual = _controller.checkBoxTag(name = "the-name", label = "The Label", labelPlacement = "aroundRight");
		expected = '<label for="the-name-1"><input id="the-name-1" name="the-name" type="checkbox" value="1">The Label</label>';
		assert('actual eq expected');
	}

	function test_custom_label_on_plain_helper() {
		actual = _controller.checkBoxTag(name = "the-name", label = "The Label:");
		expected = '<label for="the-name-1">The Label:<input id="the-name-1" name="the-name" type="checkbox" value="1"></label>';
		assert('actual eq expected');
	}

	function test_custom_label_on_plain_helper_and_overriding_id() {
		actual = _controller.checkBoxTag(name = "the-name", label = "The Label:", id = "the-id");
		expected = '<label for="the-id">The Label:<input id="the-id" name="the-name" type="checkbox" value="1"></label>';
		assert('actual eq expected');
	}

	function test_blank_label_on_plain_helper() {
		actual = _controller.textFieldTag(name = "the-name", label = "");
		expected = '<input id="the-name" name="the-name" type="text" value="">';
		assert('actual eq expected');
	}


	/* object based helpers */

	function test_custom_label_on_object_helper() {
		actual = _controller.textField(objectName = "user", property = "username", label = "The Label:");
		expected = '<label for="user-username">The Label:<input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp"></label>';
		assert('actual eq expected');
	}

	function test_custom_label_on_object_helper_and_overriding_id() {
		actual = _controller.textField(
			objectName = "user",
			property = "username",
			label = "The Label:",
			id = "the-id"
		);
		expected = '<label for="the-id">The Label:<input id="the-id" maxlength="50" name="user[username]" type="text" value="tonyp"></label>';
		assert('actual eq expected');
	}

	function test_blank_label_on_object_helper() {
		actual = _controller.textField(objectName = "user", property = "username", label = "");
		expected = '<input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp">';
		assert('actual eq expected');
	}

	function test_automatic_label_on_object_helper_with_around_placement() {
		actual = _controller.textField(objectName = "user", property = "username", labelPlacement = "around");
		expected = '<label for="user-username">Username<input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp"></label>';
		assert('actual eq expected');
	}

	function test_automatic_label_on_object_helper_with_before_placement() {
		actual = _controller.textField(objectName = "user", property = "username", labelPlacement = "before");
		expected = '<label for="user-username">Username</label><input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp">';
		assert('actual eq expected');
	}

	function test_automatic_label_on_object_helper_with_after_placement() {
		actual = _controller.textField(objectName = "user", property = "username", labelPlacement = "after")
		expected = '<input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp"><label for="user-username">Username</label>'
		assert('actual eq expected');
	}

	function test_automatic_label_on_object_helper_with_non_persisted_property() {
		actual = _controller.textField(objectName = "user", property = "virtual");
		expected = '<label for="user-virtual">Virtual<input id="user-virtual" name="user[virtual]" type="text" value=""></label>';
		assert('actual eq expected');
	}

	function test_automatic_label_in_error_message() {
		tag = Duplicate(model("tag").new());
		/* use a deep copy so as not to affect the cached model */
		tag.validatesPresenceOf(property = "name");
		tag.valid();
		errors = tag.errorsOn(property = "name");
		assert('ArrayLen(errors) eq 1 and errors[1].message is "Tag name can''t be empty"');
	}

	function test_automatic_label_in_error_message_with_non_persisted_property() {
		tag = Duplicate(model("tag").new());
		tag.validatesPresenceOf(property = "virtual");
		tag.valid();
		errors = tag.errorsOn(property = "virtual");
		assert('ArrayLen(errors) eq 1 and errors[1].message is "Virtual property can''t be empty"');
	}

}
