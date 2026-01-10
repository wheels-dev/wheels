<cfscript>
	/*
		Use this file to configure your application.
		You can also use the environment specific files (e.g. /config/production/settings.cfm) to override settings set here.
		Don't forget to issue a reload request (e.g. reload=true) after making changes.
		See https://wheels.dev/3.0.0/guides/working-with-wheels/configuration-and-defaults for more info.
	*/

	/*
		If you leave these settings commented out, Wheels will set the data source name to the same name as the folder the application resides in.
	*/
	set(coreTestDataSourceName="wheelstestdb_mysql");
	set(dataSourceName="wheelstestdb_mysql");
	// set(dataSourceUserName="");
	// set(dataSourcePassword="");

	/*
		If you comment out the following line, Wheels will try to determine the URL rewrite capabilities automatically.
		The "URLRewriting" setting can bet set to "on", "partial" or "off".
		To run with "partial" rewriting, the "cgi.path_info" variable needs to be supported by the web server.
		To run with rewriting set to "on", you need to apply the necessary rewrite rules on the web server first.
	*/
	set(URLRewriting="On");

	// Reload your application with ?reload=true&password=|reloadPassword|
	set(reloadPassword="");

	// CLI-Appends-Here
</cfscript>
