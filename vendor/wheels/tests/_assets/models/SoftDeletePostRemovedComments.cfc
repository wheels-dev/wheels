component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
		hasMany(name = "comments", modelName = "comment", foreignKey = "postId", dependent = "removeAll");
	}

}
