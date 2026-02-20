component extends="wheels.tests.Test" {

	function test_property_cannot_be_set_with_mass_assignment_when_protected() {
		model = model("post");
		_model = Duplicate(_model);
		_model.protectedProperties(properties = "views");
		properties = {views = "2000"};
		_model = _model.new(properties = properties);
		assert('StructKeyExists(_model, "views") eq false');
	}

	function test_property_can_be_set_directly() {
		_model = model("post");
		_model = Duplicate(_model);
		_model.protectedProperties(properties = "views");
		_model = _model.new();
		_model.views = 2000;
		assert('StructKeyExists(_model, "views") eq true');
	}

}
