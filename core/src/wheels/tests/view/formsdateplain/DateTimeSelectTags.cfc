component extends="wheels.tests.Test" {

	function setup() {
		pkg.controller = controller("dummy");
		result = "";
		results = {};
		_controller = controller(name = "dummy");
		args = {};
		args.label = false;
	}

	function testNoLabels() {
		result = pkg.controller.dateTimeSelectTags(name = "theName", label = false);
		assert("result Does Not Contain 'label'");
	}

	function testSameLabels() {
		str = pkg.controller.dateTimeSelectTags(name = "theName", label = "lblText");
		sub = "lblText";
		result = (Len(str) - Len(Replace(str, sub, "", "all"))) / Len(sub);
		assert("result IS 6");
	}

	function testSplittingLabels() {
		result = pkg.controller.dateTimeSelectTags(
			name = "theName",
			label = "labelMonth,labelDay,labelYear,labelHour,labelMinute,labelSecond"
		);
		assert("result Contains 'labelDay' AND result Contains 'labelSecond'");
	}

	function test_dateTimeSelectTags_blank_included_boolean() {
		args.name = "dateselector";
		args.includeBlank = "true";
		args.selected = "";
		args.startyear = "2000";
		args.endyear = "1990";
		r = _controller.dateTimeSelectTags(argumentcollection = args);
		e = '<option selected="selected" value=""></option>';
		assert("r contains e");
		args.selected = "01/02/2000";
		r = _controller.dateTimeSelectTags(argumentcollection = args);
		debug('r', false);
		e1 = '<option selected="selected" value="1">January</option>';
		e2 = '<option selected="selected" value="2">2</option>';
		e3 = '<option selected="selected" value="2000">2000</option>';
		assert("r contains e1 && r contains e2 && r contains e3");
	}

	function test_dateTimeSelectTags_blank_included_string() {
		args.name = "dateselector";
		args.includeBlank = "--Month--";
		args.selected = "";
		args.startyear = "2000";
		args.endyear = "1990";
		r = _controller.dateTimeSelectTags(argumentcollection = args);
		e = '<option selected="selected" value="">--Month--</option>';
		assert("r contains e");
		args.selected = "01/02/2000";
		r = _controller.dateTimeSelectTags(argumentcollection = args);
		debug('r', false);
		e1 = '<option selected="selected" value="1">January</option>';
		e2 = '<option selected="selected" value="2">2</option>';
		e3 = '<option selected="selected" value="2000">2000</option>';
		assert("r contains e1 && r contains e2 && r contains e3");
	}

	function test_dateTimeSelectTags_blank_not_included() {
		args.name = "dateselector";
		args.includeBlank = "false";
		args.selected = "";
		args.startyear = "2000";
		args.endyear = "1990";
		r = _controller.dateTimeSelectTags(argumentcollection = args);
		e = '<option selected="selected" value=""></option>';
		assert("r does not contain e");
		args.selected = "01/02/2000";
		r = _controller.dateTimeSelectTags(argumentcollection = args);
		debug('r', false);
		e1 = '<option selected="selected" value="1">January</option>';
		e2 = '<option selected="selected" value="2">2</option>';
		e3 = '<option selected="selected" value="2000">2000</option>';
		assert("r contains e1 && r contains e2 && r contains e3");
	}

	function test_dateTimeSelectTags_twelvehour() {
		date = CreateDateTime(2014, 8, 4, 12, 30, 35);
		args.name = "x";
		args.twelveHour = true;
		args.selected = date;
		r = _controller.dateTimeSelectTags(argumentcollection = args);
		e = '<option selected="selected" value="30">30</option>';
		assert("r Contains e");
	}

}
