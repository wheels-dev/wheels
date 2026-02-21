/*
  |----------------------------------------------------------------------------------------------------------------------------|
	| Parameter     | Required | Type    | Default | Description                                                                 |
  |----------------------------------------------------------------------------------------------------------------------------|
	| table         | Yes      | string  |         | table name                                                                  |
	| columnNames   | Yes      | string  |         | one or more column names to index, comma separated                          |
	| unique        | No       | boolean |  false  | if true will create a unique index constraint                               |
	| indexName     | No       | string  |         | use for index name. Defaults to table name + underscore + first column name |
	|----------------------------------------------------------------------------------------------------------------------------|

    EXAMPLE:
      addIndex(table='members', columnNames='username', unique=true);
*/
component extends="[extends]" hint="[description]" {

	function up() {
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

	function down() {
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

}
