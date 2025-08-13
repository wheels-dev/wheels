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
component extends="wheels.migrator.Migration" hint="Adds Default Settings" {

	function up() {
		transaction {
			try {

			/*
				Settings: note, "value" should be stored as JSON. This is because value is stored in a text field
				on purpose. MySQL is more forgiving than MSSQL when trying to insert an integer into a text field,
				So we're forcing everything to JSON so it's always treated as a string. Has the additional bonus in
				that we can store complex values in the value column for future use (i.e, arrays for dropdowns etc)
			*/
		  // Auth
          addRecord(table='settings',
          			name="authentication_gateway",
          			description="Authentication Gateway: set to local for standard local user accounts",
          			type="select",
          			options="local,LDAP,External",
          			value=serializeJSON("local"));
          addRecord(table='settings',
          			name="authentication_allowRegistration",
          			description="Allow User Registration",
            		type="boolean",
            		value=serializeJSON("true"));
          addRecord(table='settings',
          			name="authentication_allowPasswordResets",
          			description="Allow Password Resets",
            		type="boolean",
            		value=serializeJSON("true"));
          addRecord(table='settings',
          			name="authentication_defaultRole",
          			description="Default Role for new accounts",
            		type="select", options="[[getRoleDropdownList()]]",
            		value=serializeJSON("3"));
          addRecord(table='settings',
          			name="permissions_cascade",
          			description="Cascade Permissions",
            		type="boolean",
            		value=serializeJSON("true"));


          // Email
          addRecord(table='settings',
          			name="email_send",
          			description="Allow this Application to send email",
            		type="boolean",
            		value=serializeJSON("true"));
          addRecord(table="settings",
          			name="email_fromAddress",
          			description="General 'From' Email address - used in password resets etc",
          			type="textfield",
          			value=serializeJSON("admin@domain.com"));

          // i8n
          //addRecord(table='settings',
          //			name="i8n_defaultLanguage",
          //			description="Default Language for the main interface",
          //  		type="select", options="[[request.lang.availablelanguages]]",
          //  		value=serializeJSON("en_GB"));
          //addRecord(table='settings',
          //			name="i8n_defaultLocale",
          //			description="Default Locale for the main interface: changes date/time/currency formatting etc",
          //  		type="select", options="[[getLocaleListDropDown()]]",
          //  		value=serializeJSON("English (United Kingdom)"));
          //addRecord(table='settings',
          //			name="i8n_defaultTimeZone",
          //			description="Default Timezone for all buildings,users,rooms",
          //  		type="select", options="[[getTZListDropDown()]]",
          //  		value=serializeJSON("Europe/London"));

          // Misc
          addRecord(table='settings',
          			name="general_sitename",
          			description="General Site Name",
            		type="textfield",
            		value=serializeJSON("Example App"));
	       addRecord(table='settings',
	       			name="general_copyright",
	       			description="Footer Notice",
            		type="textfield",
            		value=serializeJSON("Copyright Example Wheels App"));


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
				removeRecord(table='settings', where="id IS NOT NULL");
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
