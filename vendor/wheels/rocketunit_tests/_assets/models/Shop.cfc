component extends="Model" {

	public void function config() {
		table("c_o_r_e_shops");
		setPrimaryKey("shopid");
		property(name = "id", sql = "c_o_r_e_shops.shopid");
		belongsTo(name = "city", foreignKey = "citycode");
		hasmany(name = "trucks", foreignKey = "shopid");
		ignoredColumns(columns = ["isblackmarket"]);
	}

}
