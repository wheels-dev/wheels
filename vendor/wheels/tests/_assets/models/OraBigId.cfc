component extends="Model" {

	function config() {
		table("c_o_r_e_orabigids");
		property(name = "counterTotal", sql = "SUM(counter)", select = false, dataType = "bigint");
	}

}
