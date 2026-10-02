component extends="Model" {

	function config() {
		table("c_o_r_e_jkchildren");
		belongsTo(name = "jkParent", modelName = "jkParent", foreignKey = "parentcode", joinKey = "code");
	}

}
