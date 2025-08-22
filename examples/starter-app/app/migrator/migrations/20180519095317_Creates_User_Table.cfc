/*
  |----------------------------------------------------------------------------------------------|
	| Parameter  | Required | Type    | Default | Description                                      |
  |----------------------------------------------------------------------------------------------|
	| name       | Yes      | string  |         | table name, in pluralized form                   |
	| force      | No       | boolean | false   | drop existing table of same name before creating |
	| id         | No       | boolean | true    | if false, defines a table with no primary key    |
	| primaryKey | No       | string  | id      | overrides default primary key name               |
  |----------------------------------------------------------------------------------------------|

    EXAMPLE:
      t = createTable(name='employees', force=false, id=true, primaryKey='empId');
			t.string(columnNames='firstName,lastName', default='', null=true, limit='255');
			t.text(columnNames='bio', default='', null=true);
			t.binary(columnNames='credentials');
			t.biginteger(columnNames='sinsCommitted', default='', null=true, limit='1');
			t.char(columnNames='code', default='', null=true, limit='8');
			t.decimal(columnNames='hourlyWage', default='', null=true, precision='1', scale='2');
			t.date(columnNames='dateOfBirth', default='', null=true);
			t.datetime(columnNames='employmentStarted', default='', null=true);
			t.float(columnNames='height', default='', null=true);
			t.integer(columnNames='age', default='', null=true, limit='1');
      t.time(columnNames='lunchStarts', default='', null=true);
			t.uniqueidentifier(columnNames='uid', default='newid()', null=false);
			t.references("vacation");
			t.timestamps();
			t.create();
*/
component extends="wheels.migrator.Migration" hint="Creates User Table" {

	function up() {
		transaction {
			try {
				t = createTable(name='users');
				// User properties
				t.string(columnNames='firstname,lastname', default='', null=false, limit=50);
				t.string(columnNames='email', default='', null=false, limit=255);
				t.text(columnNames='adminNotes', default='', null=true);
				// Password fields
				t.string(columnNames='passwordHash', default='', null=true, limit=500);
				t.string(columnNames='passwordResetToken,verificationToken', default='', null=true, limit=500);
				t.boolean(columnNames='passwordChangeRequired,verified', default=false);
				// Other useful timestamps
				t.datetime(columnNames='passwordResetTokenAt,passwordResetAt,loggedinAt', default='', null=true);
				// Role: assumes there won't be more than 999 roles(!)
				t.integer(columnNames='roleid', default=0, null=false, limit=3);
				t.timestamps();
				t.create();
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
				dropTable('users');
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
