component extends="Model" {

	public void function config() {
		belongsTo(name = "shop", foreignKey = "shopid");
	}

}
