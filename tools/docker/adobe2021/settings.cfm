<cfscript>
	/*
		Use this file to configure your application.
		You can also use the environment specific files (e.g. /config/production/settings.cfm) to override settings set here.
		Don't forget to issue a reload request (e.g. reload=true) after making changes.
		See https://guides.wheels.dev/v4-0-0/core-concepts/environments-and-configuration/ for more info.
	*/

	/*
		If you leave these settings commented out, Wheels will set the data source name to the same name as the folder the application resides in.
	*/
	set(coreTestDataSourceName="wheelstestdb_sqlserver");
	set(dataSourceName="wheelstestdb_sqlserver");
	// set(dataSourceUserName="");
	// set(dataSourcePassword="");

	/*
		If you comment out the following line, Wheels will try to determine the URL rewrite capabilities automatically.
		The "URLRewriting" setting can bet set to "on", "partial" or "off".
		To run with "partial" rewriting, the "cgi.path_info" variable needs to be supported by the web server.
		To run with rewriting set to "on", you need to apply the necessary rewrite rules on the web server first.
	*/
	set(URLRewriting="On");

	// Reload your application with ?reload=true&password=wheels-dev
	// SECURITY (issue #3062): an empty reloadPassword disables URL-based reload
	// entirely, so the harness needs a real (non-secret, throwaway) password for
	// edit-reload-test cycles. Matches the demo app's config/settings.cfm and
	// the SMOKE_RELOAD_PASSWORD the CI workflows use.
	set(reloadPassword="wheels-dev");

	// The harness reaches the dev tools (/wheels/core/tests, ...) from the host
	// through Docker port publishing, so requests arrive from the Docker gateway,
	// not loopback. Allow the Docker bridge (Linux CI) and Docker Desktop ranges.
	// compose.yml publishes the engine ports on 127.0.0.1 only, so LAN clients
	// cannot use this path. Test infrastructure only: never copy this into an app.
	set(devToolsAllowedRemoteAddresses="172.16.0.0/12,192.168.65.0/24");

	// CLI-Appends-Here
</cfscript>
