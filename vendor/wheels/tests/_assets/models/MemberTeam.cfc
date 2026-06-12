component extends="Model" {

	function config() {
		table("c_o_r_e_memberteams");
		belongsTo("member");
		belongsTo("team");
	}

}
