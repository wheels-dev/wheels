component extends="wheels.tests.Test" {

	function test_boolean_handled_properly() {
		sqltype = model("Sqltype").findOne();
		sqltype.booleanType = "false";
		assert('!sqltype.hasChanged("booleanType")');
		sqltype.booleanType = "no";
		assert('!sqltype.hasChanged("booleanType")');
		sqltype.booleanType = 0;
		assert('!sqltype.hasChanged("booleanType")');
		sqltype.booleanType = "0";
		assert('!sqltype.hasChanged("booleanType")');
		sqltype.booleanType = "true";
		assert('sqltype.hasChanged("booleanType")');
		sqltype.booleanType = "yes";
		assert('sqltype.hasChanged("booleanType")');
		sqltype.booleanType = 1;
		assert('sqltype.hasChanged("booleanType")');
		sqltype.booleanType = "1";
		assert('sqltype.hasChanged("booleanType")');
	}

	function test_should_be_able_to_update_integer_from_null_to_0() {
		user = model("user").findByKey(1);
		transaction {
			user.birthDayYear = "";
			user.save();
			user.birthDayYear = 0;
			user.save();
			user.reload();
			transaction action="rollback";
		}
		assert("user.birthDayYear IS 0");
	}

}
