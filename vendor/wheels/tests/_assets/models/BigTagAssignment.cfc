component extends="Model" {

	// Composite primary key (postid BIGINT, tagid) join model.
	function config() {
		table("c_o_r_e_bigtagassignments");
		belongsTo(name = "bigKeyPost", modelName = "bigKeyPost", foreignKey = "postid");
		belongsTo("tag");
	}

}
