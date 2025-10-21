component extends="Controller" {

	function config() {
		provides("html");
	}

	/**
	 * Login form
	 */
	function new() {
		// Just render the login form
	}

	/**
	 * Process login
	 */
	function create() {
		var user = model("User").findOne(where="email = '#params.email#'");

		if (isObject(user) && verifyPassword(params.password, user.passwordHash)) {
			session.userId = user.id;
			session.username = user.username;
			session.authenticated = true;

			flashInsert(success="Welcome back, #user.username#!");
			redirectTo(controller="tweets", action="index");
		} else {
			flashInsert(error="Invalid email or password");
			redirectTo(action="new");
		}
	}

	/**
	 * Logout
	 */
	function delete() {
		structClear(session);
		flashInsert(success="You have been logged out");
		redirectTo(action="new");
	}

	/**
	 * Verify password using SHA-256
	 */
	private function verifyPassword(required string password, required string hash) {
		return hash(arguments.password, "SHA-256") == arguments.hash;
	}
}
