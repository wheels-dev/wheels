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
		transaction {
			try {
				renameColumn(table = 'tableName', columnName = 'columnName', newColumnName = 'newColumnName');
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

	function down() {
		transaction {
			try {
				renameColumn(table = 'tableName', columnName = 'columnName', newColumnName = 'newColumnName');
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");
			} else {
				transaction action="commit";
			}
		}
	}

}
