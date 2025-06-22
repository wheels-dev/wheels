component extends="Model" {

	function config() {
		hasMany(name = "shops", foreignKey = "citycode");
		property(name = "id", column = "countyid");
	}

}
