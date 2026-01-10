<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/routing for more info.

	mapper()
		// Authentication routes
		.get(name="login", pattern="login", to="sessions##new")
		.post(name="authenticate", pattern="login", to="sessions##create")
		.get(name="logout", pattern="logout", to="sessions##delete")
		.get(name="register", pattern="register", to="users##new")

		// Resources
		.resources("users")
		.resources("tweets")

		// Like/Unlike routes
		.post(name="likeTweet", pattern="tweets/[tweetId]/like", to="likes##create")
		.get(name="unlikeTweet", pattern="tweets/[tweetId]/unlike", to="likes##delete")

		// Follow/Unfollow routes
		.post(name="followUser", pattern="users/[userId]/follow", to="follows##create")
		.get(name="unfollowUser", pattern="users/[userId]/unfollow", to="follows##delete")

		// CLI-Appends-Here

		// The "wildcard" call below enables automatic mapping of "controller/action" type routes.
		// This way you don't need to explicitly add a route every time you create a new action in a controller.
		.wildcard()

		// The root route below is the one that will be called on your application's home page (e.g. http://127.0.0.1/).
		.root(to="tweets##index", method="get")
	.end();
</cfscript>
