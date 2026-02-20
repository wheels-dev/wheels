component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
		args = {};
		args.objectName = "user";
		args.label = false;
		selected = {};
		selected.month = '<option selected="selected" value="11">November</option>';
		selected.day = '<option selected="selected" value="1">1</option>';
		selected.year = '<option selected="selected" value="1975">1975</option>';
		set(functionName = "dateTimeSelect", encode = false);
	}

	function teardown() {
		set(functionName = "dateTimeSelect", encode = true);
	}

	function testSplittingLabels() {
		result = _controller.dateTimeSelect(
			objectName = "user",
			property = "birthday",
			label = "labelMonth,labelDay,labelYear,labelHour,labelMinute,labelSecond"
		);
		assert("result Contains 'labelDay' AND result Contains 'labelSecond'");
	}

	function test_datetimeselect() {
		args.property = "birthday";
		r = _controller.dateTimeSelect(argumentcollection = args);
		assert("r contains selected.month");
		assert("r contains selected.day");
		assert("r contains selected.year");
	}

	function test_datetimeselect_not_combined() {
		args.property = "birthday";
		args.combine = "false";
		r = _controller.dateTimeSelect(argumentcollection = args);
		assert("r contains selected.month");
		assert("r contains selected.day");
		assert("r contains selected.year");
	}

	function test_splitting_lable_classes() {
		labelClass = "month,day,year";
		r = _controller.dateTimeSelect(
			objectName = "user",
			property = "birthday",
			label = "labelMonth,labelDay,labelYear",
			labelClass = "#labelClass#"
		);
		for (i in ListToArray(labelClass)) {
			e = 'label class="#i#"';
			assert('r Contains e');
		};
	}

	function test_ampm_select_coming_is_displayed_twice() {
		r = _controller.dateTimeSelect(
			objectName = 'user',
			property = 'birthday',
			dateOrder = 'month,day,year',
			monthDisplay = 'abbreviations',
			twelveHour = 'true',
			label = ''
		);
		a = ReMatchNoCase("user\[birthday\]\(\$ampm\)", r);
		assert('ArrayLen(a) eq 1');
	}

}
