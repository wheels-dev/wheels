component extends="Model" {

	function config() {
		settablenameprefix("c_o_r_e_tbl");
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
		if(findNoCase("Oracle",local.db)){
			property(name = "firstLetter", sql = "SUBSTR(c_o_r_e_tblusers.username, 1, 1)");
		} else {
			property(name = "firstLetter", sql = "SUBSTRING(c_o_r_e_tblusers.username, 1, 1)");
		}
		property(name = "groupCount", sql = "COUNT(c_o_r_e_tblusers.id)");
	}

}
