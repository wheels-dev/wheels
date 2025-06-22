component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_dropView_drops_view() {
		viewName = "dbm_dropview";
		// only supported with these adapters
		if (ListFindNoCase("MicrosoftSQLServer", migration.adapter.adapterName())) {
			v = migration.createView(name = viewName);
			v.selectStatement(sql = "SELECT * FROM users");
			v.create();
			info = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
			created = $query(
				query = info,
				dbtype = "query",
				sql = "SELECT * FROM query WHERE table_name = '#viewName#' AND table_type = 'VIEW'"
			);

			migration.dropView(viewName);
			info = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
			dropped = $query(
				query = info,
				dbtype = "query",
				sql = "SELECT * FROM query WHERE table_name = '#viewName#' AND table_type = 'VIEW'"
			);

			assert("created.recordCount eq 1");
			assert("dropped.recordCount eq 0");
		}
	}

}
