component extends="wheels.tests.Test" {

	function test_$listClean_default_delim() {
		mylist = "tony,    per   ,  james    ,,, chris   , raul ,,,,  peter";
		e = "tony,per,james,chris,raul,peter";
		r = $listClean(mylist);
		assert('e eq r');
	}

	function test_$listClean_provide_delim() {
		mylist = "tony|    per   |  james    | chris   | raul |||  peter";
		e = "tony|per|james|chris|raul|peter";
		r = $listClean(mylist, "|");
		assert('e eq r');
	}

	function test_$listClean_return_array() {
		mylist = "tony,    per   ,  james    ,,, chris   , raul ,,,,  peter";
		r = $listClean(list = mylist, returnAs = "array");
		assert('IsArray(r) and ArrayLen(r) eq 6');
	}

}
