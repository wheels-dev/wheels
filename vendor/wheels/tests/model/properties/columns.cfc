component extends="wheels.tests.Test" {

	function test_columns_returns_array() {
		columns = model("author").columns();
		assert('IsArray(columns) eq true');
	}

}
