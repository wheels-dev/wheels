component extends="Model" {

	function config() {
		table("c_o_r_e_authors");
		hasMany("posts");
		hasOne("profile");
		/* crazy join to test the joinKey argument */
		belongsTo(name = "user", foreignKey = "firstName", joinKey = "firstName");
		beforeSave("callbackThatReturnsTrue");
		beforeDelete("callbackThatReturnsTrue");
		property(name = "firstName", label = "First name(s)", defaultValue = "Dave");
		property(name = "numberofitems", sql = "SELECT COUNT(id) FROM c_o_r_e_posts WHERE authorid = c_o_r_e_authors.id", select = false);
		property(name = "lastName", label = "Last name", defaultValue = "");
		nestedProperties(associations = "profile", allowDelete = true);
		validatesPresenceOf("firstName");
	}

	function callbackThatReturnsTrue() {
		return true;
	}

	// #4429 rollback-cache probe: inside a transaction, write (uncommitted) then read — caching the
	// uncommitted row — and return false so the transaction rolls back. The spec then checks that the
	// phantom row is not still served from the request cache after the rollback.
	public boolean function $cacheRollbackProbe4429() {
		this.update(firstName = "Phantom4429", transaction = "none");
		model("Author").findByKey(key = this.id);
		return false;
	}

}
