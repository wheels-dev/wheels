component extends="wheels.tests.Test" {

	function test_findOneOrCreateBy() {
		transaction {
			author = model("author").findOrCreateByFirstName(firstName = "Per", lastName = "Djurner");
			assert('IsObject(author)');
			assert('author.lastname eq "Djurner"');
			assert('author.firstname eq "Per"');
			transaction action="rollback";
		}
	}

	function test_findOneOrCreateByWithOnePropertyName() {
		transaction {
			author = model("author").findOrCreateByFirstName(firstName = "Per");
			assert('IsObject(author)');
			assert('author.firstname eq "Per"');
			transaction action="rollback";
		}
	}

	function test_findOneOrCreateByWithAnyPropertyName() {
		transaction {
			author = model("author").findOrCreateByFirstName(whatever = "Per");
			assert('IsObject(author)');
			assert('author.firstname eq "Per"');
			transaction action="rollback";
		}
	}

	function test_findOneOrCreateByWithUnnamedArgument() {
		transaction {
			author = model("author").findOrCreateByFirstName("Per");
			assert('IsObject(author)');
			assert('author.firstname eq "Per"');
			transaction action="rollback";
		}
	}

}
