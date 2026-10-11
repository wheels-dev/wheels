component extends="Model" {

	function config() {
		table("c_o_r_e_authors");
		hasMany(name = "depPosts", modelName = "depPost", foreignKey = "authorId", dependent = "delete");
	}

}
