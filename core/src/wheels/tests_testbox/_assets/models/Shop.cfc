component extends="Model" {

	public void function config() {
		setPrimaryKey("shopid");
		property(name = "id", sql = "shops.shopid");
		belongsTo(name = "city", foreignKey = "citycode");
		hasmany(name = "trucks", foreignKey = "shopid");
	}

}
