<cfscript>
	/*
		Use this file to configure your application.
		You can also use the environment specific files (e.g. app/config/production/settings.cfm) to override settings set here.
		Don't forget to issue a reload request (e.g. reload=true) after making changes.
		See https://guides.wheels.dev/v/3.0.0-snapshot/working-with-cfwheels/configuration-and-defaults for more info.
	*/

	/*
		You can change the "wheels.dev" value from the two functions below to set your datasource.
		You can change the the value for the "dataSourceName" to set a default datasource to be used throughout your application.
		You can also change the value for the "coreTestDataSourceName" to set your testing datasource.
		You can also uncomment the 2 "set" functions below them to set the username and password for the datasource.
	*/
	set(coreTestDataSourceName="wheels.dev");
	set(dataSourceName="wheels.dev");
	// set(dataSourceUserName="");
	// set(dataSourcePassword="");

	/*
		If you comment out the following line, Wheels will try to determine the URL rewrite capabilities automatically.
		The "URLRewriting" setting can bet set to "on", "partial" or "off".
		To run with "partial" rewriting, the "cgi.path_info" variable needs to be supported by the web server.
		To run with rewriting set to "on", you need to apply the necessary rewrite rules on the web server first.
	*/
	set(URLRewriting="On");

	// Reload your application with ?reload=true&password=wheels.dev
	set(reloadPassword="wheels.dev");

	// CLI-Appends-Here
</cfscript>
