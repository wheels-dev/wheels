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
component extends="[extends]" hint="[description]" {

	function up() {
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

	function down() {
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

}
