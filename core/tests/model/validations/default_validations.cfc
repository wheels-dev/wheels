component extends="wheels.tests.Test" {

	function setup() {
		user = model("UserBlank").new();
		user.username = "gavin@cfwheels.org";
		user.password = "disismypassword";
		user.firstName = "Gavin";
		user.lastName = "Gavinsson";
	}

	function test_validates_presence_of_invalid() {
		/* missing key */
		StructDelete(user, "username");
		/* zero length string */
		user.password = "";
		user.valid();
		assert('ArrayLen(user.allErrors()) eq 2');
	}

	function test_validates_presence_of_valid() {
		user.password = "something";
		user.firstName = "blahblah";
		assert('user.valid()');
	}

	function test_validates_presence_of_valid_with_default_on_update() {
		user = model("UserBlank").findOne(); // use existing user to test update
		user.birthtime = "";
		user.save(transaction = "rollback");
		arrResult = user.errorsOn("birthtime");
		assert("ArrayLen(arrResult) eq 1 AND arrResult[1].message eq 'Birthtime can''t be empty'");
	}

	function test_validates_length_of_invalid() {
		user.state = "Too many characters!";
		user.valid();
		arrResult = user.errorsOn("state");
		assert('ArrayLen(arrResult) eq 1 AND arrResult[1].message eq "State is the wrong length"');
	}

	function test_validates_length_of_valid() {
		user.state = "FL";
		assert('user.valid()');
	}

	function test_validates_numericality_of_invalid() {
		user.birthDayMonth = "This is not a number!";
		user.valid();
		arrResult = user.errorsOn("birthDayMonth");
		assert('ArrayLen(arrResult) eq 1 AND arrResult[1].message eq "Birthdaymonth is not a number"');
	}

	function test_validates_numericality_of_valid() {
		user.birthDayMonth = "7";
		assert('user.valid()');
	}

	function test_validates_numericality_of_integer_invalid() {
		user.birthDayMonth = "7.825";
		user.valid();
		arrResult = user.errorsOn("birthDayMonth");
		assert('ArrayLen(arrResult) eq 1 AND arrResult[1].message eq "Birthdaymonth is not a number"');
	}

	function test_validates_format_of_date_invalid() {
		user.birthDay = "This is not a date!";
		user.valid();
		arrResult = user.errorsOn("birthDay");
		assert('ArrayLen(arrResult) eq 1 AND arrResult[1].message eq "Birth day is invalid"');
	}

	function test_validates_format_of_date_valid() {
		user.birthDay = "01/01/2000";
		assert('user.valid()');
	}

	function test_validates_format_of_time_invalid() {
		user.birthTime = "This is not a time!";
		user.valid();
		arrResult = user.errorsOn("birthTime");
		assert('ArrayLen(arrResult) eq 1 AND arrResult[1].message eq "Birthtime is invalid"');
	}

	function test_validates_format_of_time_valid() {
		user.birthTime = "6:15 PM";
		assert('user.valid()');
	}

}