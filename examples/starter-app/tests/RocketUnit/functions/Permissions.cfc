component extends="tests.Test" {


	function setup() {
		super.setup();
	}
	function teardown() {
		super.teardown();
		userPermissions={};
		params={};
	}

	function Test_getDefaultPermissionString_without_returns_empty(){
		params={"controller"="","action"=""};
		r=getDefaultPermissionString();
		assert("len(r) EQ 0");
	}

	function Test_getDefaultPermissionString_with_simple_controller_string(){
		params={"controller"="Test","action"=""};
		r=getDefaultPermissionString();
		assert("len(r) EQ 4");
	}
	function Test_getDefaultPermissionString_with_dotted_controller_string(){
		params={"controller"="Test.Test","action"=""};
		r=getDefaultPermissionString();
		assert("len(r) EQ 9");
	}
	function Test_getDefaultPermissionString_with_simple_controller_with_action(){
		params={"controller"="Test","action"="Foo"};
		r=getDefaultPermissionString();
		assert("len(r) EQ 8");
	}
	function Test_getDefaultPermissionString_with_dotted_controller_with_action(){
		params={"controller"="Test.Foo","action"="Bar"};
		r=getDefaultPermissionString();
		assert("len(r) EQ 12");
	}
	function Test_getPermissionArr_with_simple_string(){
		r=getPermissionArr("Test");
		assert("arraylen(r) EQ 1");
		assert("r[1] EQ 'test'");
	}
	function Test_getPermissionArr_with_dotted_string2(){
		r=getPermissionArr("Test.Test");
		assert("arraylen(r) EQ 2");
		assert("r[1] EQ 'test'");
		assert("r[2] EQ 'test.test'");
	}
	function Test_getPermissionArr_with_dotted_string3(){
		r=getPermissionArr("Test.Foo.Bar");
		assert("arraylen(r) EQ 3");
		assert("r[1] EQ 'test'");
		assert("r[2] EQ 'test.foo'");
		assert("r[3] EQ 'test.foo.bar'");

	}
	function Test_getPermissionArr_with_dotted_string4(){
		r=getPermissionArr("Test.Foo.bar.poi");
		assert("arraylen(r) EQ 4");
		assert("r[1] EQ 'test'");
		assert("r[2] EQ 'test.foo'");
		assert("r[3] EQ 'test.foo.bar'");
		assert("r[4] EQ 'test.foo.bar.poi'");
	}

	function Test_convertStringToStruct_with_simple_string(){
		r=convertStringToStruct("Test", true);
		assert("isStruct(r) EQ true");
		assert("structKeyExists(r, 'Test') EQ true");
	}
	function Test_convertStringToStruct_with_dotted_string2(){
		r=convertStringToStruct("Test.Test", true);
		assert("isStruct(r) EQ true");
		assert("structKeyExists(r, 'Test') EQ true");
		assert("structKeyExists(r.Test, 'Test') EQ true");

	}
	function Test_convertStringToStruct_with_dotted_string3(){
		r=convertStringToStruct("Test.Foo.Bar", true);
		assert("isStruct(r) EQ true");
		assert("structKeyExists(r, 'Test') EQ true");
		assert("structKeyExists(r.Test, 'Foo') EQ true");
		assert("structKeyExists(r.Test.Foo, 'Bar') EQ true");
	}
	function Test_convertStringToStruct_with_dotted_string4(){
		r=convertStringToStruct("Test.Foo.bar.poi", true);
		assert("isStruct(r) EQ true");
		assert("structKeyExists(r, 'Test') EQ true");
		assert("structKeyExists(r.Test, 'Foo') EQ true");
		assert("structKeyExists(r.Test.Foo, 'Bar') EQ true");
		assert("structKeyExists(r.Test.Foo.Bar, 'poi') EQ true");
	}

	function Test_hasPermission_cascade_top_level_admin(){
		userPermissions={
			"admin": true
		};
		r=hasPermission(permission="admin",
						userPermissions=userPermissions,
						debug=true);
		r2=hasPermission(permission="admin.foo",
						userPermissions=userPermissions,
						debug=true);
		r3=hasPermission(permission="admin.foo.bar",
						userPermissions=userPermissions,
						debug=true);
		assert("r.rv EQ true");
		assert("r2.rv EQ true");
		assert("r3.rv EQ true");
	}

	function Test_hasPermission_cascade_mid_level_admin(){
		userPermissions={
			"admin.foo": true
		};
		r=hasPermission(permission="admin",
						userPermissions=userPermissions,
						debug=true);
		r2=hasPermission(permission="admin.foo",
						userPermissions=userPermissions,
						debug=true);
		r3=hasPermission(permission="admin.foo.bar",
						userPermissions=userPermissions,
						debug=true);
		assert("r.rv EQ false");
		assert("r2.rv EQ true");
		assert("r3.rv EQ true");
	}

	function Test_hasPermission_cascade_3rd_level_admin(){
		userPermissions={
			"admin.foo.bar": true
		};
		r=hasPermission(permission="admin",
						userPermissions=userPermissions,
						debug=true);
		r2=hasPermission(permission="admin.foo",
						userPermissions=userPermissions,
						debug=true);
		r3=hasPermission(permission="admin.foo.bar",
						userPermissions=userPermissions,
						debug=true);
		assert("r.rv EQ false");
		assert("r2.rv EQ false");
		assert("r3.rv EQ true");
	}

	// These should always return false
	function Test_hasPermission_with_non_existent_permission(){
		r=hasPermission(permission="ishouldfail",
			userPermissions=userPermissions);
		assert("r EQ false");
	}
}
