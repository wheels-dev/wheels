component extends="Model" {

	function config() {
		hasMany("posts");
		hasOne("profile");
		/* crazy join to test the joinKey argument */
		belongsTo(name = "user", foreignKey = "firstName", joinKey = "firstName");
		beforeSave("callbackThatReturnsTrue");
		beforeDelete("callbackThatReturnsTrue");
		property(name = "firstName", label = "First name(s)", defaultValue = "Dave");
		property(name = "numberofitems", sql = "SELECT COUNT(id) FROM posts WHERE authorid = authors.id", select = false);
		property(name = "lastName", label = "Last name", defaultValue = "");
		nestedProperties(associations = "profile", allowDelete = true);
		validatesPresenceOf("firstName");
	}

	function callbackThatReturnsTrue() {
		return true;
	}

}
