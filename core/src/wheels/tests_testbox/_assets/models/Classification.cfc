component extends="Model" {

	function config() {
		table("_c_o_r_e_classifications");
		belongsTo("post");
		belongsTo("tag");
	}

}
