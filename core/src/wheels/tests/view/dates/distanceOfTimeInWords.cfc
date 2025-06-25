component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		f = "distanceOfTimeInWords";
		args = {};
		args.fromTime = Now();
		args.includeSeconds = true;
	}

	function test_with_seconds_below_5_seconds() {
		c = 5 - 1;
		args.toTime = DateAdd('s', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "less than 5 seconds";
		assert("actual eq expected");
	}

	function test_with_seconds_below_10_seconds() {
		c = 10 - 1;
		args.toTime = DateAdd('s', c, args.fromTime);
		debug("_controller.distanceOfTimeInWords(argumentcollection=args)", false);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "less than 10 seconds";
		assert("actual eq expected");
	}

	function test_with_seconds_below_20_seconds() {
		c = 20 - 1;
		args.toTime = DateAdd('s', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "less than 20 seconds";
		assert("actual eq expected");
	}

	function test_with_seconds_below_40_seconds() {
		c = 40 - 1;
		args.toTime = DateAdd('s', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "half a minute";
		assert("actual eq expected");
	}

	function test_with_seconds_below_60_seconds() {
		c = 60 - 1;
		args.toTime = DateAdd('s', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "less than a minute";
		assert("actual eq expected");
	}

	function test_with_seconds_above_60_seconds() {
		c = 60 + 50;
		args.toTime = DateAdd('s', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "1 minute";
		assert("actual eq expected");
	}

	function test_without_seconds_below_60_seconds() {
		args.includeSeconds = false;
		c = 60 - 1;
		args.toTime = DateAdd('s', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "less than a minute";
		assert("actual eq expected");
	}

	function test_without_seconds_above_60_seconds() {
		args.includeSeconds = false;
		c = 60 + 50;
		args.toTime = DateAdd('s', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "1 minute";
		assert("actual eq expected");
	}

	function test_without_seconds_below_45_minutes() {
		args.includeSeconds = false;
		c = 45 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "#c# minutes";
		assert("actual eq expected");
	}

	function test_without_seconds_below_90_minutes() {
		args.includeSeconds = false;
		c = 90 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "about 1 hour";
		assert("actual eq expected");
	}

	function test_without_seconds_below_1440_minutes() {
		args.includeSeconds = false;
		c = 1440 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		c = Ceiling(c / 60);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "about #c# hours";
		assert("actual eq expected");
	}

	function test_without_seconds_below_2880_minutes() {
		args.includeSeconds = false;
		c = 2880 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "1 day";
		assert("actual eq expected");
	}

	function test_without_seconds_below_43200_minutes() {
		args.includeSeconds = false;
		c = 43200 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		c = Int(c / 1440);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "#c# days";
		assert("actual eq expected");
	}

	function test_without_seconds_below_86400_minutes() {
		args.includeSeconds = false;
		c = 86400 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "about 1 month";
		assert("actual eq expected");
	}

	function test_without_seconds_below_525600_minutes() {
		args.includeSeconds = false;
		c = 525600 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		c = Int(c / 43200);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "#c# months";
		assert("actual eq expected");
	}

	function test_without_seconds_below_657000_minutes() {
		args.includeSeconds = false;
		c = 657000 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "about 1 year";
		assert("actual eq expected");
	}

	function test_without_seconds_below_919800_minutes() {
		args.includeSeconds = false;
		c = 919800 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "over 1 year";
		assert("actual eq expected");
	}

	function test_without_seconds_below_1051200_minutes() {
		args.includeSeconds = false;
		c = 1051200 - 1;
		args.toTime = DateAdd('n', c, args.fromTime);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "almost 2 years";
		assert("actual eq expected");
	}

	function test_without_seconds_above_1051200_minutes() {
		args.includeSeconds = false;
		c = 1051200;
		c = (c * 3) + 786;
		args.toTime = DateAdd('n', c, args.fromTime);
		c = Int(c / 525600);
		actual = _controller.distanceOfTimeInWords(argumentCollection = args);
		expected = "over #c# years";
		assert("actual eq expected");
	}

}
