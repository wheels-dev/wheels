component extends="Model" {

	public void function config() {
		table("_c_o_r_e_shops");
		setPrimaryKey("shopid");
		property(name = "id", sql = "_c_o_r_e_shops.shopid");
		belongsTo(name = "city", foreignKey = "citycode");
		hasmany(name = "trucks", foreignKey = "shopid");
	}

}
