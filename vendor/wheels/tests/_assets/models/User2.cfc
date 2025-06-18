component extends="Model" {

	function config() {
		settablenameprefix("_c_o_r_e_tbl");
		table("users");
		local.db_info = $dbinfo(datasource = application.wheels.dataSourceName, type = "version");
		local.db = LCase(
			Replace(
				local.db_info.database_productname,
				" ",
				"",
				"all"
			)
		);
		property(name = "firstLetter", sql = "SUBSTRING(_c_o_r_e_tblusers.username, 1, 1)");
		property(name = "groupCount", sql = "COUNT(_c_o_r_e_tblusers.id)");
	}

}
