component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		set(functionName = "hourSelectTag", encode = false);
	}

	function teardown() {
		set(functionName = "hourSelectTag", encode = true);
	}

	function test_hourSelect_twelve_hour_format() {
		args.name = "dateselector";
		args.twelveHour = "true";
		args.selected = "11";
		r = _controller.hourSelectTag(argumentcollection = args);
		e = '<select id="dateselector-hour" name="dateselector($hour)"><option value="1">1</option><option value="2">2</option><option value="3">3</option><option value="4">4</option><option value="5">5</option><option value="6">6</option><option value="7">7</option><option value="8">8</option><option value="9">9</option><option value="10">10</option><option selected="selected" value="11">11</option><option value="12">12</option></select>:<select id="dateselector-ampm" name="dateselector($ampm)"><option selected="selected" value="AM">AM</option><option value="PM">PM</option></select>';
		assert('e eq r');
		args.selected = "23";
		r = _controller.hourSelectTag(argumentcollection = args);
		e = '<select id="dateselector-hour" name="dateselector($hour)"><option value="1">1</option><option value="2">2</option><option value="3">3</option><option value="4">4</option><option value="5">5</option><option value="6">6</option><option value="7">7</option><option value="8">8</option><option value="9">9</option><option value="10">10</option><option selected="selected" value="11">11</option><option value="12">12</option></select>:<select id="dateselector-ampm" name="dateselector($ampm)"><option value="AM">AM</option><option selected="selected" value="PM">PM</option></select>';
		assert('e eq r');
	}

}
