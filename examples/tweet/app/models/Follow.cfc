component extends="Model" {

	function config() {
		table("follows");
		setPrimaryKey("id");

		// Associations
		belongsTo(name="follower", foreignKey="followerId", modelName="User");
		belongsTo(name="following", foreignKey="followingId", modelName="User");

		// Validations
		validatesPresenceOf(properties="followerId,followingId");
		validatesUniquenessOf(properties="followerId", scope="followingId");
		validate(methods="preventSelfFollow");
	}

	function preventSelfFollow() {
		if (structKeyExists(this, "followerId") && structKeyExists(this, "followingId") && this.followerId == this.followingId) {
			addError(property="followerId", message="You cannot follow yourself");
		}
	}

}