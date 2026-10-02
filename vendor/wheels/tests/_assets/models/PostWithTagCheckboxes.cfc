component extends="Model" {

	// Parent for the hasManyCheckBox join-model specs (#3884, #3885): one
	// composite-key join model and one surrogate-id join model, both nested.
	function config() {
		table("c_o_r_e_posts");
		hasMany(name = "tagAssignments", foreignKey = "postid");
		hasMany(name = "classifications", foreignKey = "postid");
		hasMany(name = "postSlots", foreignKey = "postid");
		hasMany(name = "bareTagAssignments", modelName = "bareTagAssignment", foreignKey = "postid");
		nestedProperties(associations = "tagAssignments,classifications,postSlots,bareTagAssignments", allowDelete = true);
	}

}
