component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		webPath = Replace(
			application.wheels.webpath,
			"/",
			"&##x2f;",
			"all"
		);
	}

	function test_should_handle_extensions_nonextensions_and_multiple_extensions() {
		args.source = "test,test.css,jquery.dataTables.min,jquery.dataTables.min.css";
		result = _controller.styleSheetLinkTag(argumentcollection = args);
		expected = '<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;jquery.dataTables.min.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;jquery.dataTables.min.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#';
		assert("result eq expected");
	}

	function test_no_automatic_extention_when_cfm() {
		args.source = "test.cfm,test.css.cfm";
		result = _controller.styleSheetLinkTag(argumentcollection = args);
		expected = '<link href="#webPath#stylesheets&##x2f;test.cfm" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;test.css.cfm" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#';
		assert("result eq expected");
	}

	function test_support_external_links() {
		args.source = "http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/themes/start/jquery-ui.css,test.css,https://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/themes/start/jquery-ui.css";
		result = _controller.styleSheetLinkTag(argumentcollection = args);
		expected = '<link href="http&##x3a;&##x2f;&##x2f;ajax.googleapis.com&##x2f;ajax&##x2f;libs&##x2f;jqueryui&##x2f;1.7.2&##x2f;themes&##x2f;start&##x2f;jquery-ui.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="https&##x3a;&##x2f;&##x2f;ajax.googleapis.com&##x2f;ajax&##x2f;libs&##x2f;jqueryui&##x2f;1.7.2&##x2f;themes&##x2f;start&##x2f;jquery-ui.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#';
		assert("result eq expected");
	}

	function test_allow_specification_of_delimiter() {
		args.source = "test|test.css|http://fonts.googleapis.com/css?family=Istok+Web:400,700";
		args.delim = "|";
		result = _controller.styleSheetLinkTag(argumentcollection = args);
		expected = '<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="http&##x3a;&##x2f;&##x2f;fonts.googleapis.com&##x2f;css&##x3f;family&##x3d;Istok&##x2b;Web&##x3a;400,700" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#';
		assert("result eq expected");
	}

	function test_type_media_arguments() {
		args.source = "test.css";
		args.media = "";
		args.type = "";
		result = _controller.styleSheetLinkTag(argumentcollection = args);
		expected = '<link href="#webPath#stylesheets&##x2f;test.css" rel="stylesheet">#Chr(10)#';
		assert("result eq expected");
	}

	function test_no_encoding() {
		args.source = "<test>.css";
		local.encodeHtmlAttributes = application.wheels.encodeHtmlAttributes;
		application.wheels.encodeHtmlAttributes = false;
		result = _controller.styleSheetLinkTag(argumentcollection = args);
		application.wheels.encodeHtmlAttributes = local.encodeHtmlAttributes;
		expected = '<link href="#application.wheels.webPath#stylesheets/<test>.css" media="all" rel="stylesheet" type="text/css">#Chr(10)#';
		assert("result eq expected");
	}

}
