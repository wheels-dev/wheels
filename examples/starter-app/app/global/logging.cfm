<cfscript>
//=====================================================================
//=     Logging
//=====================================================================

/**
* Adds a logline to the Audit Log: doesn't log anything in testing mode
*
* [section: Application]
* [category: Utils]
*
* @type Anything you want to group by: i.e, email | database | user | auth | login | flash etc.
* @message The Message
* @severity One of info | warning | danger
* @data Arbitary data to store alongside this log line. will be serialized
* @createdBy Username of who fired the log line
*/
public void function addLogLine(required string type, required string message, string severity="info", any data, string createdBy="Anon"){
	if(!structKeyExists(request, "isTestingMode")){
		if(isAuthenticated()){
			arguments.createdBy=getSession().user.properties.firstname & ' ' & getSession().user.properties.lastname;
		}
		arguments.ipaddress=getIPAddress();
		local.newLogLine=model("auditlog").create(arguments);
	}
}

</cfscript>
