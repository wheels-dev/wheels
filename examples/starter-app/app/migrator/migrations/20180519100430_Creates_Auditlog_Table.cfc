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
			t.string(columnNames='firstName,lastName', default='', allowNull=true, limit='255');
			t.text(columnNames='bio', default='', allowNull=true);
			t.binary(columnNames='credentials');
			t.biginteger(columnNames='sinsCommitted', default='', allowNull=true, limit='1');
			t.char(columnNames='code', default='', allowNull=true, limit='8');
			t.decimal(columnNames='hourlyWage', default='', allowNull=true, precision='1', scale='2');
			t.date(columnNames='dateOfBirth', default='', allowNull=true);
			t.datetime(columnNames='employmentStarted', default='', allowNull=true);
			t.float(columnNames='height', default='', allowNull=true);
			t.integer(columnNames='age', default='', allowNull=true, limit='1');
      t.time(columnNames='lunchStarts', default='', allowNull=true);
			t.uniqueidentifier(columnNames='uid', default='newid()', allowNull=false);
			t.references(referenceNames="vacation");
			t.timestamps();
			t.create();
*/
component extends="wheels.migrator.Migration" hint="Creates Audit Log Table" {

	function up() {
		transaction {
			try {
				t = createTable(name='auditlogs');
				t.string(columnNames='message,createdBy', allowNull=false, limit=500);
				t.string(columnNames='type', allowNull=false, limit=50);
				t.string(columnNames='severity', allowNull=false, limit=50);
				t.string(columnNames='ipaddress', allowNull=false, limit=45); // handle IPv4-mapped IPv6 (45 characters)
				t.text(columnNames='data', allowNull=true);
				t.timestamp(columnNames='createdAt', allowNull=true);
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
				dropTable('auditlogs');
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
