component extends="Model" {

	function config() {
		table("c_o_r_e_cities");
		hasMany(name = "shops", foreignKey = "citycode");
		property(name = "id", column = "countyid");
	}

}
