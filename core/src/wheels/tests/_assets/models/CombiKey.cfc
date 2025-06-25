component extends="Model" {

	function config() {
		table("_c_o_r_e_combikeys");
		belongsTo("User");
		validatesPresenceOf("id1,id2");
		validatesUniquenessOf(property = "id1", scope = "id2");
	}

}
