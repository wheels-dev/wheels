component extends="Model" {

	function config() {
		settablenameprefix("tbl");
		table("users");
		local.db_info = $dbinfo(datasource = application.wheels.dataSourceName, type = "version");
		local.db = LCase(Replace(local.db_info.database_productname, " ", "", "all"));
		property(name = "firstLetter", sql = "SUBSTRING(tblusers.username, 1, 1)");
		property(name = "groupCount", sql = "COUNT(tblusers.id)");
	}

}
