component extends="wheels.tests.Test" {

	/* function test_contains_multiple_spaces_tabs_and_carriage_returns() {
		r = model("post").findAll(where="views

					 ;=
					   5   		   AND
		  averagerating
		   >
		   				3")>
		assert('r.recordcount eq 1');
	} */

	function test_should_not_strip_extra_whitespace_from_values() {
		r = model("user").findAll(where = "address = '123     Petruzzi St.'");
		assert('r.recordcount eq 0');
		r = model("user").findAll(where = "address = '123 Petruzzi St.'");
		assert('r.recordcount eq 2');
	}

	function test_in_statement_should_not_error() {
		r = model("user").findAll(
			where = "username IN('tonyp','perd','chrisp') AND (firstname = 'Tony' OR firstname = 'Per' OR firstname = 'Chris') OR id IN(1,2,3)"
		);
		assert('r.recordcount eq 3');
	}

	function test_in_statement_respect_parenthesis_commas_and_single_quotes() {
		r = model("user").findAll(where = "username IN('tony''s','pe''(yo,yo)rd','chrisp')");
		assert('r.recordcount eq 1');
	}

	function test_numeric_value_for_string_property() {
		expected = "title='1'";
		actual = model("Post").$keyWhereString(properties = "title", values = "1");
		assert('actual EQ expected');
	}

}
