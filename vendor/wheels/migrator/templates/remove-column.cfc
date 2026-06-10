/*
  |-------------------------------------------------------------------------------------------------|
	| Parameter     | Required | Type    | Default | Description                                      |
  |-------------------------------------------------------------------------------------------------|
	| table         | Yes      | string  |         | existing table name                              |
	| columnName    | No       | string  |         | existing column name                             |
	| referenceName | No       | string  |         | name of reference that was used to create column |
  |-------------------------------------------------------------------------------------------------|

    EXAMPLE:
      removeColumn(table='members',columnName='status');
*/
component extends="[extends]" hint="[description]" {

	function up() {
		var state = {};
		transaction {
			try {
				removeColumn(table = 'tableName', columnName = 'columnName');
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
				addColumn(table = 'tableName', columnType = '', columnName = 'columnName', default = '', allowNull = true);
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
