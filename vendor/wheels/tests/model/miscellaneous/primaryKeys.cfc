component extends="wheels.tests.Test" {

	function test_primarykey_returns_key() {
		author = model("author");
		e = author.$classData().keys;
		r = "id";
		assert("e IS r");
		r = author.primaryKey();
		assert("e IS r");
		r = author.primaryKeys();
		assert("e IS r");
	}

	function test_setprimarykey_appends_keys() {
		author = model("author");
		author = Duplicate(author);
		e = author.$classData().keys;
		r = "id";
		assert("e IS r");
		author.setprimaryKeys("id2,id3");
		e = "id,id2,id3";
		r = author.primaryKeys();
		assert("e IS r");
	}

	function test_setprimarykey_not_append_duplicate_keys() {
		author = model("author");
		author = Duplicate(author);
		e = author.$classData().keys;
		r = "id";
		assert("e IS r");
		author.setprimaryKeys("id2");
		author.setprimaryKeys("id2");
		e = "id,id2";
		r = author.primaryKeys();
		assert("e IS r");
	}

	function test_retrieve_primary_key_by_position() {
		author = model("author");
		author = Duplicate(author);
		author.setprimaryKeys("id2,id3");
		e = author.primaryKeys(1);
		r = "id";
		assert("e IS r");
		e = author.primaryKeys(2);
		r = "id2";
		assert("e IS r");
	}

}
