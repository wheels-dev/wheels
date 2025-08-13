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
component extends="wheels.migrator.Migration" hint="Adds User Permissions" {

	function up() {
		transaction {
			/*
				roleid:
				1 = admin
				2 = editor
				3 = user

				If you're using non cascading permissions, you need to add a whole lot more.

				NB, remember it's the controller.action name ;
				So whilst the URL for logs might be /admin/logs, the CONTROLLER is admin.auditlogs and the action is index etc
			*/

			try {
			// Add some test user permissions to our example user
			// This user can see the logs
			 addRecord(table='userpermissions', userid=4, permissionid=2);
			// This user has an named user permission set so they can see admin logs
			 addRecord(table='userpermissions', userid=1, permissionid=35);


			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
			} else {
				transaction action="commit";
			}
		}
	}

	function down() {
		transaction {
			try {
				removeRecord(table='userpermissions', where="userid IS NOT NULL");
			} catch (any e) {
				local.exception = e;
			}

			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
			} else {
				transaction action="commit";
			}
		}
	}

}
