component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		now = Now();
		args = {};
		args.includeSeconds = true;
		args.fromTime = now;
	}

	function test_with_seconds_below_5_seconds() {
		c = 5 - 1;
		args.toTime = DateAdd('s', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "less than 5 seconds";
		assert("e eq r");
	}

	function test_with_seconds_below_10_seconds() {
		c = 10 - 1;
		args.toTime = DateAdd('s', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "less than 10 seconds";
		assert("e eq r");
	}

	function test_with_seconds_below_20_seconds() {
		c = 20 - 1;
		args.toTime = DateAdd('s', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "less than 20 seconds";
		assert("e eq r");
	}

	function test_with_seconds_below_40_seconds() {
		c = 40 - 1;
		args.toTime = DateAdd('s', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "half a minute";
		assert("e eq r");
	}

	function test_with_seconds_below_60_seconds() {
		c = 60 - 1;
		args.toTime = DateAdd('s', c, now);
		debug('args', false);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "less than a minute";
		assert("e eq r");
	}

	function test_with_seconds_above_60_seconds() {
		c = 60 + 50;
		args.toTime = DateAdd('s', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "1 minute";
		assert("e eq r");
	}

	function test_without_seconds_above_60_seconds() {
		args.includeSeconds = false;
		c = 60 + 50;
		args.toTime = DateAdd('s', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "1 minute";
		assert("e eq r");
	}

	function test_without_seconds_below_45_minutes() {
		args.includeSeconds = false;
		c = 45 - 1;
		args.toTime = DateAdd('n', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "#c# minutes";
		assert("e eq r");
	}

	function test_without_seconds_below_90_minutes() {
		args.includeSeconds = false;
		c = 90 - 1;
		args.toTime = DateAdd('n', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "about 1 hour";
		assert("e eq r");
	}

	function test_without_seconds_below_1440_minutes() {
		args.includeSeconds = false;
		c = 1440 - 1;
		args.toTime = DateAdd('n', c, now);
		c = Ceiling(c / 60);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "about #c# hours";
		assert("e eq r");
	}

	function test_without_seconds_below_2880_minutes() {
		args.includeSeconds = false;
		c = 2880 - 1;
		args.toTime = DateAdd('n', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "1 day";
		assert("e eq r");
	}

	function test_without_seconds_below_43200_minutes() {
		args.includeSeconds = false;
		c = 43200 - 1;
		args.toTime = DateAdd('n', c, now);
		c = Int(c / 1440);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "#c# days";
		assert("e eq r");
	}

	function test_without_seconds_below_86400_minutes() {
		args.includeSeconds = false;
		c = 86400 - 1;
		args.toTime = DateAdd('n', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "about 1 month";
		assert("e eq r");
	}

	function test_without_seconds_below_525600_minutes() {
		args.includeSeconds = false;
		c = 525600 - 1;
		args.toTime = DateAdd('n', c, now);
		c = Int(c / 43200);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "#c# months";
		assert("e eq r");
	}

	function test_without_seconds_below_1051200_minutes() {
		args.includeSeconds = false;
		c = 1051200 - 1;
		args.toTime = DateAdd('n', c, now);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "almost 2 years";
		assert("e eq r");
	}

	function test_without_seconds_above_1051200_minutes() {
		args.includeSeconds = false;
		c = 1051200;
		c = (c * 3) + 786;
		args.toTime = DateAdd('n', c, now);
		c = Int(c / 525600);
		e = _controller.timeUntilInWords(argumentCollection = args);
		r = "over #c# years";
		assert("e eq r");
	}

}
