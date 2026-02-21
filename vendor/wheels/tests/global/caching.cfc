component extends="wheels.tests.Test" {

	function test_hashing_arguments_to_identical_result() {
		result1 = _method(1, 2, 3, 4, 5, 6, 7, 8, 9);
		result2 = _method(1, 2, 3, 4, 5, 6, 7, 8, 9);
		assert("result1 IS result2");
		result1 = _method("per", "was", "here");
		result2 = _method("per", "was", "here");
		assert("result1 IS result2");
		result1 = _method(a = 1, b = 2);
		result2 = _method(a = 1, b = 2);
		assert("result1 IS result2");
		aStruct = StructNew();
		aStruct.test1 = "a";
		aStruct.test2 = "b";
		anArray = ArrayNew(1);
		anArray[1] = 1;
		result1 = _method(a = aStruct, b = anArray);
		result2 = _method(a = aStruct, b = anArray);
		assert("result1 IS result2");
	}

	function _method() {
		return $hashedKey(arguments);
	}

}
