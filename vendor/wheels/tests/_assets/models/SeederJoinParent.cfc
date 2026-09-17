component extends="Model" {
	function config() {
		table("c_o_r_e_refparents");
		property(name = "referenceCode", column = "id");
		setPrimaryKey("name");
	}
}
