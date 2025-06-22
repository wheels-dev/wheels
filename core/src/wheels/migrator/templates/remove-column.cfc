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
		transaction {
			try {
				removeColumn(table = 'tableName', columnName = 'columnName');
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
				addColumn(table = 'tableName', columnType = '', columnName = 'columnName', default = '', null = true);
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
