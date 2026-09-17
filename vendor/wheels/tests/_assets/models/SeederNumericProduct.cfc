component extends="Model" {
	function config() {
		table("c_o_r_e_posts");
		property(name = "price", column = "averagerating");
		validatesNumericalityOf("price");
	}
}
