component extends="wheels.tests.Test" {

	function test_all_properties_can_be_set_by_default() {
		_model = model("author");
		_model = Duplicate(_model);
		properties = {firstName = "James", lastName = "Gibson"};
		_model = _model.new(properties = properties);
		assert('StructKeyExists(_model, "firstName") eq true');
		assert('StructKeyExists(_model, "lastName") eq true');
	}

	function test_all_other_properties_cannot_be_set_except_accessible_properties() {
		_model = model("post");
		_model = Duplicate(_model);
		_model.accessibleProperties(properties = "views");
		properties = {
			views = "2000",
			averageRating = 4.9,
			body = "This is the body",
			title = "this is the title"
		};
		_model = _model.new(properties = properties);
		assert('StructKeyExists(_model, "averageRating") eq false');
		assert('StructKeyExists(_model, "body") eq false');
		assert('StructKeyExists(_model, "title") eq false');
		assert('StructKeyExists(_model, "views") eq true');
	}

	function test_all_other_properties_can_be_set_directly() {
		_model = model("post");
		_model = Duplicate(_model);
		_model.accessibleProperties(properties = "views");
		_model = _model.new();
		_model.averageRating = 4.9;
		_model.body = "This is the body";
		_model.title = "this is the title";
		assert('StructKeyExists(_model, "averageRating") eq true');
		assert('StructKeyExists(_model, "body") eq true');
		assert('StructKeyExists(_model, "title") eq true');
	}

}
