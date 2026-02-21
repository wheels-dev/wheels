component extends="wheels.tests.Test" {

	function test_toggle_property_with_save() {
		_model = model("user").findOne(where = "firstName='Chris'");
		transaction action="begin" {
			saved = _model.toggle("isActive");
			transaction action="rollback";
		}
		assert('_model.isActive eq false and saved eq true');
	}

	function test_toggle_property_without_save() {
		_model = model("user").findOne(where = "firstName='Chris'");
		_model.toggle("isActive", false);
		assert('_model.isActive eq false');
	}

	function test_toggle_property_dynamic_method_without_save() {
		_model = model("user").findOne(where = "firstName='Chris'");
		_model.toggleIsActive(save = false);
		assert('_model.isActive eq false');
	}

	function test_toggle_property_dynamic_method_with_save() {
		_model = model("user").findOne(where = "firstName='Chris'");
		transaction action="begin" {
			saved = _model.toggleIsActive();
			transaction action="rollback";
		}
		assert('_model.isActive eq false and saved eq true');
	}

	function test_toggle_property_without_save_errors_when_not_existing() {
		_model = model("user").findOne(where = "firstName='Chris'");
		error = raised('_model.toggle("isMember", false)');
		assert('error eq "Wheels.PropertyDoesNotExist"');
	}

	function test_toggle_property_without_save_errors_when_not_boolean() {
		_model = model("user").findOne(where = "firstName='Chris'");
		error = raised('_model.toggle("firstName", false)');
		assert('error eq "Wheels.PropertyIsIncorrectType"');
	}

}
