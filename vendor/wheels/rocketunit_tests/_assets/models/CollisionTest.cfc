component extends="Model" {

	function config() {
		table("c_o_r_e_collisiontests");
		afterFind("afterFindCallback");
	}

	function afterFindCallback() {
		arguments.method = "done";
		return arguments;
	}

}
