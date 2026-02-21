component extends="wheels.tests.Test" {

	function test_declaring_required_arguments_throws_error_when_missing() {
		args = {};
		expected = "Wheels.IncorrectArguments";
		actual = raised('$args(args=args, name="sendEmail", combine="template/templates/!")');
		assert('expected eq actual');
		actual = raised('$args(args=args, name="sendEmail", combine="template/templates", required="template")');
		assert('expected eq actual');
		actual = raised('$args(args=args, name="sendEmail", required="template")');
		assert('expected eq actual');
		actual = raised('$args(args=args, name="sendEmail", template="", required="template")');
		args.template = "";
		actual = raised('$args(args=args, name="sendEmail", combine="template/templates", required="template")');
		assert('expected eq actual');
		args.template = "";
		actual = raised('$args(args=args, name="sendEmail", combine="template/templates")');
		assert('actual eq ""');
	}

	function test_not_declaring_required_arguments_should_not_raise_error_when_missing() {
		args = {};
		expected = "";
		actual = raised('$args(args=args, name="sendEmail", combine="template/templates")');
		assert('expected eq actual');
		actual = raised('$args(args=args, name="sendEmail")');
		assert('expected eq actual');
	}

	function test_combined_arguments() {
		expected = "";
		actual = combined_arguments(template = "tony", templates = "per");
		assert('actual.template eq "per"');
		assert('not StructKeyExists(actual, "templates")');
		actual = combined_arguments(templates = "per");
		assert('actual.template eq "per"');
		assert('not StructKeyExists(actual, "templates")');
	}

	/**
	 * HELPERS
	 */

	function combined_arguments() {
		$args(args = arguments, name = "sendEmail", combine = "template/templates");
		return arguments;
	}

}
