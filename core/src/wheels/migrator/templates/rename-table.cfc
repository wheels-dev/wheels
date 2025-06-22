/*
  |----------------------------------------------------------------------------------------------|
	| Parameter  | Required | Type    | Default | Description                                      |
  |----------------------------------------------------------------------------------------------|
	| oldName    | Yes      | string  |         | existing table name                              |
	| newName    | Yes      | string  |         | new table name                              		 |
  |----------------------------------------------------------------------------------------------|

    EXAMPLE:
      renameTable(oldName='employees', newName='users');
*/
component extends="[extends]" hint="[description]" {

	function up() {
		transaction {
			try {
				renameTable(oldName = '', newName = '');
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
				renameTable(oldName = '', newName = '');
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
