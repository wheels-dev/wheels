<cfscript>
	/*
		Use this file to configure your application.
		You can also use the environment specific files (e.g. /config/production/settings.cfm) to override settings set here.
		Don't forget to issue a reload request (e.g. reload=true) after making changes.
		See http://docs.cfwheels.org/docs/configuration-and-defaults for more info.
	*/

	/*
		If you leave these settings commented out, CFWheels will set the data source name to the same name as the folder the application resides in.
	*/
	set(coreTestDataSourceName="wheelstestdb_oracle");
	set(dataSourceName="wheelstestdb_oracle");
	// set(dataSourceUserName="");
	// set(dataSourcePassword="");

	/*
		If you comment out the following line, CFWheels will try to determine the URL rewrite capabilities automatically.
		The "URLRewriting" setting can bet set to "on", "partial" or "off".
		To run with "partial" rewriting, the "cgi.path_info" variable needs to be supported by the web server.
		To run with rewriting set to "on", you need to apply the necessary rewrite rules on the web server first.
	*/
	set(URLRewriting="On");

	// Reload your application with ?reload=true&password=|reloadPassword|
	set(reloadPassword="wheelstestdb");

	// CLI-Appends-Here
</cfscript>
