component extends="wheels.tests.Test" {

	function setup() {
		_debug = false;
	}

	function test_setting_and_getting_properties() {
		user = model("user").new();

		args = {};
		args.Address = "1313 mockingbird lane";
		args.City = "deerfield beach";
		args.Fax = "9545551212";
		args.FirstName = "anthony";
		args.LastName = "Petruzzi";
		args.Password = "it's a secret";
		args.Phone = "9544826106";
		args.State = "fl";
		args.UserName = "tonypetruzzi";
		args.ZipCode = "33441";
		args.Id = "";
		args.birthday = "11/01/1975";
		args.birthdaymonth = "11";
		args.birthdayyear = "1975";
		args.allowExplicitTimestamps = false;

		user.setProperties(args);

		props = user.properties();

		for (i in props) {
			actual = props[i];
			expected = args[i];
			assert("actual eq expected");
		};

		args.FirstName = "per";
		args.LastName = "djurner";

		user.setproperties(firstname = "per", lastname = "djurner");
		props = user.properties();

		for (i in props) {
			actual = props[i];
			expected = args[i];
			assert("actual eq expected");
		};

		args.FirstName = "chris";
		args.LastName = "peters";
		args.ZipCode = "33333";

		_params = {};
		_params.lastname = "peters";
		_params.zipcode = "33333";

		user.setproperties(firstname = "chris", properties = _params);
		props = user.properties();

		for (i in props) {
			actual = props[i];
			expected = args[i];
			assert("actual eq expected");
		};
	}

	function test_setting_and_getting_properties_with_named_arguments() {
		author = model("author").findOne();
		author.setProperties(firstName = "a", lastName = "b");
		result = author.properties();
		assert('result.firstName eq "a"');
		assert('result.lastName eq "b"');
	}

	function test_properties_returns_expected_struct_keys() {
		author = model("author").new(firstName = "Foo", lastName = "Bar");

		_properties = author.properties();
		actual = ListSort(StructKeyList(_properties), "text");
		expected = "allowExplicitTimestamps,firstName,lastName";

		assert('actual eq expected');
		assert("author.firstName eq 'Foo'");
		assert("author.lastName eq 'Bar'");
	}

	function test_nested_property_returns_an_object() {
		author = model("author").new(firstName = "Foo", lastName = "Bar");
		author.post = model("post").new(title = "Brown Fox");
		_properties = author.properties();

		actual = IsObject(_properties.post);
		expected = true;

		debug("author.properties()", _debug);

		assert('actual eq expected');
	}

	function test_nested_properties_returns_array_of_objects() {
		author = model("author").new(firstName = "Foo", lastName = "Bar");
		author.posts = [model("post").new(title = "Brown Fox"), model("post").new(title = "Lazy Dog")];

		actual = author.properties().posts[2];

		debug("actual", _debug);

		assert('IsObject(actual)');
	}

	function test_nested_property_is_not_returned_when_returnincluded_is_false() {
		author = model("author").new(firstName = "Foo", lastName = "Bar");
		author.post = model("post").new(title = "Brown Fox");

		_properties = author.properties(returnIncluded = false);
		actual = ListSort(StructKeyList(_properties), "text");
		expected = "allowExplicitTimestamps,firstName,lastName";

		debug("author.properties()", _debug);

		assert('actual eq expected');
	}

	function test_afterfind_callback_returns_included_model_as_object() {
		mypost = model("postWithAfterFindCallback").findOne(include = "author");
		assert("IsObject(mypost.author)");
	}

	function test_calculated_property_override() {
		user = model("User3").findOne();
		assert("IsObject(user) and user.firstName eq 'Calculated Property Column Override'");
	}

}
