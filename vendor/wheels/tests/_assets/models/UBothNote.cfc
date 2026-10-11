component extends="Model" {

	function config() {
		table("c_o_r_e_ubothnotes");
		belongsTo(name = "notable", polymorphic = true);
	}

}
