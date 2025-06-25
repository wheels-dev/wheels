component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.source = "/wheels/tests/_assets/files/cfwheels-logo.png";
		args.alt = "wheelstestlogo";
		args.class = "wheelstestlogoclass";
		args.id = "wheelstestlogoid";
		imagePath = application.wheels.webPath & application.wheels.imagePath;
		set(functionName = "imageTag", encode = false);
	}

	function teardown() {
		set(functionName = "imageTag", encode = true);
	}

	function test_just_source() {
		StructDelete(args, "alt");
		StructDelete(args, "class");
		StructDelete(args, "id");
		r = '<img alt="Cfwheels logo" height="121" src="#imagePath#/#args.source#" width="93">';
		e = _controller.imageTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_supplying_an_alt() {
		StructDelete(args, "class");
		StructDelete(args, "id");
		r = '<img alt="#args.alt#" height="121" src="#imagePath#/#args.source#" width="93">';
		e = _controller.imageTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_supplying_an_id_when_caching_is_on() {
		cacheImages = application.wheels.cacheImages;
		application.wheels.cacheImages = true;
		StructDelete(args, "alt");
		StructDelete(args, "class");
		r = '<img alt="Cfwheels logo" height="121" src="#imagePath#/#args.source#" id="#args.id#" width="93">';
		e = _controller.imageTag(argumentCollection = args);
		assert("e eq r");
		application.wheels.cacheImages = cacheImages;
	}

	function test_supplying_class_and_id() {
		r = '<img alt="#args.alt#" class="#args.class#" height="121" src="#imagePath#/#args.source#" id="#args.id#" width="93">';
		e = _controller.imageTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_grabbing_from_http() {
		StructDelete(args, "alt");
		StructDelete(args, "class");
		StructDelete(args, "id");
		args.source = "http://www.cfwheels.org/images/cfwheels-logo.png";
		r = '<img alt="Cfwheels logo" src="#args.source#">';
		e = _controller.imageTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_grabbing_from_https() {
		StructDelete(args, "alt");
		StructDelete(args, "class");
		StructDelete(args, "id");
		args.source = "https://www.cfwheels.org/images/cfwheels-logo.png";
		r = '<img alt="Cfwheels logo" src="#args.source#">';
		e = _controller.imageTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_specifying_height_and_width() {
		StructDelete(args, "alt");
		StructDelete(args, "class");
		StructDelete(args, "id");
		args.height = 25;
		args.width = 25;
		r = '<img alt="Cfwheels logo" height="25" src="#imagePath#/#args.source#" width="25">';
		e = _controller.imageTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_height_only() {
		StructDelete(args, "alt");
		StructDelete(args, "class");
		StructDelete(args, "id");
		args.height = 25;
		r = '<img alt="Cfwheels logo" height="25" src="#imagePath#/#args.source#" width="93">';
		e = _controller.imageTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_width_only() {
		StructDelete(args, "alt");
		StructDelete(args, "class");
		StructDelete(args, "id");
		args.width = 25;
		r = '<img alt="Cfwheels logo" height="121" src="#imagePath#/#args.source#" width="25">';
		e = _controller.imageTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_remove_height_width_attributes_when_set_to_false() {
		StructDelete(args, "alt");
		StructDelete(args, "class");
		StructDelete(args, "id");
		args.height = false;
		args.width = false;
		r = '<img alt="Cfwheels logo" src="#imagePath#/#args.source#">';
		e = _controller.imageTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_raises_exception_on_missing_image() {
		path = "missing.jpg";
		actual = raised("_controller.imageTag(source=path)");
		expected = "Wheels.ImageFileNotFound";
		assert("actual eq expected");
	}

	function test_raises_exception_on_unsupported_image() {
		path = "/wheels/tests/_assets/files/cfwheels-logo.txt";
		actual = raised("_controller.imageTag(source=path)");
		expected = "Wheels.ImageFormatNotSupported";
		assert("actual eq expected");
	}

	function test_accepts_missing_image() {
		path = "missing.jpg";
		actual = _controller.imageTag(source = path, required = false, alt = "This may be broken");
		expected = '<img alt="This may be broken" src="#imagePath#/#path#">';
		assert("actual eq expected");
	}

}
