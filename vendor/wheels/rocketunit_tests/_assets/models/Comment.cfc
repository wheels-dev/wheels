component extends="Model" {

	function config() {
		table("c_o_r_e_comments");
		belongsTo("post");
	}

}
