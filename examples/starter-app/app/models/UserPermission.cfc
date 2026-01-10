component extends="Model" {

	function config() {
		// Associations
		belongsTo("user");
		belongsTo("permission");

		// Properties
		validatesPresenceOf("userid,permissionid");
	}

}
