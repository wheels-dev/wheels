component extends="Model" {

	function config() {
		// Associations
		belongsTo(name="role", foreignKey="roleid");
        belongsTo(name="permission", foreignKey="permissionid");

		// Properties
		validatesPresenceOf("roleid,permissionid");
	}

}
