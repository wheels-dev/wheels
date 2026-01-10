component extends="Model" {

	function config() {
		table("users");
		setPrimaryKey("id");

		// Associations
		hasMany(name="tweets");
		hasMany(name="likes");
		hasMany(name="followers", foreignKey="followingId", modelName="Follow");
		hasMany(name="following", foreignKey="followerId", modelName="Follow");

		// Validations
		validatesPresenceOf(properties="username,email,passwordHash");
		validatesUniquenessOf(properties="username,email");
		validatesFormatOf(properties="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");
		validatesLengthOf(properties="username", minimum=3, maximum=50);
		validatesLengthOf(properties="bio", maximum=500, allowBlank=true);

		// Callbacks
		beforeCreate("setDefaults");
	}

	function setDefaults() {
		if (!structKeyExists(this, "followersCount") || !len(this.followersCount)) {
			this.followersCount = 0;
		}
		if (!structKeyExists(this, "followingCount") || !len(this.followingCount)) {
			this.followingCount = 0;
		}
		if (!structKeyExists(this, "tweetsCount") || !len(this.tweetsCount)) {
			this.tweetsCount = 0;
		}
	}

	function fullName() {
		return trim("#username#");
	}

	function isFollowing(required numeric userId) {
		var follow = model("Follow").findOne(
			where="followerId = #this.id# AND followingId = #arguments.userId#"
		);
		return isObject(follow);
	}

}