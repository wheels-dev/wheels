// An explicit foreignType with a derived foreignKey: only the key resolves against the schema.
component extends="Model" {

	function config() {
		table("c_o_r_e_uautonotes");
		belongsTo(name = "notable", polymorphic = true, foreignType = "notable_type");
	}

}
