component extends="wheels.tests.Test" {

	function test_tablename_and_tablenameprefix() {
		user = model("user2");
		assert('user.tableName() eq "tblusers"');
	}

	function test_tablename_and_tablenameprefix_in_finders_fixes_issue_667() {
		users = model("user2").findAll(select = "id");
		assert('users.recordcount eq 3');
	}

}
