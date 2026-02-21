component extends="wheels.tests.Test" {

	function test_returns_true_when_property_is_set() {
		_model = model("author");
		properties = {firstName = "James", lastName = "Gibson"};
		_model = _model.new(properties = properties);
		assert('_model.propertyIsPresent("firstName") eq true');
	}

	function test_returns_false_when_property_is_blank() {
		_model = model("author").new();
		_model.lastName = "";
		assert('_model.propertyIsPresent("lastName") eq false');
	}

	function test_returns_false_when_property_does_not_exist() {
		_model = model("author").new();
		StructDelete(_model, "lastName");
		assert('_model.propertyIsPresent("lastName") eq false');
	}

	function test_dynamic_method_call() {
		_model = model("author");
		properties = {firstName = "James", lastName = "Gibson"};
		_model = _model.new(properties = properties);
		assert('_model.firstNameIsPresent() eq true');
	}

}
