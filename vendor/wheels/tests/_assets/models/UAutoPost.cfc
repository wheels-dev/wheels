component extends="Model" {

	function config() {
		table("c_o_r_e_uautoposts");
		hasMany(name = "uAutoNotes", as = "notable");
		nestedProperties(associations = "uAutoNotes");
	}

}
