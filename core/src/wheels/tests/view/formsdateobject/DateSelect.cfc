component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
		args = {};
		args.objectName = "user";
		args.label = false;
		set(functionName = "dateSelect", encode = false);
	}

	function teardown() {
		set(functionName = "dateSelect", encode = true);
	}

	function test_dateselect_parsing_and_passed_month() {
		args.property = "birthday";
		args.order = "month";
		debug("_controller.dateSelect(argumentcollection=args)", false);
		e = dateSelect_month_str(args.property);
		r = _controller.dateSelect(argumentcollection = args);
		assert("e eq r");
		args.property = "birthdaymonth";
		e = dateSelect_month_str(args.property);
		r = _controller.dateSelect(argumentcollection = args);
		assert("e eq r");
	}

	function test_dateselect_parsing_and_passed_year() {
		args.property = "birthday";
		args.order = "year";
		args.startyear = "1973";
		args.endyear = "1976";
		debug("_controller.dateSelect(argumentcollection=args)", false);
		e = dateSelect_year_str(args.property);
		r = _controller.dateSelect(argumentcollection = args);
		assert("e eq r");
	}

	function test_dateselect_year_is_less_than_startyear() {
		args.property = "birthday";
		args.order = "year";
		args.startyear = "1976";
		args.endyear = "1980";
		debug("_controller.dateSelect(argumentcollection=args)", false);
		e = '<select id="user-birthday-year" name="user[birthday]($year)"><option selected="selected" value="1975">1975</option><option value="1976">1976</option><option value="1977">1977</option><option value="1978">1978</option><option value="1979">1979</option><option value="1980">1980</option></select>';
		r = _controller.dateSelect(argumentcollection = args);
		assert("e eq r");
	}

	/**
	 * HELPERS
	 */

	function dateSelect_month_str(required string property) {
		return '<select id="user-#arguments.property#-month" name="user[#arguments.property#]($month)"><option value="1">January</option><option value="2">February</option><option value="3">March</option><option value="4">April</option><option value="5">May</option><option value="6">June</option><option value="7">July</option><option value="8">August</option><option value="9">September</option><option value="10">October</option><option selected="selected" value="11">November</option><option value="12">December</option></select>';
	}

	function dateSelect_year_str(required string property) {
		return '<select id="user-#arguments.property#-year" name="user[#arguments.property#]($year)"><option value="1973">1973</option><option value="1974">1974</option><option selected="selected" value="1975">1975</option><option value="1976">1976</option></select>';
	}

}
