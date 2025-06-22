component extends="Model" {

	function config() {
		table("userphotos");
		setPrimaryKey("galleryid");
		hasMany(name = "photos", modelName = "photo", foreignKey = "galleryid");
	}

}
