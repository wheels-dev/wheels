/*
  |-------------------------------------------------------------------------------------------|
	| Parameter     | Required | Type    | Default | Description                                |
  |-------------------------------------------------------------------------------------------|
	| table         | Yes      | string  |         | Name of table to add record to             |
	| columnNames   | Yes      | string  |         | Use column name as argument name and value |
  |-------------------------------------------------------------------------------------------|

    EXAMPLE:
      addRecord(table='members',id=1,username='admin',password='#Hash("admin")#');
*/
component extends="wheels.migrator.Migration" hint="Adds Default User Accounts" {

	function up() {
		transaction {
			try {
				//Password123!
			 	addRecord(table='users', verified=1, firstname="Example", lastname="Administrator", email="admin@domain.com", roleid=1, createdAt=now(), passwordHash="$2a$12$aUqhjsUm.BtrlrIxHFEMsO.LN.WbEd6hYYwsh3V5Rph5gL454e7Xi", adminNotes="This is a an example Administrator Account" );
			 	addRecord(table='users', verified=1, firstname="Example", lastname="Editor", email="editor@domain.com", roleid=2, createdAt=now(), passwordHash="$2a$12$aUqhjsUm.BtrlrIxHFEMsO.LN.WbEd6hYYwsh3V5Rph5gL454e7Xi", adminNotes="This is a an example Editor Account" );
			 	addRecord(table='users', verified=1, firstname="Example", lastname="User", email="user@domain.com", roleid=3, createdAt=now(), passwordHash="$2a$12$aUqhjsUm.BtrlrIxHFEMsO.LN.WbEd6hYYwsh3V5Rph5gL454e7Xi", adminNotes="This is a an example User Account" );
			 	addRecord(table='users', verified=1, firstname="Another", lastname="User", email="user2@domain.com", roleid=3, createdAt=now(), passwordHash="$2a$12$aUqhjsUm.BtrlrIxHFEMsO.LN.WbEd6hYYwsh3V5Rph5gL454e7Xi", adminNotes="This is a an example User Account with some user permissions set" );
			 	addRecord(table='users', verified=0, firstname="ExamplePending", lastname="User", email="user3@domain.com", roleid=3, createdAt=now(), passwordHash="$2a$12$aUqhjsUm.BtrlrIxHFEMsO.LN.WbEd6hYYwsh3V5Rph5gL454e7Xi", adminNotes="This is a an example User Account which has yet to be verified" );
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
			} else {
				transaction action="commit";
			}
		}
	}

	function down() {
		transaction {
			try {
				removeRecord(table='users', where="id IS NOT NULL");
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
			} else {
				transaction action="commit";
			}
		}
	}

}
