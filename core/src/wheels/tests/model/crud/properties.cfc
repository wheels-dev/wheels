component extends="wheels.tests.Test" {

	function test_updateProperty() {
		transaction action="begin" {
			author = model("Author").findOne(where = "firstName='Andy'");
			saved = author.updateProperty("firstName", "Frog");
			transaction action="rollback";
		}
		assert('saved eq true and author.firstName eq "Frog"');
	}

	function test_updatePropertyWithDynamicArgs() {
		transaction action="begin" {
			author = model("Author").findOne(where = "firstName='Andy'");
			saved = author.updateProperty(firstName = "Frog");
			transaction action="rollback";
		}
		assert('saved eq true and author.firstName eq "Frog"');
	}

	function test_updateProperty_dynamic_method() {
		transaction action="begin" {
			author = model("Author").findOne(where = "firstName='Andy'");
			saved = author.updateFirstName(value = "Frog");
			transaction action="rollback";
		}
		assert('saved eq true and author.firstName eq "Frog"');
	}

	function test_updating_properties() {
		transaction action="begin" {
			author = model("Author").findOne(where = "firstName='Andy'");
			saved = author.update(firstName = "Kirmit", lastName = "Frog");
			transaction action="rollback";
		}
		assert('saved eq true and author.lastName eq "Frog" and author.firstName eq "Kirmit"');
	}

}
