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
			t.references(columnNames="vacation");
			t.timestamps();
			t.create();
*/
component extends="[extends]" hint="[description]" {

	function up() {
		var state = {};
		transaction {
			try {
				t = createTable(name = 'tableName');
				t.timestamps();
				t.create();
			} catch (any e) {
				state.exception = e;
			}

			if (StructKeyExists(state, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = state.exception.detail, message = state.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

	function down() {
		var state = {};
		transaction {
			try {
				dropTable('tableName');
			} catch (any e) {
				state.exception = e;
			}

			if (StructKeyExists(state, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = state.exception.detail, message = state.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

}
