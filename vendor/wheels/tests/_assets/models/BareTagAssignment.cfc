component extends="Model" {

	// Composite primary key (postid, tagid) with a belongsTo for the parent only: tagid has
	// no belongsTo, so a nested form can't set it on a new row.
	function config() {
		table("c_o_r_e_tagassignments");
		belongsTo("post");
	}

}
