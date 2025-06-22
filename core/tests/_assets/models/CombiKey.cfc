component extends="Model" {

	function config() {
		belongsTo("User");
		validatesPresenceOf("id1,id2");
		validatesUniquenessOf(property = "id1", scope = "id2");
	}

}
