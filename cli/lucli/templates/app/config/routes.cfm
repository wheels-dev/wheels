<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://guides.wheels.dev/v4-0-0-snapshot/handling-requests-with-controllers/routing for more info.

	mapper()
		// CLI-Appends-Here

		// Liveness / warm-up endpoint. `wheels deploy`'s proxy healthcheck probes
		// `/up` before traffic cutover; a 200 here also compiles the request path
		// so the first real visitor gets warm latency. See app/controllers/Up.cfc.
		.get(name="up", to="up##index")

		// The "wildcard" call below enables automatic mapping of "controller/action" type routes.
		// This way you don't need to explicitly add a route every time you create a new action in a controller.
		.wildcard()

		// The root route below is the one that will be called on your application's home page.
		.root(to="main##index", method="get")
	.end();
</cfscript>
