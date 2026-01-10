component extends="Model" {

	function config() {
		table("tweets");
		setPrimaryKey("id");

		// Associations
		belongsTo(name="user");
		hasMany(name="likes");
		hasMany(name="replies", foreignKey="replyToTweetId", modelName="Tweet");
		belongsTo(name="replyToTweet", foreignKey="replyToTweetId", modelName="Tweet");

		// Validations
		validatesPresenceOf(properties="userId,content");
		validatesLengthOf(properties="content", minimum=1, maximum=280);

		// Callbacks
		beforeCreate("setDefaults");
	}

	function setDefaults() {
		if (!structKeyExists(this, "likesCount") || !len(this.likesCount)) {
			this.likesCount = 0;
		}
		if (!structKeyExists(this, "repliesCount") || !len(this.repliesCount)) {
			this.repliesCount = 0;
		}
		if (!structKeyExists(this, "retweetsCount") || !len(this.retweetsCount)) {
			this.retweetsCount = 0;
		}
	}

	function isLikedBy(required numeric userId) {
		var like = model("Like").findOne(
			where="userId = #arguments.userId# AND tweetId = #this.id#"
		);
		return isObject(like);
	}

}