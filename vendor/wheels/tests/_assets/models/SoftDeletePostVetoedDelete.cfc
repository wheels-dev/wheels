component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
		afterDelete("vetoDelete");
	}

	function vetoDelete() {
		return false;
	}

}
