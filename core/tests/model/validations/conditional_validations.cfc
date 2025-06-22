component extends="wheels.tests.Test" {

	function setup() {
		user = application.wirebox.getInstance( "wheels.tests._assets.models.Model" ).$initModelClass(
			name = "Users",
			path = get("modelPath")
		);
		user.username = "TheLongestNameInTheWorld";
		args = {};
		args.property = "username";
		args.maximum = "5";
	}

	function test_unless_validation_using_expression_valid() {
		args.unless = "1 eq 1";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, true);
	}

	function test_unless_validation_using_expression_invalid() {
		args.unless = "1 eq 0";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, false);
	}

	function test_unless_validation_using_method_valid() {
		args.unless = "isnew()";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, true);
	}

	function test_unless_validation_using_method_invalid() {
		args.unless = "!isnew()";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, false);
	}

	function test_unless_validation_using_method_mixin_and_parameters_valid() {
		user.stupid_mixin = stupid_mixin;
		args.unless = "this.stupid_mixin(b='1' , a='2') eq 3";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, true);
	}

	function test_unless_validation_using_method_mixin_and_parameters_invalid() {
		user.stupid_mixin = stupid_mixin;
		args.unless = "this.stupid_mixin(b='1' , a='2') neq 3";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, false);
	}

	function test_if_validation_using_expression_invalid() {
		args.condition = "1 eq 1";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, false);
	}

	function test_if_validation_using_expression_valid() {
		args.condition = "1 eq 0";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, true);
	}

	function test_if_validation_using_method_invalid() {
		args.condition = "isnew()";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, false);
	}

	function test_if_validation_using_method_valid() {
		args.condition = "!isnew()";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, true);
	}

	function test_if_validation_using_method_mixin_and_parameters_invalid() {
		user.stupid_mixin = stupid_mixin;
		args.condition = "this.stupid_mixin(b='1' , a='2') eq 3";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, false);
	}

	function test_if_validation_using_method_mixin_and_parameters_valid() {
		user.stupid_mixin = stupid_mixin;
		args.condition = "this.stupid_mixin(b='1' , a='2') neq 3";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, true);
	}

	function test_both_validations_if_trigged_unless_not_trigged_valid() {
		args.condition = "1 eq 1";
		args.unless = "this.username eq 'TheLongestNameInTheWorld'";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, true);
	}

	function test_both_validations_if_trigged_unless_trigged_invalid() {
		args.condition = "1 eq 1";
		args.unless = "this.username eq ''";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, false);
	}

	function test_both_validations_if_not_trigged_unless_not_trigged_valid() {
		args.condition = "1 eq 0";
		args.unless = "this.username eq 'TheLongestNameInTheWorld'";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, true);
	}

	function test_both_validations_if_not_trigged_unless_trigged_valid() {
		args.condition = "1 eq 0";
		args.unless = "this.username eq ''";
		user.validatesLengthOf(argumentCollection = args);
		assert_test(user, true);
	}

	/**
	 * HELPERS
	 */

	function assert_test(required any obj, required boolean expect) {
		e = arguments.obj.valid();
		assert('e eq #arguments.expect#');
	}

	function stupid_mixin(required numeric a, required numeric b) {
		return a + b;
	}

}
