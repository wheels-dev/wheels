component extends="wheels.tests.Test" {

	function test_existing_object() {
		args.type = "myCustomCallBack";
		model("tag").$registerCallback(type = args.type, methods = "methodOne");
		r = model("tag").$callbacks(argumentCollection = args);
		assert('IsArray(r)');
		assert('ArrayLen(r) eq 1');
	}

}
