component extends="wheels.tests.Test" {

	function setup() {
		_controller = application.wirebox.getInstance("wheels.tests._assets.controllers.ControllerWithModel");
		args = {};
		args.objectName = "user";
		args.property = "birthday";
		args.includeblank = false;
		args.order = "year";
		args.label = false;
		_controller.changeBirthday = changeBirthday;
		set(functionName = "dateSelect", encode = false);
	}

	function teardown() {
		set(functionName = "dateSelect", encode = true);
	}

	function test_startyear_lt_endyear_value_lt_startyear() {
		args.startyear = "1980";
		args.endyear = "1990";
		r = _controller.dateSelect(argumentCollection = args);
		debug('r', false);
		e = '<select id="user-birthday-year" name="user[birthday]($year)"><option selected="selected" value="1975">1975</option><option value="1976">1976</option><option value="1977">1977</option><option value="1978">1978</option><option value="1979">1979</option><option value="1980">1980</option><option value="1981">1981</option><option value="1982">1982</option><option value="1983">1983</option><option value="1984">1984</option><option value="1985">1985</option><option value="1986">1986</option><option value="1987">1987</option><option value="1988">1988</option><option value="1989">1989</option><option value="1990">1990</option></select>';
		assert('e eq r');
	}

	function test_startyear_lt_endyear_value_gt_startyear() {
		_controller.changeBirthday(CreateDate(1995, 11, 1));
		args.startyear = "1980";
		args.endyear = "1990";
		r = _controller.dateSelect(argumentCollection = args);
		debug('r', false);
		e = '<select id="user-birthday-year" name="user[birthday]($year)"><option value="1980">1980</option><option value="1981">1981</option><option value="1982">1982</option><option value="1983">1983</option><option value="1984">1984</option><option value="1985">1985</option><option value="1986">1986</option><option value="1987">1987</option><option value="1988">1988</option><option value="1989">1989</option><option value="1990">1990</option></select>';
		assert('e eq r');
	}

	function test_startyear_gt_endyear_value_lt_endyear() {
		args.startyear = "1990";
		args.endyear = "1980";
		r = _controller.dateSelect(argumentCollection = args);
		debug('r', false);
		e = '<select id="user-birthday-year" name="user[birthday]($year)"><option value="1990">1990</option><option value="1989">1989</option><option value="1988">1988</option><option value="1987">1987</option><option value="1986">1986</option><option value="1985">1985</option><option value="1984">1984</option><option value="1983">1983</option><option value="1982">1982</option><option value="1981">1981</option><option value="1980">1980</option><option value="1979">1979</option><option value="1978">1978</option><option value="1977">1977</option><option value="1976">1976</option><option selected="selected" value="1975">1975</option></select>';
		assert('e eq r');
	}

	function test_startyear_gt_endyear_value_gt_endyear() {
		_controller.changeBirthday(CreateDate(1995, 11, 1));
		args.startyear = "1990";
		args.endyear = "1980";
		r = _controller.dateSelect(argumentCollection = args);
		debug('r', false);
		e = '<select id="user-birthday-year" name="user[birthday]($year)"><option value="1990">1990</option><option value="1989">1989</option><option value="1988">1988</option><option value="1987">1987</option><option value="1986">1986</option><option value="1985">1985</option><option value="1984">1984</option><option value="1983">1983</option><option value="1982">1982</option><option value="1981">1981</option><option value="1980">1980</option></select>';
		assert('e eq r');
	}

	/**
	 * HELPERS
	 */

	function changeBirthday(required any value) {
		user.birthday = arguments.value;
	}

}
