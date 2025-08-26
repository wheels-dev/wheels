component extends="app.tests.Test" {

	function setup(){
		super.setup();
	}

	function teardown(){
		super.teardown();
	}

	function test_isNotUnique(){
		p = model("permission").new();
		p.setProperties(
			name = "admin", type="controller"
		);
		r = p.valid();
		err = p.allErrors();
		assert("r EQ false");
		assert("err[1]['property'] EQ 'name'");
	}

	function test_checkForType(){
		p = model("permission").new();
		p.setProperties(
			name = "foo.bar.baz", type="BADVALUE"
		);
		r = p.valid();
		err = p.allErrors();
		assert("r EQ false");
		assert("err[1]['property'] EQ 'type'");
	}

	function test_checkNameFormat_Spaces(){
		p = model("permission").new();
		p.setProperties(
			name = "I Should Fail", type="controller"
		);
		r = p.valid();
		err = p.allErrors();
		assert("r EQ false");
		assert("err[1]['property'] EQ 'name'");
	}

	function test_checkNameFormat_Dots(){
		p = model("permission").new();
		p.setProperties(
			name = "admin.foo.abr", type="named"
		);
		r = p.valid();
		err = p.allErrors();
		assert("r EQ false");
		assert("err[1]['property'] EQ 'name'");
	}

	function test_validation_passes(){
		p = model("permission").new();
		p.setProperties(
			name = "foo.bar.baz", type="controller"
		);
		assert("p.valid()");
	}
}
