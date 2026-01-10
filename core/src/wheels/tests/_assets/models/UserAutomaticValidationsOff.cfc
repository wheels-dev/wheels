component extends="Model" {

	function config() {
		table("c_o_r_e_users");
		automaticValidations(true);
		property(name = "id", automaticValidations = false);
	}

}
