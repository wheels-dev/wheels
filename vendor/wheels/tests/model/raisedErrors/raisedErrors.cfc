component extends="wheels.tests.Test" {

	function test_table_not_found() {
		e = raised("model('table_not_found')");
		debug("e", false);
		r = "Wheels.TableNotFound";
		assert("e eq r");
	}

	function test_no_primary_key() {
		e = raised("model('noPrimaryKey')");
		debug("e", false);
		r = "Wheels.NoPrimaryKey";
		assert("e eq r");
	}

	function test_bykey_methods_should_raise_error_with_key_argument() {
		post = model("post");
		e = raised('post.deleteByKey(key="1,2")');
		r = "Wheels.InvalidArgumentValue";
		assert("e eq r");
		e = raised('post.findByKey(key="1,2")');
		r = "Wheels.InvalidArgumentValue";
		assert("e eq r");
		e = raised('post.updateByKey(key="1,2", title="testing")');
		r = "Wheels.InvalidArgumentValue";
		assert("e eq r");
	}

	function test_value_cannot_be_determined_in_where_clause() {
		e = raised('model("user").count(where="username = tony")');
		r = "Wheels.QueryParamValue";
		assert("e eq r");
	}

	function test_invalid_select_column() {
		e = raised('model("user").findAll(select="id,email,firstname,lastname,createdat,foo")');
		r = "Wheels.ColumnNotFound";
		assert("e eq r");
	}

}
