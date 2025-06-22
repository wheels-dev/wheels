component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_createView_generates_view() {
		viewName = "dbm_createview";
		// only supported with these adapters
		if (ListFindNoCase("MicrosoftSQLServer", migration.adapter.adapterName())) {
			v = migration.createView(name = viewName);
			v.selectStatement(sql = "SELECT * FROM users");
			v.create();

			info = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
			migration.dropView(viewName);

			actual = $query(
				query = info,
				dbtype = "query",
				sql = "SELECT * FROM query WHERE table_name = '#viewName#' AND table_type = 'VIEW'"
			);

			assert("actual.recordCount eq 1");
		}
	}

}
