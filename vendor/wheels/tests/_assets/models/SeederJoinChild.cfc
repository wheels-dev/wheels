component extends="Model" {
	function config() {
		table("c_o_r_e_refchildren");
		property(name = "ownerCode", column = "refparent_id");
		belongsTo(name = "owner", modelName = "SeederJoinParent", foreignKey = "ownerCode", joinKey = "referenceCode");
	}
}
