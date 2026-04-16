<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://wheels.dev/3.1.0/guides/handling-requests-with-controllers/routing for more info.

	mapper()
		// CLI-Appends-Here

		// Browser test fixture routes (loginAs endpoint is env-gated in controller)
		.scope(path="/_browser")
			.get(name="browserTestHome", pattern="/home", to="BrowserTestHome##index")
			.get(name="browserTestLogin", pattern="/login", to="BrowserTestSessions##new")
			.post(name="browserTestAuthenticate", pattern="/login", to="BrowserTestSessions##create")
			.get(name="browserTestDashboard", pattern="/dashboard", to="BrowserTestHome##dashboard")
			.post(name="browserTestLogout", pattern="/logout", to="BrowserTestSessions##destroy")
			.get(name="browserTestLoginAs", pattern="/login-as", to="BrowserTestLogin##create")
		.end()

		// The "wildcard" call below enables automatic mapping of "controller/action" type routes.
		// This way you don't need to explicitly add a route every time you create a new action in a controller.
		.wildcard()

		// The root route below is the one that will be called on your application's home page (e.g. http://127.0.0.1/).
		//.root(to = "home##index", method = "get")
		.root(method = "get")
	.end();
</cfscript>
