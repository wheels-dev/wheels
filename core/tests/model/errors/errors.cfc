component extends="wheels.tests.Test" {

	function setup() {
		user = model("user").findOne();
		user.addErrorToBase(message = "base error1");
		user.addErrorToBase(message = "base name error1", name = "base_errors");
		user.addErrorToBase(message = "base name error2", name = "base_errors");
		user.addError(property = "firstname", message = "firstname error1");
		user.addError(property = "firstname", message = "firstname error2");
		user.addError(property = "firstname", message = "firstname name error1", name = "firstname_errors");
		user.addError(property = "firstname", message = "firstname name error2", name = "firstname_errors");
		user.addError(property = "firstname", message = "firstname name error3", name = "firstname_errors");
		user.addError(property = "lastname", message = "lastname error1");
		user.addError(property = "lastname", message = "lastname error2");
		user.addError(property = "lastname", message = "lastname error3");
		user.addError(property = "lastname", message = "lastname name error1", name = "lastname_errors");
		user.addError(property = "lastname", message = "lastname name error2", name = "lastname_errors");
	}

	function test_error_information_for_lastname_property_no_name_provided() {
		r = user.hasErrors(property = "lastname");
		assert('r eq true');
		r = user.errorCount(property = "lastname");
		assert('r eq 3');
		user.clearErrors(property = "lastname");
		r = user.errorCount(property = "lastname");
		assert('r eq 0');
		r = user.hasErrors();
		assert('r eq true');
		r = user.hasErrors(property = "lastname");
		assert('r eq false');
		r = user.hasErrors(property = "lastname", name = "lastname_errors");
		assert('r eq true');
	}

	function test_error_information_for_lastname_property_name_provided() {
		r = user.hasErrors(property = "lastname", name = "lastname_errors");
		assert('r eq true');
		r = user.errorCount(property = "lastname", name = "lastname_errors");
		assert('r eq 2');
		user.clearErrors(property = "lastname", name = "lastname_errors");
		r = user.errorCount(property = "lastname", name = "lastname_errors");
		assert('r eq 0');
		r = user.hasErrors();
		assert('r eq true');
		r = user.hasErrors(property = "lastname", name = "lastname_errors");
		assert('r eq false');
		r = user.hasErrors(property = "lastname");
		assert('r eq true');
	}

	function test_error_information_for_firstname_property_no_name_provided() {
		r = user.hasErrors(property = "firstname");
		assert('r eq true');
		r = user.errorCount(property = "firstname");
		assert('r eq 2');
		user.clearErrors(property = "firstname");
		r = user.errorCount(property = "firstname");
		assert('r eq 0');
		r = user.hasErrors();
		assert('r eq true');
		r = user.hasErrors(property = "firstname");
		assert('r eq false');
		r = user.hasErrors(property = "firstname", name = "firstname_errors");
		assert('r eq true');
	}

	function test_error_information_for_firstname_property_name_provided() {
		r = user.hasErrors(property = "firstname", name = "firstname_errors");
		assert('r eq true');
		r = user.errorCount(property = "firstname", name = "firstname_errors");
		assert('r eq 3');
		user.clearErrors(property = "firstname", name = "firstname_errors");
		r = user.errorCount(property = "firstname", name = "firstname_errors");
		assert('r eq 0');
		r = user.hasErrors();
		assert('r eq true');
		r = user.hasErrors(property = "firstname", name = "firstname_errors");
		assert('r eq false');
		r = user.hasErrors(property = "firstname");
		assert('r eq true');
	}

	function test_error_information_for_base_no_name_provided() {
		r = user.hasErrors();
		assert('r eq true');
		r = user.errorCount();
		assert('r eq 13');
		user.clearErrors();
		r = user.errorCount();
		assert('r eq 0');
		r = user.hasErrors();
		assert('r eq false');
		r = user.hasErrors(property = "lastname");
		assert('r eq false');
		r = user.hasErrors(property = "lastname", name = "lastname_errors");
		assert('r eq false');
		r = user.hasErrors(property = "firstname");
		assert('r eq false');
		r = user.hasErrors(property = "firstname", name = "firstname_errors");
		assert('r eq false');
	}

	function test_error_information_for_base_name_provided() {
		r = user.hasErrors(name = "base_errors");
		assert('r eq true');
		r = user.errorCount(name = "base_errors");
		assert('r eq 2');
		user.clearErrors(name = "base_errors");
		debug('user.allErrors()', false);
		r = user.errorCount(name = "base_errors");
		assert('r eq 0');
		r = user.hasErrors(name = "base_errors");
		assert('r eq false');
		r = user.hasErrors(property = "lastname");
		assert('r eq true');
		r = user.hasErrors(property = "lastname", name = "lastname_errors");
		assert('r eq true');
		r = user.hasErrors(property = "firstname");
		assert('r eq true');
		r = user.hasErrors(property = "firstname", name = "firstname_errors");
		assert('r eq true');
	}

	function test_error_information_for_incorrect_property() {
		r = user.hasErrors(property = "firstnamex");
		assert('r eq false');
		r = user.errorCount(property = "firstnamex");
		assert('r eq 0');
		user.clearErrors(property = "firstnamex");
		r = user.hasErrors();
		assert('r eq true');
		r = user.hasErrors(property = "firstname");
		assert('r eq true');
		r = user.hasErrors(property = "firstname", name = "firstname_errors");
		assert('r eq true');
	}

	function test_error_information_for_incorrect_name_on_property() {
		r = user.hasErrors(property = "firstname", name = "firstname_errorsx");
		assert('r eq false');
		r = user.errorCount(property = "firstname", name = "firstname_errorsx");
		assert('r eq 0');
		user.clearErrors(property = "firstname", name = "firstname_errorsx");
		r = user.hasErrors();
		assert('r eq true');
		r = user.hasErrors(property = "firstname", name = "firstname_errors");
		assert('r eq true');
		r = user.hasErrors(property = "firstname");
		assert('r eq true');
	}

	function test_error_information_for_incorrect_name_on_base() {
		r = user.hasErrors(name = "base_errorsx");
		assert('r eq false');
		r = user.errorCount(name = "base_errorsx");
		assert('r eq 0');
		user.clearErrors(name = "base_errorsx");
		r = user.hasErrors(name = "base_errors");
		assert('r eq true');
		r = user.hasErrors(property = "lastname");
		assert('r eq true');
		r = user.hasErrors(property = "lastname", name = "lastname_errors");
		assert('r eq true');
		r = user.hasErrors(property = "firstname");
		assert('r eq true');
		r = user.hasErrors(property = "firstname", name = "firstname_errors");
		assert('r eq true');
	}

}
