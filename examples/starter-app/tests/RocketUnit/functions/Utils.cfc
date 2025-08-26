component extends="tests.Test" {

	function setup() {
		super.setup();
	}
	function teardown() {
		super.teardown();
	}

	function Test_convertStringToStruct(){
		str="foo.bar";
		r=convertStringToStruct(str, "howdy");
		assert("isStruct(r) EQ true");
		assert("r.foo.bar EQ 'howdy'");
	}
}
