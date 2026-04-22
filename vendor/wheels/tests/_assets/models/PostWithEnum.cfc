component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
		belongsTo("author");
		enum(property = "status", values = "draft,published,archived");
	}

}
