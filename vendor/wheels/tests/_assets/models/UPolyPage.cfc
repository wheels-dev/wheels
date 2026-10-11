component extends="Model" {

	// Backs polymorphicForeignTypeSpec: a hasOne owner of UPolyNote through `as = "notable"`.
	function config() {
		table("c_o_r_e_upolypages");
		hasOne(name = "uPolyNote", modelName = "UPolyNote", as = "notable", foreignKey = "notable_id", foreignType = "notable_type");
	}

}
