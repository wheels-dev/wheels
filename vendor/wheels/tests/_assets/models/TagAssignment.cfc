component extends="Model" {

	// Composite-primary-key join model (postid, tagid) for hasManyCheckBox
	// nested-property specs (#3884).
	function config() {
		table("c_o_r_e_tagassignments");
		belongsTo("post");
		belongsTo("tag");
	}

}
