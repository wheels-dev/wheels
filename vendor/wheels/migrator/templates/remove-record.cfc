/*
  |-------------------------------------------------------------------------------------------|
	| Parameter     | Required | Type    | Default | Description                                |
  |-------------------------------------------------------------------------------------------|
	| table         | Yes      | string  |         | Name of table to remove records from       |
	| where         | No       | string  |         | Where condition                            |
  |-------------------------------------------------------------------------------------------|

    EXAMPLE:
      removeRecord(table='members',where='id=1');
*/
component extends="[extends]" hint="[description]" {

	function up() {
		var state = {};
		transaction {
			try {
				removeRecord(table = 'tableName', where = '');
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
				addRecord(table = 'tableName', field = '');
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
