component extends="wheels.tests.Test" {

	function test_accepts_undefined_value(string value1 = "foo", string value2) {
		/* value2 arg creates an undefined value to test $hashedKey() */
		e = raised('$hashedKey(argumentCollection=arguments)');
		r = "";
		assert('e eq r');
	}

	function test_accepts_generated_query(string a = "foo", query = QueryNew('a,b,c,e')) {
		/* query arg creates a query that does not have sql metadata */
		e = raised('$hashedKey(argumentCollection=arguments)');
		r = "";
		assert('e eq r');
	}

	function test_same_output() {
		binaryData = FileReadBinary(ExpandPath('/wheels/tests/_assets/files/cfwheels-logo.png'));
		transaction action="begin" {
			photo = model("photo").findOne();
			photo.update(filename = "somefilename", fileData = binaryData);
			photo = model("photo").findAll(where = "id = #photo.id#");
			transaction action="rollback";
		}
		a = [];
		a[1] = "petruzzi";
		a[2] = "gibson";
		query = QueryNew('a,b,c,d,e');
		QueryAddRow(query, 1);
		QuerySetCell(query, "a", "tony");
		QuerySetCell(query, "b", "per");
		QuerySetCell(query, "c", "james");
		QuerySetCell(query, "d", "chris");
		QuerySetCell(query, "e", "raul");
		a[3] = query;
		a[4] = [1, 2, 3, 4, 5, 6];
		a[5] = {a = 1, b = 2, c = 3, d = 4};
		a[6] = photo;
		args = {};
		args.a = a;
		e = $hashedKey(argumentCollection = args);
		ArraySwap(a, 1, 3);
		ArraySwap(a, 4, 5);
		r = $hashedKey(argumentCollection = args);
		assert('e eq r');
	}

}
