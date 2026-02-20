component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
		user = model("user");
		set(functionName = "select", encode = false);
	}

	function teardown() {
		set(functionName = "select", encode = true);
	}

	function test_with_list_as_options() {
		options = "Opt1,Opt2";
		r = _controller.select(
			objectName = "user",
			property = "firstname",
			options = options,
			label = false
		);
		e = '<select id="user-firstname" name="user[firstname]"><option value="Opt1">Opt1</option><option value="Opt2">Opt2</option></select>';
		assert('e eq r');
	}

	function test_with_array_as_options() {
		options = ArrayNew(1);
		options[1] = "Opt1";
		options[2] = "Opt2";
		options[3] = "Opt3";
		r = _controller.select(
			objectName = "user",
			property = "firstname",
			options = options,
			label = false
		);
		e = '<select id="user-firstname" name="user[firstname]"><option value="Opt1">Opt1</option><option value="Opt2">Opt2</option><option value="Opt3">Opt3</option></select>';
		assert('e eq r');
	}

	function test_with_struct_as_options() {
		options = {};
		options.x = "xVal";
		options.y = "yVal";
		r = _controller.select(
			objectName = "user",
			property = "firstname",
			options = options,
			label = false
		);
		e = '<select id="user-firstname" name="user[firstname]"><option value="x">xVal</option><option value="y">yVal</option></select>';
		assert('e eq r');
	}

	function test_setting_text_field() {
		users = user.findAll(returnAs = "objects", order = "id");
		r = _controller.select(
			objectName = "user",
			property = "firstname",
			options = users,
			valueField = "id",
			textField = "firstName",
			label = false
		);
		e = '<select id="user-firstname" name="user[firstname]"><option value="#users[1].id#">Tony</option><option value="#users[2].id#">Chris</option><option value="#users[3].id#">Per</option><option value="#users[4].id#">Raul</option><option value="#users[5].id#">Joe</option></select>';
		assert('e eq r');
	}

	function test_first_non_numeric_property_default_text_field_on_query() {
		users = user.findAll(returnAs = "query", order = "id");
		r = _controller.select(
			objectName = "user",
			property = "firstname",
			options = users,
			label = false
		);
		e = '<select id="user-firstname" name="user[firstname]"><option value="#users["id"][1]#">tonyp</option><option value="#users["id"][2]#">chrisp</option><option value="#users["id"][3]#">perd</option><option value="#users["id"][4]#">raulr</option><option value="#users["id"][5]#">joeb</option></select>';
		assert('e eq r');
	}

	function test_first_non_numeric_property_default_text_field_on_objects() {
		users = user.findAll(returnAs = "objects", order = "id");
		r = _controller.select(
			objectName = "user",
			property = "firstname",
			options = users,
			label = false
		);
		e = '<select id="user-firstname" name="user[firstname]"><option value="#users[1].id#">tonyp</option><option value="#users[2].id#">chrisp</option><option value="#users[3].id#">perd</option><option value="#users[4].id#">raulr</option><option value="#users[5].id#">joeb</option></select>';
		assert('e eq r');
	}

	function test_with_array_of_structs_as_options() {
		options = [];
		options[1] = {};
		options[1].tp = "tony petruzzi";
		options[2] = {};
		options[2].pd = "per djurner";
		r = _controller.select(
			objectName = "user",
			property = "firstname",
			options = options,
			label = false
		);
		e = '<select id="user-firstname" name="user[firstname]"><option value="tp">tony petruzzi</option><option value="pd">per djurner</option></select>';
		assert('e eq r');
	}

	function test_with_array_of_structs_as_options_2() {
		options = [];
		options[1] = {};
		options[1] = {value = "petruzzi", name = "tony"};
		options[2] = {};
		options[2] = {value = "djurner", name = "per"};
		r = _controller.select(
			objectName = "user",
			property = "firstname",
			options = options,
			valueField = "value",
			textField = "name",
			label = false
		);
		e = '<select id="user-firstname" name="user[firstname]"><option value="petruzzi">tony</option><option value="djurner">per</option></select>';
		assert('e eq r');
	}

	function test_htmlsafe() {
		badValue = "<invalidTag;alert('hello');</script>";
		badName = "<invalidTag;alert('tony');</script>";
		goodValue = EncodeForHTMLAttribute(badValue);
		goodName = EncodeForHTML(badName);
		options = [];
		options[1] = {value = "#badValue#", name = "#badName#"};
		set(functionName = "select", encode = true);
		r = _controller.select(
			objectName = "user",
			property = "firstname",
			options = options,
			valueField = "value",
			textField = "name",
			label = false
		);
		assert('r CONTAINS goodValue AND r CONTAINS goodName');
	}

}
