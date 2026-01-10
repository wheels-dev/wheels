component extends="wheels.tests.Test" {

	function setup() {
		args = {
			property = "lastName",
			message = "[property] is the wrong length",
			exactly = 0,
			maximum = 0,
			minimum = 0,
			within = ""
		};
		object = model("user").new();
	}

	function test_Maximum_good() {
		object.lastName = "LessThan";
		object.$validatesLengthOf(argumentCollection = args, maximum = 10);
		assert("!object.hasErrors()");
	}

	function test_Maximum_bad() {
		object.lastName = "SomethingMoreThanTenLetters";
		object.$validatesLengthOf(argumentCollection = args, maximum = 10);
		assert("object.hasErrors()");
	}

	function test_Minimum_good() {
		object.lastName = "SomethingMoreThanTenLetters";
		object.$validatesLengthOf(argumentCollection = args, minimum = 10);
		assert("!object.hasErrors()");
	}

	function test_Minimum_bad() {
		object.lastName = "LessThan";
		object.$validatesLengthOf(argumentCollection = args, minimum = 10);
		assert("object.hasErrors()");
	}

	function test_Within_good() {
		object.lastName = "6Chars";
		within = [4, 8];
		object.$validatesLengthOf(argumentCollection = args, within = within);
		assert("!object.hasErrors()");
	}

	function test_Within_bad() {
		object.lastName = "6Chars";
		within = [2, 5];
		object.$validatesLengthOf(argumentCollection = args, within = within);
		assert("object.hasErrors()");
	}

	function test_Exactly_good() {
		object.lastName = "Exactly14Chars";
		object.$validatesLengthOf(argumentCollection = args, exactly = 14);
		assert("!object.hasErrors()");
	}

	function test_Exactly_bad() {
		object.lastName = "Exactly14Chars";
		object.$validatesLengthOf(argumentCollection = args, exactly = 99);
		assert("object.hasErrors()");
	}

}
