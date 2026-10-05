component extends="Model" {

	function config() {
		table("c_o_r_e_uautopages");
		hasOne(name = "uAutoNote", as = "notable");
	}

}
