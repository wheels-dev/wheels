component extends="Model" {

	// joinType test fixture (#3936): posts with classifications joined as "left".
	function config() {
		table("c_o_r_e_posts");
		hasMany(name = "classifications", modelName = "classification", foreignKey = "postid", joinType = "left");
	}

}
