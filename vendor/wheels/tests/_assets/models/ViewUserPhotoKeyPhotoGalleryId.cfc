component extends="Model" {

	function config() {
		table("_c_o_r_e_userphotos");
		setPrimaryKey("galleryid");
		hasMany(name = "photos", modelName = "photo", foreignKey = "galleryid");
	}

}
