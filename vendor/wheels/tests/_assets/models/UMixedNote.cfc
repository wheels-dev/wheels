// An explicit foreignKey with a derived foreignType: only the type resolves against the schema.
component extends="Model" {

	function config() {
		table("c_o_r_e_uautonotes");
		belongsTo(name = "notable", polymorphic = true, foreignKey = "notable_id");
	}

}
