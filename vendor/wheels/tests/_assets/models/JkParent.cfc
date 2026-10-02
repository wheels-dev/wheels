component extends="Model" {

	// hasMany through a custom joinKey: children point at `code`, not at `id`.
	function config() {
		table("c_o_r_e_jkparents");
		hasMany(name = "jkChildren", modelName = "jkChild", foreignKey = "parentcode", joinKey = "code");
		nestedProperties(associations = "jkChildren", allowDelete = true);
	}

}
