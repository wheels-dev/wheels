component extends="wheels.tests.Test" {

	function setup() {
		application.wheels.transactionMode = "commit";
	}

	function teardown() {
		application.wheels.transactionMode = "none";
	}

	function test_create_rollbacks_when_callback_returns_false() {
		tag = model("tagFalseCallbacks").create(name = "Kermit", description = "The Frog");
		tag = model("tagFalseCallbacks").findOne(where = "name='Kermit'");
		assert("tag IS false");
	}

	function test_update_rollbacks_when_callback_returns_false() {
		tag = model("tagFalseCallbacks").findOne(where = "description='testdesc'");
		tag.update(name = "Kermit");
		tag = model("tagFalseCallbacks").findOne(where = "description='testdesc'");
		assert("tag.name IS 'releases'");
	}

	function test_save_rollbacks_when_callback_returns_false() {
		tag = model("tagFalseCallbacks").findOne(where = "description='testdesc'");
		tag.name = "Kermit";
		tag.save();
		tag = model("tagFalseCallbacks").findOne(where = "description='testdesc'");
		assert("tag.name IS 'releases'");
	}

	function test_delete_rollbacks_when_callback_returns_false() {
		tag = model("tagFalseCallbacks").findOne(where = "description='testdesc'");
		tag.delete();
		tag = model("tagFalseCallbacks").findOne(where = "description='testdesc'");
		assert("IsObject(tag)");
	}

	function test_deleteAll_with_instantiate_rollbacks_when_callback_returns_false() {
		model("tagFalseCallbacks").deleteAll(instantiate = true);
		results = model("tagFalseCallbacks").findAll();
		assert("results.recordcount IS 8");
	}

	function test_updateAll_with_instantiate_rollbacks_when_callback_returns_false() {
		model("tagFalseCallbacks").updateAll(name = "Kermit", instantiate = true);
		results = model("tagFalseCallbacks").findAll(where = "name = 'Kermit'");
		assert("results.recordcount IS 0");
	}

	function test_create_with_rollback() {
		tag = model("tag").create(name = "Kermit", description = "The Frog", transaction = "rollback");
		tag = model("tag").findOne(where = "name='Kermit'");
		assert("not IsObject(tag)");
	}

	function test_update_with_rollback() {
		tag = model("tag").findOne(where = "description='testdesc'");
		tag.update(name = "Kermit", transaction = "rollback");
		tag = model("tag").findOne(where = "description='testdesc'");
		assert("tag.name IS 'releases'");
	}

	function test_save_with_rollback() {
		tag = model("tag").findOne(where = "description='testdesc'");
		tag.name = "Kermit";
		tag.save(transaction = "rollback");
		tag = model("tag").findOne(where = "description='testdesc'");
		assert("tag.name IS 'releases'");
	}

	function test_delete_with_rollback() {
		tag = model("tag").findOne(where = "description='testdesc'");
		tag.delete(transaction = "rollback");
		tag = model("tag").findOne(where = "description='testdesc'");
		assert("IsObject(tag)");
	}

	function test_deleteAll_with_rollback() {
		model("tag").deleteAll(instantiate = true, transaction = "rollback");
		results = model("tag").findAll();
		assert("results.recordcount IS 8");
	}

	function test_updateAll_with_rollback() {
		model("tag").updateAll(name = "Kermit", instantiate = true, transaction = "rollback");
		results = model("tag").findAll(where = "name = 'Kermit'");
		assert("results.recordcount IS 0");
	}

	function test_create_with_transactions_disabled() {
		transaction {
			tag = model("tag").create(name = "Kermit", description = "The Frog", transaction = "none");
			tag = model("tag").findOne(where = "name='Kermit'");
			assert("IsObject(tag)");
			transaction action="rollback";
		}
	}

	function test_create_with_transactions_false() {
		transaction {
			tag = model("tag").create(name = "Kermit", description = "The Frog", transaction = false);
			tag = model("tag").findOne(where = "name='Kermit'");
			assert("IsObject(tag)");
			transaction action="rollback";
		}
	}

	function test_update_with_transactions_disabled() {
		transaction {
			tag = model("tag").findOne(where = "description='testdesc'");
			tag.update(name = "Kermit", transaction = "none");
			tag.reload();
			assert("tag.name IS 'Kermit'");
			transaction action="rollback";
		}
	}

	function test_save_with_transactions_disabled() {
		transaction {
			tag = model("tag").findOne(where = "description='testdesc'");
			tag.name = "Kermit";
			tag.save(transaction = "none");
			tag.reload();
			assert("tag.name IS 'Kermit'");
			transaction action="rollback";
		}
	}

	function test_delete_with_transactions_disabled() {
		transaction {
			tag = model("tag").findOne(where = "description='testdesc'");
			tag.delete(transaction = "none");
			tag = model("tag").findOne(where = "description='testdesc'");
			assert("not IsObject(tag)");
			transaction action="rollback";
		}
	}

	function test_deleteAll_with_transactions_disabled() {
		transaction {
			model("tag").deleteAll(instantiate = true, transaction = "none");
			results = model("tag").findAll();
			assert("results.recordcount IS 0");
			transaction action="rollback";
		}
	}

	function test_updateAll_with_transactions_disabled() {
		transaction {
			model("tag").updateAll(name = "Kermit", instantiate = true, transaction = "none");
			results = model("tag").findAll(where = "name = 'Kermit'");
			assert("results.recordcount IS 8");
			transaction action="rollback";
		}
	}

	function test_nested_transaction_within_callback_respect_initial_transaction_mode() {
		postsBefore = model('post').count(reload = true);
		tag = model("tagWithDataCallbacks").create(name = "Kermit", description = "The Frog", transaction = "rollback");
		postsAfter = model('post').count(reload = true);
		assert("IsObject(tag)");
		assert("postsBefore eq postsAfter");
	}

	function test_nested_transaction_within_callback_with_transactions_disabled() {
		transaction {
			tag = model("tagWithDataCallbacks").create(name = "Kermit", description = "The Frog", transaction = "none");
			results = model("tag").findAll(where = "name = 'Kermit'");
			transaction action="rollback";
		}
		assert("IsObject(tag)");
		assert("results.recordcount IS 1");
	}

	function test_transaction_closed_after_rollback() {
		hash = model("tag").$hashedConnectionArgs();
		tag = model("tagWithDataCallbacks").create(name = "Kermit", description = "The Frog", transaction = "rollback");
		assert('request.wheels.transactions[hash] is false');
	}

	function test_transaction_closed_after_none() {
		hash = model("tag").$hashedConnectionArgs();
		transaction {
			tag = model("tagWithDataCallbacks").create(name = "Kermit", description = "The Frog", transaction = "none");
			transaction action="rollback";
		}
		assert('request.wheels.transactions[hash] is false');
	}

	function test_transaction_closed_when_error_raised() {
		hash = model("tag").$hashedConnectionArgs();
		try {
			tag = model("tag").create(
				id = "",
				name = "Kermit",
				description = "The Frog",
				transaction = "rollback"
			);
		} catch (any e) {
		}
		assert('request.wheels.transactions[hash] is false');
	}

	function test_rollback_when_error_raised() {
		tag = Duplicate(model("tagWithDataCallbacks").new(name = "Kermit", description = "The Frog"));
		tag.afterSave(methods = "crashMe");
		try {
			tag.save();
		} catch (any e) {
			results = model("tag").findAll(where = "name = 'Kermit'");
		}
		assert("results.recordcount IS 0");
	}

}
