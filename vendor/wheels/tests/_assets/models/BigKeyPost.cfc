component extends="Model" {

	// BIGINT primary key assigned explicitly (19 digits), for nested struct keys above 2^31.
	function config() {
		table("c_o_r_e_bigkeyposts");
		hasMany(name = "bigTagAssignments", modelName = "bigTagAssignment", foreignKey = "postid");
		nestedProperties(associations = "bigTagAssignments", allowDelete = true);
	}

}
