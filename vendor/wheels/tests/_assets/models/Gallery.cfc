component extends="Model" {

	function config() {
		table("_c_o_r_e_galleries");
		belongsTo(name = "user", modelName = "user", foreignKey = "userid");
		hasMany(name = "photos", modelName = "photo", foreignKey = "galleryid");
		nestedProperties(associations = "photos", allowDelete = "true");
		validatesPresenceOf("title");
	}

}
