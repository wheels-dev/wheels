/*
  |----------------------------------------------------------------------------|
	| Parameter     | Required | Type    | Default | Description                 |
  |----------------------------------------------------------------------------|
	| table         | Yes      | string  |         | table name                  |
	| indexName     | Yes      | string  |         | name of the index to remove |
  |----------------------------------------------------------------------------|

    EXAMPLE:
      removeIndex(table='members',indexName='members_username');
*/
component extends="[extends]" hint="[description]" {

	function up() {
		transaction {
			try {
				removeIndex(table = 'tableName', indexName = '');
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
				addIndex(table = 'tableName', columnNames = 'columnName', unique = true);
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
