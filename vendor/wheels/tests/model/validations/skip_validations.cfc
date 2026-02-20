component extends="wheels.tests.Test" {

	function setup() {
		user = model("user");
		args = {
			username = "myusername",
			password = "mypassword",
			firstname = "myfirstname",
			lastname = "mylastname"
		};
	}

	function test_can_create_new_record_validation_execute() {
		transaction {
			u = user.new(args);
			e = u.isnew();
			r = u.save();
			transaction action="rollback";
		}
		assert('e eq true');
		assert('r eq true');
	}

	function test_cannot_create_new_record_validation_execute() {
		transaction {
			args.username = "1";
			u = user.new(args);
			e = u.isnew();
			r = u.save();
			transaction action="rollback";
		}
		assert('e eq true');
		assert('r eq false');
	}

	function test_can_create_new_record_validation_skipped() {
		transaction {
			args.username = "1";
			u = user.new(args);
			e = u.isnew();
			r = u.save(validate = "false");
			transaction action="rollback";
		}
		assert('e eq true');
		assert('r eq true');
	}

	function test_can_update_existing_record_validation_execute() {
		transaction {
			u = user.findOne(where = "lastname = 'Petruzzi'");
			p = u.properties();
			r = u.update(args);
			e = u.isnew();
			u.update(p);
			transaction action="rollback";
		}
		assert('e eq false');
		assert('r eq true');
	}

	function test_cannot_update_existing_record_validation_execute() {
		transaction {
			args.password = "1";
			u = user.findOne(where = "lastname = 'Petruzzi'");
			p = u.properties();
			r = u.update(args);
			e = u.isnew();
			u.update(p);
			transaction action="rollback";
		}
		assert('e eq false');
		assert('r eq false');
	}

	function test_cant_update_existing_record_validation_skipped() {
		transaction {
			args.password = "1";
			u = user.findOne(where = "lastname = 'Petruzzi'");
			p = u.properties();
			u.setProperties(args);
			e = u.isnew();
			r = u.save(validate = "false");
			u.update(p);
			transaction action="rollback";
		}
		assert('e eq false');
		assert('r eq true');
	}

}
