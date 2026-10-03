component extends="Model" {

	function config() {
		table("c_o_r_e_bigvalues");
		property(name = "amountTotal", sql = "SUM(amount)", select = false, dataType = "bigint");
	}

}
