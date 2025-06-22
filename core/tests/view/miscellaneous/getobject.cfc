component extends="wheels.tests.Test" {

	function setup(){
		_controller = application.wirebox.getInstance( "wheels.Controller" );
	}

	function test_getting_object_from_request_scope() {
		request.obj = model("post").findOne();
		result = _controller.$getObject( objectname = "request.obj", variableScope = variables );
		assert("IsObject(result)");
	}

	function test_getting_object_from_default_scope() {
		obj = model("post").findOne();
		result = _controller.$getObject( objectname = "obj", variableScope = variables );
		assert("IsObject(result)");
	}

	function test_getting_object_from_variables_scope() {
		variables.obj = model("post").findOne();
		result = _controller.$getObject( objectname = "variables.obj", variableScope = variables );
		assert("IsObject(result)");
	}

}
