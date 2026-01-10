component extends="Controller" {

	function config() {
		provides("html");
		filters(through="requireAuth");
	}

	/**
	 * Home feed - show tweets from followed users
	 */
	function index() {
		if (structKeyExists(session, "userId")) {
			// Get tweets from users the current user follows + their own tweets
			var followingIds = model("Follow").findAll(
				where="followerId = #session.userId#",
				select="followingId"
			);

			var userIds = [session.userId];
			if (followingIds.recordCount > 0) {
				for (var row in followingIds) {
					arrayAppend(userIds, row.followingId);
				}
			}

			var userIdList = arrayToList(userIds);

			tweets = model("Tweet").findAll(
				where="userId IN (#userIdList#)",
				order="createdAt DESC",
				include="user"
			);
		} else {
			// Guest users see all tweets
			tweets = model("Tweet").findAll(
				order="createdAt DESC",
				include="user"
			);
		}
	}

	/**
	 * Create a new tweet
	 */
	function create() {
		params.tweet.userId = session.userId;

		tweet = model("Tweet").create(params.tweet);

		if (tweet.valid()) {
			// Update user's tweet count
			var user = model("User").findByKey(session.userId);
			user.update(tweetsCount = user.tweetsCount + 1);

			flashInsert(success="Tweet posted successfully!");
			redirectTo(action="index");
		} else {
			flashInsert(error="Error posting tweet. Please check your input.");
			redirectTo(action="index");
		}
	}

	/**
	 * Delete a tweet
	 */
	function delete() {
		tweet = model("Tweet").findByKey(params.key);

		if (isObject(tweet) && tweet.userId == session.userId) {
			if (tweet.delete()) {
				// Update user's tweet count
				var user = model("User").findByKey(session.userId);
				if (user.tweetsCount > 0) {
					user.update(tweetsCount = user.tweetsCount - 1);
				}

				flashInsert(success="Tweet deleted successfully");
			} else {
				flashInsert(error="Error deleting tweet");
			}
		} else {
			flashInsert(error="You can only delete your own tweets");
		}

		redirectTo(action="index");
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
}
