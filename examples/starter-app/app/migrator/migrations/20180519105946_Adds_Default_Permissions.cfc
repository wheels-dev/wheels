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
component extends="wheels.migrator.Migration" hint="Adds Default Permissions" {

	function up() {
		transaction {
			/*
			Controller Permissions
				roleid:
				1 = admin
				2 = editor
				3 = user

				If you're using non cascading permissions, you need to add a whole lot more.

				NB, remember it's the controller.action name ;
				So whilst the URL for logs might be /admin/logs, the CONTROLLER is admin.auditlogs and the action is index etc
			*/

			try {
				c=0;
				addRecord(table='permissions', id=++c, name='admin', description='Global Administrative Access');
				addRecord(table='rolepermissions', roleid=1, permissionid=c)

				addRecord(table='permissions', id=++c, name='admin.auditlogs', description='Allow Global Administrative Access to Logs');
				addRecord(table='permissions', id=++c, name='admin.auditlogs.index', description='View Logs');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.auditlogs.show', description='Show Log Extended Data')
				addRecord(table='permissions', id=++c, name='admin.permissions', description='Allow Global Administrative Access to Permissions');
				addRecord(table='permissions', id=++c, name='admin.permissions.index', description='List Permissions');
				addRecord(table='permissions', id=++c, name='admin.permissions.edit', description='Edit Permission');
				addRecord(table='permissions', id=++c, name='admin.permissions.update', description='Update Permission')
				addRecord(table='permissions', id=++c, name='admin.settings', description='Allow Global Administrative Access to Settings');
				addRecord(table='permissions', id=++c, name='admin.settings.index', description='List Settings');
				addRecord(table='permissions', id=++c, name='admin.settings.edit', description='Edit Setting');
				addRecord(table='permissions', id=++c, name='admin.settings.update', description='Update Setting')
				addRecord(table='permissions', id=++c, name='admin.users', description='Allow Global Administrative Access to Users');

				addRecord(table='permissions', id=++c, name='admin.users.index', description='List Users');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.users.new', description='New User');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.users.create', description='Create User');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.users.edit', description='Edit User');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.users.update', description='Update User');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.users.delete', description='Delete User');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.users.reset', description='Reset Users Password');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.users.recover', description='Recover User');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.users.show', description='View User');
				addRecord(table='rolepermissions', roleid=2, permissionid=c);

				addRecord(table='permissions', id=++c, name='admin.users.assume', description='Assume Users (Grant only to Admins)');
				addRecord(table='permissions', id=++c, name='admin.users.destroy', description='Destroy Users (Grant only to Admins)');
				addRecord(table='permissions', id=++c, name='admin.roles', description='Allow Global Administrative Access to Roles');
				addRecord(table='permissions', id=++c, name='admin.roles.index', description='List Roles');
				addRecord(table='permissions', id=++c, name='admin.roles.new', description='New Role');
				addRecord(table='permissions', id=++c, name='admin.roles.create', description='Create Role');
				addRecord(table='permissions', id=++c, name='admin.roles.edit', description='Edit Role');
				addRecord(table='permissions', id=++c, name='admin.roles.update', description='Update Role');
				addRecord(table='permissions', id=++c, name='admin.roles.delete', description='Delete Role');

				addRecord(table='permissions', id=++c, name='accounts', description='Allow Global Access to Own Profile');
				addRecord(table='rolepermissions', roleid=1, permissionid=c);
				addRecord(table='rolepermissions', roleid=2, permissionid=c);
				addRecord(table='rolepermissions', roleid=3, permissionid=c);

				addRecord(table='permissions', id=++c, name='accounts.show', description='View My Account');
				addRecord(table='permissions', id=++c, name='accounts.edit', description='Edit Own Account');
				addRecord(table='permissions', id=++c, name='accounts.update', description='Update Own Account');

				/*
				Named Permissions : arbitary permissions
				*/
				addRecord(table='permissions', id=++c, name='canViewAdminNotes', type="named", description='Allow user to view admin notes');

				addRecord(table='permissions', id=++c, name='canViewLogData', type="named", description='Allow user to view extended log data');
				addRecord(table='rolepermissions', roleid=1, permissionid=c);

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
				removeRecord(table='permissions', where="id IS NOT NULL");
				removeRecord(table='rolepermissions', where="roleid IS NOT NULL");
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
