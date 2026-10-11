component extends="Model" {

	// Backs polymorphicForeignTypeSpec: a polymorphic child on an underscore-shaped schema
	// (notable_id / notable_type), so both columns are named explicitly.
	function config() {
		table("c_o_r_e_upolynotes");
		belongsTo(name = "notable", polymorphic = true, foreignKey = "notable_id", foreignType = "notable_type");
	}

}
