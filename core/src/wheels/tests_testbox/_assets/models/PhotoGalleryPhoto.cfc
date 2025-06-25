component extends="Model" {

	function config() {
		property(name = "DESCRIPTION1", column = "description");
		belongsTo(name = "photogallery", modelName = "photogallery", foreignKey = "photogalleryid");
	}

}
