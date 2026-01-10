component extends="Model" {

	function config() {
		table("likes");
		setPrimaryKey("id");

		// Associations
		belongsTo(name="user");
		belongsTo(name="tweet");

		// Validations
		validatesPresenceOf(properties="userId,tweetId");
		validatesUniquenessOf(properties="userId", scope="tweetId");
	}

}