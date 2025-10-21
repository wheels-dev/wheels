component extends="Controller" {

	function config() {
		provides("html");
		filters(through="requireAuth");
	}

	/**
	 * Follow a user
	 */
	function create() {
		follow = model("Follow").create(
			followerId = session.userId,
			followingId = params.userId
		);

		if (follow.valid()) {
			// Update follower's following count
			follower = model("User").findByKey(session.userId);
			follower.update(followingCount = follower.followingCount + 1);

			// Update following's followers count
			following = model("User").findByKey(params.userId);
			following.update(followersCount = following.followersCount + 1);

			flashInsert(success="User followed!");
		} else {
			flashInsert(error="Error following user");
		}

		redirectTo(back=true, default="{controller='users',action='show',key='#params.userId#'}");
	}

	/**
	 * Unfollow a user
	 */
	function delete() {
		follow = model("Follow").findOne(
			where="followerId = #session.userId# AND followingId = #params.userId#"
		);

		if (isObject(follow) && follow.delete()) {
			// Update follower's following count
			follower = model("User").findByKey(session.userId);
			if (follower.followingCount > 0) {
				follower.update(followingCount = follower.followingCount - 1);
			}

			// Update following's followers count
			following = model("User").findByKey(params.userId);
			if (following.followersCount > 0) {
				following.update(followersCount = following.followersCount - 1);
			}

			flashInsert(success="User unfollowed");
		} else {
			flashInsert(error="Error unfollowing user");
		}

		redirectTo(back=true, default="{controller='users',action='show',key='#params.userId#'}");
	}

	/**
	 * Require authentication filter
	 */
	private function requireAuth() {
		if (!structKeyExists(session, "authenticated") || !session.authenticated) {
			flashInsert(error="You must be logged in");
			redirectTo(controller="sessions", action="new");
		}
	}
}
