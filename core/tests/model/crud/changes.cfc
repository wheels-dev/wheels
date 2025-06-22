component extends="wheels.tests.Test" {

	function test_clearing_all_change_info() {
		author = model("author").findOne(select = "firstName");
		author.firstName = "asfdg9876asdgf";
		author.lastName = "asfdg9876asdgf";
		result = author.hasChanged();
		assert("result");
		author.clearChangeInformation();
		result = author.hasChanged();
		assert("NOT result");
	}

	function test_clearing_property_change_info() {
		author = model("author").findOne(select = "firstName");
		author.firstName = "asfdg9876asdgf";
		author.lastName = "asfdg9876asdgf";
		result = author.hasChanged(property = "firstName");
		assert("result");
		result = author.hasChanged(property = "lastName");
		assert("result");
		author.clearChangeInformation(property = "firstName");
		result = author.hasChanged(property = "firstName");
		assert("NOT result");
		result = author.hasChanged(property = "lastName");
		assert("result");
	}

	function test_comparing_existing_properties_only() {
		author = model("author").findOne(select = "firstName");
		result = author.hasChanged();
		assert("NOT result");
		result = author.hasChanged("firstName");
		assert("NOT result");
		author = model("author").findOne();
		StructDelete(author, "firstName");
		result = author.hasChanged();
		assert("NOT result");
		result = author.hasChanged("firstName");
		assert("NOT result");
		result = author.hasChanged("somethingThatDoesNotExist");
		assert("NOT result");
	}

	function test_allChanges() {
		author = model("author").findOne(order = "id");
		author.firstName = "a";
		author.lastName = "b";
		compareWith.firstName.changedFrom = "Per";
		compareWith.firstName.changedTo = "a";
		compareWith.lastName.changedFrom = "Djurner";
		compareWith.lastName.changedTo = "b";
		result = author.allChanges();
		assert("result.toString() IS compareWith.toString()");
	}

	function test_changedProperties() {
		author = model("author").findOne();
		author.firstName = "a";
		author.lastName = "b";
		result = ListSort(author.changedProperties(), "textnocase");
		assert("result IS 'firstName,lastName'");
	}

	function test_changedProperties_without_changes() {
		author = model("author").findOne();
		result = author.changedProperties();
		assert("result IS ''");
	}

	function test_changedProperties_change_and_back() {
		author = model("author").findOne();
		author.oldFirstName = author.firstName;
		author.firstName = "a";
		result = author.changedProperties();
		assert("result IS 'firstName'");
		author.firstName = author.oldFirstName;
		result = author.changedProperties();
		assert("result IS ''");
	}

	function test_isNew() {
		transaction {
			author = model("author").new(firstName = "Per", lastName = "Djurner");
			result = author.isNew();
			assert("result IS true");
			author.save(transaction = "none");
			result = author.isNew();
			assert("result IS false");
			transaction action="rollback";
		}
	}

	function test_isNew_with_find() {
		author = model("author").findOne();
		result = author.isNew();
		assert("result IS false");
	}

	function test_isPeristed() {
		transaction {
			author = model("author").new(firstName = "Per", lastName = "Djurner");
			result = author.isPersisted();
			assert("result is false");
			author.save(transaction = "none");
			result = author.isPersisted();
			assert("result is true");
			transaction action="rollback";
		}
	}

	function test_isPersisted_with_find() {
		author = model("author").findOne();
		result = author.isPersisted();
		assert("result is true");
	}

	function test_hasChanged() {
		author = model("author").findOne(where = "lastName = 'Djurner'");
		result = author.hasChanged();
		assert("result IS false");
		author.lastName = "Petruzzi";
		result = author.hasChanged();
		assert("result IS true");
		author.lastName = "Djurner";
		result = author.hasChanged();
		assert("result IS false");
	}

	function test_hasChanged_with_new() {
		transaction {
			author = model("author").new();
			result = author.hasChanged();
			assert("result IS true");
			author.firstName = "Per";
			author.lastName = "Djurner";
			author.save(transaction = "none");
			result = author.hasChanged();
			assert("result IS false");
			author.lastName = "Petruzzi";
			result = author.hasChanged();
			assert("result IS true");
			author.save(transaction = "none");
			result = author.hasChanged();
			assert("result IS false");
			transaction action="rollback";
		}
	}

	function test_XXXHasChanged() {
		author = model("author").findOne(where = "lastName = 'Djurner'");
		author.lastName = "Petruzzi";
		result = author.lastNameHasChanged();
		assert("result IS true");
		result = author.firstNameHasChanged();
		assert("result IS false");
	}

	function test_changedFrom() {
		author = model("author").findOne(where = "lastName = 'Djurner'");
		author.lastName = "Petruzzi";
		result = author.changedFrom(property = "lastName");
		assert("result IS 'Djurner'");
	}

	function test_XXXChangedFrom() {
		author = model("author").findOne(where = "lastName = 'Djurner'");
		author.lastName = "Petruzzi";
		result = author.lastNameChangedFrom(property = "lastName");
		assert("result IS 'Djurner'");
	}

	function test_date_compare() {
		user = model("user").findOne(where = "username = 'tonyp'");
		user.birthday = "11/01/1975 12:00 AM";
		e = user.hasChanged("birthday");
		assert('e eq false');
	}

	function test_binary_compare() {
		transaction {
			photo = model("photo").findOne(order = model("photo").primaryKey());
			assert("NOT photo.hasChanged('fileData')");
			binaryData = FileReadBinary(ExpandPath('/wheels/tests/_assets/files/cfwheels-logo.png'));
			photo.fileData = binaryData;
			assert("photo.hasChanged('fileData')");
			photo.galleryid = 99;
			photo.save();
			assert("NOT photo.hasChanged('fileData')");
			photo = model("photo").findOne(where = "galleryid=99");
			assert("NOT photo.hasChanged('fileData')");
			binaryData = FileReadBinary(ExpandPath('/wheels/tests/_assets/files/cfwheels-logo.txt'));
			photo.fileData = binaryData;
			assert("photo.hasChanged('fileData')");
			transaction action="rollback";
		}
	}

	function test_float_compare() {
		transaction {
			post = model("post").findByKey(2);
			post.averagerating = 3.0000;
			post.save(reload = true);
			post.averagerating = "3.0000";
			changed = post.hasChanged("averagerating");
			assert('changed eq false');
			transaction action="rollback";
		}
	}

}
