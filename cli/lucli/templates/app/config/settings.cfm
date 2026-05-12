<cfscript>
	/*
		Use this file to configure your application.
		You can also use the environment specific files (e.g. /config/production/settings.cfm) to override settings set here.
		Don't forget to issue a reload request (e.g. reload=true) after making changes.
		See https://guides.wheels.dev/v4-0-0-snapshot/working-with-wheels/configuration-and-defaults for more info.
	*/

	/*
		Set data source name. By default uses the app name.
		Uncomment username/password if your datasource requires them.
	*/
	set(dataSourceName="{{datasourceName}}");
	// set(dataSourceUserName="");
	// set(dataSourcePassword="");

	/*
		URL rewriting mode: "On", "Partial", or "Off".
		"On" requires web server rewrite rules (or urlrewrite.xml for LuCLI/Tuckey).
		"Partial" requires cgi.path_info support.
	*/
	set(URLRewriting="On");

	// Reload your application with ?reload=true&password={{reloadPassword}}
	set(reloadPassword="{{reloadPassword}}");

	// CLI-Appends-Here
</cfscript>
