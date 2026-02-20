component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		set(functionName = "javaScriptIncludeTag", encode = false);
	}

	function teardown() {
		set(functionName = "javaScriptIncludeTag", encode = true);
	}

	function test_should_handle_extensions_nonextensions_and_multiple_extensions() {
		args.source = "test,test.js,jquery.dataTables.min,jquery.dataTables.min.js";
		e = _controller.javaScriptIncludeTag(argumentcollection = args);
		r = '<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/jquery.dataTables.min.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/jquery.dataTables.min.js" type="text/javascript"></script>#Chr(10)#';
		debug(expression = 'htmleditformat(e)', display = false, format = "text");
		debug(expression = 'htmleditformat(r)', display = false, format = "text");
		assert("e eq r");
	}

	function test_no_automatic_extention_when_cfm() {
		args.source = "test.cfm,test.js.cfm";
		e = _controller.javaScriptIncludeTag(argumentcollection = args);
		r = '<script src="#application.wheels.webpath#javascripts/test.cfm" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/test.js.cfm" type="text/javascript"></script>#Chr(10)#';
		debug(expression = 'htmleditformat(e)', display = false, format = "text");
		debug(expression = 'htmleditformat(r)', display = false, format = "text");
		assert("e eq r");
	}

	function test_support_external_links() {
		args.source = "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js,test,https://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js";
		e = _controller.javaScriptIncludeTag(argumentcollection = args);
		r = '<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript"></script>#Chr(10)#';
		debug(expression = 'htmleditformat(e)', display = false, format = "text");
		debug(expression = 'htmleditformat(r)', display = false, format = "text");
		assert("e eq r");
	}

	function test_allow_specification_of_delimiter() {
		args.source = "test|test.js|http://fonts.googleapis.com/css?family=Istok+Web:400,700";
		args.delim = "|";
		e = _controller.javaScriptIncludeTag(argumentcollection = args);
		r = '<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="http://fonts.googleapis.com/css?family=Istok+Web:400,700" type="text/javascript"></script>#Chr(10)#';
		debug(expression = 'htmleditformat(e)', display = false, format = "text");
		debug(expression = 'htmleditformat(r)', display = false, format = "text");
		assert("e eq r");
	}

	function test_removing_type_argument() {
		args.source = "test.js";
		args.type = "";
		e = _controller.javaScriptIncludeTag(argumentcollection = args);
		r = '<script src="#application.wheels.webpath#javascripts/test.js"></script>#Chr(10)#';
		assert("e eq r");
	}

}
