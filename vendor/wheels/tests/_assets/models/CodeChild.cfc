component extends="Model" {

	function config() {
		table("c_o_r_e_codechildren");
		belongsTo(name = "codeParent", foreignKey = "parentcode");
	}

}
