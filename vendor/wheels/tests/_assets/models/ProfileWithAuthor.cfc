component extends="Model" {

	// A profile that edits its author through nested properties (belongsTo).
	function config() {
		table("c_o_r_e_profiles");
		belongsTo(name = "author", foreignKey = "authorid");
		nestedProperties(associations = "author");
	}

}
