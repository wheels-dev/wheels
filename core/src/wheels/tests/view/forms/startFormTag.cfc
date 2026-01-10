component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.host = "";
		args.method = "post";
		args.multipart = false;
		args.onlypath = true;
		args.port = 0;
		args.protocol = "";
		args.controller = "testcontroller";
		set(functionName = "startFormTag", encode = false);
		request.$wheelsProtectedFromForgery = true;
	}

	function teardown() {
		set(functionName = "startFormTag", encode = true);
		request.$wheelsProtectedFromForgery = false;
	}

	function test_no_csrf_when_not_enabled() {
		if (StructKeyExists(request, "$wheelsProtectedFromForgery")) {
			local.$wheelsProtectedFromForgery = request.$wheelsProtectedFromForgery;
			StructDelete(request, "$wheelsProtectedFromForgery");
		}
		StructDelete(args, "controller");
		argsction = _controller.urlfor(argumentCollection = args);
		e = '<form action="#argsction#" method="post">';
		r = _controller.startFormTag(argumentcollection = args);
		assert('e eq r');
		if (StructKeyExists(local, "$wheelsProtectedFromForgery")) {
			request.$wheelsProtectedFromForgery = local.$wheelsProtectedFromForgery;
		}
	}

	function test_no_controller_or_action_or_route_should_point_to_current_page() {
		StructDelete(args, "controller");
		argsction = _controller.urlfor(argumentCollection = args);
		e = '<form action="#argsction#" method="post">' & _controller.authenticityTokenField();
		r = _controller.startFormTag(argumentcollection = args);
		assert('e eq r');
	}

	function test_with_controller() {
		argsction = _controller.urlfor(argumentCollection = args);
		e = '<form action="#argsction#" method="post">' & _controller.authenticityTokenField();
		r = _controller.startFormTag(argumentcollection = args);
		assert("e eq r", "testing this out");
	}

	function test_with_get_method() {
		args.method = "get";
		argsction = _controller.urlfor(argumentCollection = args);
		e = '<form action="#argsction#" method="get">';
		r = _controller.startFormTag(argumentcollection = args);
		assert("e eq r");
	}

	// TODO: Change `method` back to `post` after integrating ColdRoute. Then also test for inclusion of `_method`
	// hidden field.
	function test_with_put_method() {
		args.method = "put";
		argsction = _controller.urlfor(argumentCollection = args);
		e = '<form action="#argsction#" method="put">' & _controller.authenticityTokenField();
		r = _controller.startFormTag(argumentcollection = args);
		assert("r is e");
	}

	// TODO: Change `method` back to `post` after integrating ColdRoute. Then also test for inclusion of `_method`
	// hidden field.
	function test_with_patch_method() {
		args.method = "patch";
		argsction = _controller.urlfor(argumentCollection = args);
		e = '<form action="#argsction#" method="patch">' & _controller.authenticityTokenField();
		r = _controller.startFormTag(argumentcollection = args);
		assert("r is e");
	}

	// TODO: Change `method` back to `post` after integrating ColdRoute. Then also test for inclusion of `_method`
	// hidden field.
	function test_with_delete_method() {
		args.method = "delete";
		argsction = _controller.urlfor(argumentCollection = args);
		e = '<form action="#argsction#" method="delete">' & _controller.authenticityTokenField();
		r = _controller.startFormTag(argumentcollection = args);
		assert("r is e");
	}

	function test_with_multipart() {
		args.multipart = "true";
		argsction = _controller.urlfor(argumentCollection = args);
		e = _controller.startFormTag(argumentcollection = args);
		r = '<form action="#argsction#" enctype="multipart/form-data" method="post">' & _controller.authenticityTokenField();
		assert("e eq r");
	}

	function test_with_root_route() {
		args.route = "root";
		argsction = _controller.urlfor(argumentCollection = args);
		e = '<form action="#argsction#" method="post">' & _controller.authenticityTokenField();
		r = _controller.startFormTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_external_link() {
		args.multipart = true;
		argsction = _controller.urlfor(argumentCollection = args);
		e = '<form action="#argsction#" enctype="multipart/form-data" method="post">' & _controller.authenticityTokenField();
		r = _controller.startFormTag(argumentcollection = args);
		assert("e eq r");
	}

	function test_with_controller_and_action() {
		argsction = _controller.urlfor(argumentCollection = args, action = "test");
		e = '<form action="#argsction#" method="post">' & _controller.authenticityTokenField();
		r = _controller.startFormTag(argumentcollection = args, action = "test");
		assert("e eq r");
	}

}
