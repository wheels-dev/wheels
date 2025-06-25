component extends="wheels.tests.Test" {

	function test_columnForProperty_returns_column_name() {
		_model = model("author").new();
		assert('_model.columnForProperty("firstName") eq "firstname"');
	}

	function test_columnForProperty_returns_false() {
		_model = model("author").new();
		assert('_model.columnForProperty("myFavy") eq false');
	}

	function test_columnForProperty_dynamic_method_call() {
		_model = model("author").new();
		assert('_model.columnForFirstName() eq "firstname"');
	}

}
