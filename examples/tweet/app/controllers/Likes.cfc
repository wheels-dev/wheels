component extends="Controller" {

	function config() {
		provides("html");
		filters(through="requireAuth");
	}

	/**
	 * Like a tweet
	 */
	function create() {
		like = model("Like").create(
			userId = session.userId,
			tweetId = params.tweetId
		);

		if (like.valid()) {
			// Update tweet's like count
			tweet = model("Tweet").findByKey(params.tweetId);
			tweet.update(likesCount = tweet.likesCount + 1);

			flashInsert(success="Tweet liked!");
		} else {
			flashInsert(error="Error liking tweet");
		}

		redirectTo(back=true, default="{controller='tweets',action='index'}");
	}

	/**
	 * Unlike a tweet
	 */
	function delete() {
		like = model("Like").findOne(
			where="userId = #session.userId# AND tweetId = #params.tweetId#"
		);

		if (isObject(like) && like.delete()) {
			// Update tweet's like count
			tweet = model("Tweet").findByKey(params.tweetId);
			if (tweet.likesCount > 0) {
				tweet.update(likesCount = tweet.likesCount - 1);
			}

			flashInsert(success="Tweet unliked");
		} else {
			flashInsert(error="Error unliking tweet");
		}

		redirectTo(back=true, default="{controller='tweets',action='index'}");
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
