component extends="Model" {

	function config() {
		table("authors");
		property(name = "selectArgDefault", sql = "id");
		property(name = "selectArgTrue", sql = "id", select = true);
		property(name = "selectArgFalse", sql = "id", select = false);
	}

}
