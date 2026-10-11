component extends="Model" {

	function config() {
		table("c_o_r_e_uautonotes");
		belongsTo(name = "notable", polymorphic = true);
	}

}
