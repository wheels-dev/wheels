/*
  |----------------------------------------------------------------------|
	| Parameter     | Required | Type    | Default | Description           |
  |----------------------------------------------------------------------|
	| table         | Yes      | string  |         | existing table name   |
	| columnName    | Yes      | string  |         | existing column name  |
	| newColumnName | No       | string  |         | new name for column   |
  |----------------------------------------------------------------------|

    EXAMPLE:
      renameColumn(table='users', columnName='password', newColumnName='');
*/
component extends="[extends]" hint="[description]" {

	function up() {
		var state = {};
		transaction {
			try {
				renameColumn(table = 'tableName', columnName = 'columnName', newColumnName = 'newColumnName');
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
				renameColumn(table = 'tableName', columnName = 'columnName', newColumnName = 'newColumnName');
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
