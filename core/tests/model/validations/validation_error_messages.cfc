component extends="wheels.tests.Test" {

	function setup() {
		StructDelete(application.wheels.models, "users", false);
		user = model("users").new();
		user.username = "TheLongestNameInTheWorld";
		args = {};
		args.property = "username";
		args.minimum = "5";
		args.maximum = "20";
		args.message = "Please shorten your [property] please. [maximum] characters is the maximum length allowed.";
	}

	function test_bracketed_argument_markers_are_replaced() {
		user.validatesLengthOf(argumentCollection = args);
		user.valid();
		asset_test(user, "Please shorten your username please. 20 characters is the maximum length allowed.");
	}

	function test_bracketed_property_argument_marker_at_beginning_is_capitalized() {
		args.message = "[property] must be between [minimum] and [maximum] characters.";
		user.validatesLengthOf(argumentCollection = args);
		user.valid();
		asset_test(user, "Username must be between 5 and 20 characters.");
	}

	function test_bracketed_argument_markers_can_be_escaped() {
		args.message = "[property] must be between [[minimum]] and [maximum] characters.";
		user.validatesLengthOf(argumentCollection = args);
		user.valid();
		asset_test(user, "Username must be between [minimum] and 20 characters.");
	}

	/**
	 * HELPERS
	 */

	function asset_test(required any obj, required string expected) {
		e = arguments.obj.errorsOn("username");
		e = e[1].message;
		r = arguments.expected;
		assert('e eq r');
	}

}
