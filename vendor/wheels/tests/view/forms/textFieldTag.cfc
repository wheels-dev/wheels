component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_x_textFieldTag_valid() {
		_controller.textFieldTag(name = "someName");
	}

	function test_custom_textfieldTag_type() {
		textField = _controller.textFieldTag(name = "search", label = "Search me", type = "search");
		foundCustomType = YesNoFormat(FindNoCase('type="search"', textField));
		assert('foundCustomType eq true');
	}

	function test_data_attribute_underscore_conversion() {
		result = _controller.textFieldTag(
			name = "num",
			type = "range",
			min = 5,
			max = 10,
			data_dom_cache = "cache",
			data_role = "button"
		);
		correct = '<input data-dom-cache="cache" data-role="button" id="num" max="10" min="5" name="num" type="range" value="">';
		assert('result IS correct');
	}

	function test_data_attribute_camelcase_conversion_when_not_in_quotes() {
		result = _controller.textFieldTag(
			name = "num",
			type = "range",
			min = 5,
			max = 10,
			dataDomCache = "cache",
			dataRole = "button"
		);
		correct = '<input data-dom-cache="cache" data-role="button" id="num" max="10" min="5" name="num" type="range" value="">';
		assert('result IS correct');
	}

	function test_data_attribute_camelcase_conversion() {
		args = {};
		args["dataDomCache"] = "cache";
		args["dataRole"] = "button";
		result = _controller.textFieldTag(
			name = "num",
			type = "range",
			min = 5,
			max = 10,
			argumentCollection = args
		);
		correct = '<input data-dom-cache="cache" data-role="button" id="num" max="10" min="5" name="num" type="range" value="">';
		assert('result IS correct');
	}

	function test_data_attribute_set_to_true() {
		args = {};
		args["data-dom-cache"] = "true";
		result = _controller.textFieldTag(name = "num", argumentCollection = args);
		correct = '<input data-dom-cache="true" id="num" name="num" type="text" value="">';
		assert('result IS correct');
	}

}
