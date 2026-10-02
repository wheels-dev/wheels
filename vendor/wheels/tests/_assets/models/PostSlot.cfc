component extends="Model" {

	// Composite primary key (postid, slotnumber) where `slotnumber` is not a foreign
	// key: the nested-properties PK-clearing must still drop a posted slotnumber.
	function config() {
		table("c_o_r_e_postslots");
		belongsTo("post");
	}

}
