component extends="wheels.tests.Test" {

	function setup() {
		pkg.controller = controller("dummy");
		result = "";
		results = {};
	}

	function testBasic() {
		result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
			counter = 5,
			value = "",
			$optionNames = "",
			$type = ""
		);
		assert("result IS '<option value=""5"">5</option>'");
	}

	function testSelected() {
		result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
			counter = 3,
			value = 3,
			$optionNames = "",
			$type = ""
		);
		assert("result IS '<option selected=""selected"" value=""3"">3</option>'");
	}

	function testFormatting() {
		result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
			counter = 1,
			value = "",
			$optionNames = "",
			$type = "minute"
		);
		assert("result IS '<option value=""1"">01</option>'");
		result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
			counter = 59,
			value = "",
			$optionNames = "",
			$type = "second"
		);
		assert("result IS '<option value=""59"">59</option>'");
	}

	function testOptionName() {
		result = pkg.controller.$yearMonthHourMinuteSecondSelectTagContent(
			counter = 1,
			value = "",
			$optionNames = "someName",
			$type = ""
		);
		assert("result IS '<option value=""1"">someName</option>'");
	}

}
