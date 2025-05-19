component extends="Model" {

	function config() {
		table("_c_o_r_e_users");
		property(name = "birthDay", column = "birthday");
		automaticValidations(true);
	}

}
