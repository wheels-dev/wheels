component extends="Controller" {

	function config() {
		provides("html");
		filters(through="requireAuth", except="new,create");
		filters(through="findUser", only="show,edit,update");
	}

	/**
	 * Registration form
	 */
	function new() {
		user = model("User").new();
	}

	/**
	 * Create new user
	 */
	function create() {
		// Hash the password using SHA-256 (Lucee doesn't support BCrypt natively)
		params.user.passwordHash = hash(params.user.password, "SHA-256");

		user = model("User").create(params.user);

		if (user.valid()) {
			session.userId = user.id;
			session.username = user.username;
			session.authenticated = true;

			flashInsert(success="Welcome to Tweeter, #user.username#!");
			redirectTo(controller="tweets", action="index");
		} else {
			flashInsert(error="Please fix the errors below");
			renderView(action="new");
		}
	}

	/**
	 * User profile
	 */
	function show() {
		tweets = model("Tweet").findAll(
			where="userId = #user.id#",
			order="createdAt DESC",
			include="user"
		);

		// Check if current user follows this user
		if (structKeyExists(session, "userId") && session.userId != user.id) {
			isFollowing = model("Follow").findOne(
				where="followerId = #session.userId# AND followingId = #user.id#"
			);
			isFollowingUser = isObject(isFollowing);
		} else {
			isFollowingUser = false;
		}
	}

	/**
	 * Edit profile form
	 */
	function edit() {
		// Ensure user can only edit their own profile
		if (session.userId != user.id) {
			flashInsert(error="You can only edit your own profile");
			redirectTo(action="show", key=user.id);
		}
	}

	/**
	 * Update user profile
	 */
	function update() {
		// Ensure user can only update their own profile
		if (session.userId != user.id) {
			flashInsert(error="You can only update your own profile");
			redirectTo(action="show", key=user.id);
		}

		if (user.update(params.user)) {
			flashInsert(success="Profile updated successfully");
			redirectTo(action="show", key=user.id);
		} else {
			flashInsert(error="Please fix the errors below");
			renderView(action="edit");
		}
	}

	/**
	 * Require authentication filter
	 */
	private function requireAuth() {
		if (!structKeyExists(session, "authenticated") || !session.authenticated) {
			flashInsert(error="You must be logged in to access this page");
			redirectTo(controller="sessions", action="new");
		}
	}

	/**
	 * Find user by ID
	 */
	private function findUser() {
		user = model("User").findByKey(params.key);
		if (!isObject(user)) {
			flashInsert(error="User not found");
			redirectTo(controller="tweets", action="index");
		}
	}
}
