component extends="Model" {

	// Backs polymorphicForeignTypeSpec: a hasMany owner of UPolyNote through `as = "notable"`.
	function config() {
		table("c_o_r_e_upolyposts");
		hasMany(name = "uPolyNotes", modelName = "UPolyNote", as = "notable", foreignKey = "notable_id", foreignType = "notable_type");
		nestedProperties(associations = "uPolyNotes");
	}

}
