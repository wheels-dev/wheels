component extends="Model" {
	function config() {
		table("c_o_r_e_refchildren");
		belongsTo(name = "parent", modelName = "SeederSelfChild", foreignKey = "refparent_id");
	}
}
