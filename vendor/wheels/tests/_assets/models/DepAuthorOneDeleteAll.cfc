component extends="Model" {

	function config() {
		table("c_o_r_e_authors");
		hasOne(name = "depPost", modelName = "depPost", foreignKey = "authorId", dependent = "deleteAll");
	}

}
