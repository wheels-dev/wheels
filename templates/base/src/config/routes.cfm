<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/routing for more info.

	mapper()
		// CLI-Appends-Here

		// MCP Server routes - must come before wildcard
		.post(pattern="/wheels/mcp", to="##mcp")
		.get(pattern="/wheels/mcp", to="##mcp")

		// The "wildcard" call below enables automatic mapping of "controller/action" type routes.
		// This way you don't need to explicitly add a route every time you create a new action in a controller.
		.wildcard()

		// The root route below is the one that will be called on your application's home page (e.g. http://127.0.0.1/).
		//.root(to = "home##index", method = "get")
		.root(method = "get")
	.end();
</cfscript>
