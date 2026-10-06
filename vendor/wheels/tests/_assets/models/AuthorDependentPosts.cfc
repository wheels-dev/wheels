component extends="Model" {

	function config() {
		table("c_o_r_e_authors");
		hasMany(name = "posts", modelName = "post", foreignKey = "authorId", dependent = "delete");
	}

}
