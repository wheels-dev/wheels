component extends="wheels.tests.Test" {

	function test_$listToStruct() {
		actual = $listToStruct("a,b,c");
		assert('actual.a eq 1');
		assert('actual.b eq 1');
		assert('actual.c eq 1');
		assert("ListLen(StructKeyList(actual)) eq 3");
	}

}
