component extends="Model" {

	// String primary key, for nested-property ownership checks where "01" and "1"
	// are different parents.
	function config() {
		table("c_o_r_e_codeparents");
		hasMany(name = "codeChildren", foreignKey = "parentcode");
		nestedProperties(associations = "codeChildren", allowDelete = true);
	}

}
