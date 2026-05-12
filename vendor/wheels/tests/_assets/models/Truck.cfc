component extends="Model" {

	public void function config() {
		table("c_o_r_e_trucks");
		belongsTo(name = "shop", foreignKey = "shopid");
	}

}
