component extends="wheels.tests.Test" {

	function test_have_access_to_changed_property_values_in_aftersave() {
		model("user").$registerCallback(type = "afterSave", methods = "saveHasChanged");
		obj = model("user").findOne(where = "username = 'tonyp'");
		obj.saveHasChanged = saveHasChanged;
		obj.getHasObjectChanged = getHasObjectChanged;
		assert('obj.hasChanged() eq false');
		obj.password = "xxxxxxx";
		assert('obj.hasChanged() eq true');
		transaction {
			obj.save(transaction = "none");
			assert('obj.getHasObjectChanged() eq true');
			assert('obj.hasChanged() eq false');
			transaction action="rollback";
		}
		model("user").$clearCallbacks(type = "afterSave");
	}

	function saveHasChanged() {
		hasObjectChanged = hasChanged();
	}

	function getHasObjectChanged() {
		return hasObjectChanged;
	}

}
