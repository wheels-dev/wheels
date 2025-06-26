component extends="Model" {

	function config() {
		table("_c_o_r_e_authors");
		property(name = "selectArgDefault", sql = "id");
		property(name = "selectArgTrue", sql = "id", select = true);
		property(name = "selectArgFalse", sql = "id", select = false);
	}

}
