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
			t.string(columnNames='firstName,lastName', allowNull=true, limit='255');
			t.text(columnNames='bio', allowNull=true);
			t.binary(columnNames='credentials');
			t.biginteger(columnNames='sinsCommitted', allowNull=true, limit='1');
			t.char(columnNames='code', allowNull=true, limit='8');
			t.decimal(columnNames='hourlyWage', allowNull=true, precision='1', scale='2');
			t.date(columnNames='dateOfBirth', allowNull=true);
			t.datetime(columnNames='employmentStarted', allowNull=true);
			t.float(columnNames='height', allowNull=true);
			t.integer(columnNames='age', allowNull=true, limit='1');
      t.time(columnNames='lunchStarts', allowNull=true);
			t.uniqueidentifier(columnNames='uid', default='newid()', allowNull=false);
			t.references(referenceNames="vacation");
			t.timestamps();
			t.create();
*/
component extends="wheels.migrator.Migration" hint="Creates Settings Table" {

	function up() {
		transaction {
			try {
				t = createTable(name='settings');
				t.string(columnNames="name,description,type", allowNull=true );
				t.text(columnNames="options,value,docs", allowNull=true );
				t.boolean(columnNames="editable", default=true);
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
				dropTable('settings');
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
