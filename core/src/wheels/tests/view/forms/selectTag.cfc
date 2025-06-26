component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		options.simplevalues = '<select id="testselect" name="testselect"><option value="first">first</option><option value="second">second</option><option value="third">third</option></select>';
		options.complexvalues = '<select id="testselect" name="testselect"><option value="1">first</option><option value="2">second</option><option value="3">third</option></select>';
		options.single_key_struct = '<select id="testselect" name="testselect"><option value="firstKeyName">first Value</option><option value="secondKeyName">second Value</option></select>';
		options.single_column_query = '<select id="testselect" name="testselect"><option value="first">first</option><option value="second">second</option><option value="third">third</option></select>';
		options.empty_query = '<select id="testselect" name="testselect"></select>';
	}

	function test_encode_for_html_and_encode_for_html_attribute() {
		result = controller("dummy").selectTag(name = "x", options = "<t e s t>,<2>,3", selected = "<2>");
		expected = '<select id="x" name="x"><option value="&lt;t&##x20;e&##x20;s&##x20;t&gt;">&lt;t e s t&gt;</option><option selected="selected" value="&lt;2&gt;">&lt;2&gt;</option><option value="3">3</option></select>';
		assert("result eq expected");
	}

	function test_list_for_option_values() {
		args.name = "testselect";
		args.options = "first,second,third";
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.simplevalues eq r');
	}

	function test_struct_for_option_values() {
		args.name = "testselect";
		args.options = {1 = "first", 2 = "second", 3 = "third"};
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.complexvalues eq r');
	}

	function test_array_of_structs_for_option_values_single_key() {
		args.name = "testselect";
		args.options = [];
		temp = {firstKeyName = "first Value"};
		ArrayAppend(args.options, temp);
		temp = {secondKeyName = "second Value"};
		ArrayAppend(args.options, temp);
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.single_key_struct eq r');
	}

	function test_one_dimensional_array_for_option_values() {
		args.name = "testselect";
		args.options = ["first", "second", "third"];
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.simplevalues eq r');
	}

	function test_two_dimensional_array_for_option_values() {
		args.name = "testselect";
		first = [1, "first"];
		second = [2, "second"];
		third = [3, "third"];
		args.options = [first, second, third];
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.complexvalues eq r');
	}

	function test_three_dimensional_array_for_option_values() {
		args.name = "testselect";
		first = [1, "first", "a"];
		second = [2, "second", "b"];
		third = [3, "third", "c"];
		args.options = [first, second, third];
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.complexvalues eq r');
	}

	function test_query_for_option_values() {
		q = QueryNew("");
		id = [1, 2, 3];
		name = ["first", "second", "third"];
		QueryAddColumn(q, "id", id);
		QueryAddColumn(q, "name", name);
		args.name = "testselect";
		args.options = q;
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.complexvalues eq r');
	}

	function test_one_column_query_for_options() {
		q = QueryNew("");
		id = ["first", "second", "third"];
		QueryAddColumn(q, "id", id);
		args.name = "testselect";
		args.options = q;
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.single_column_query eq r');
	}

	function test_query_with_no_records_for_option_values_() {
		q = QueryNew("");
		id = [];
		name = [];
		QueryAddColumn(q, "id", id);
		QueryAddColumn(q, "name", name);
		args.name = "testselect";
		args.options = q;
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.empty_query eq r');
	}

	function test_query_with_no_records_or_columns_for_option_values_() {
		q = QueryNew("");
		args.name = "testselect";
		args.options = q;
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.empty_query eq r');
	}

	function test_array_of_structs_for_option_values() {
		args.name = "testselect";
		args.options = [];
		temp = {value = "1", text = "first"};
		ArrayAppend(args.options, temp);
		temp = {value = "2", text = "second"};
		ArrayAppend(args.options, temp);
		temp = {value = "3", text = "third"};
		ArrayAppend(args.options, temp);
		debug("_controller.selectTag(argumentcollection=args)", false);
		r = _controller.selectTag(argumentcollection = args);
		assert('options.complexvalues eq r');
	}

}
