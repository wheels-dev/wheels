component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		isACF2016 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2016;
		isPostgres = migration.adapter.adapterName() == "PostgreSQL";
	}

	function test_addIndex_creates_an_index() {
		if (isACF2016 && isPostgres) {
			return;
		}

		tableName = "dbm_addindex_tests";
		indexName = "idx_to_add";
		t = migration.createTable(name = tableName, force = true);
		t.integer(columnNames = "integercolumn");
		t.create();

		migration.addIndex(table = tableName, columnName = 'integercolumn', indexName = indexName);
		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "index");

		migration.dropTable(tableName);

		sql = "SELECT * FROM query WHERE index_name = '#indexName#'";

		actual = $query(query = info, dbtype = "query", sql = sql);
		assert("actual.recordCount eq 1");
		assert("actual.non_unique");
	}

	function test_add_index_on_mutiple_columns() {
		if (isACF2016 && isPostgres) {
			return;
		}

		tableName = "dbm_addindex_tests";
		indexName = "idx_to_add_to_multiple_columns";
		t = migration.createTable(name = tableName, force = true);
		t.integer(columnNames = "integercolumn,datecolumn");
		t.create();

		migration.addIndex(table = tableName, columnNames = 'integercolumn,datecolumn', indexName = indexName);
		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "index");

		migration.dropTable(tableName);

		sql = "SELECT * FROM query WHERE index_name = '#indexName#'";

		actual = $query(query = info, dbtype = "query", sql = sql);

		// Added the ListLen check here for CF2018 because its cfdbinfo behaves a little differently.
		// It returns the index for multiple columns in one record where as Lucee returns multiple.
		assert("actual.recordCount eq 2 OR ListLen(actual['column_name'][1]) IS 2");
		assert("actual.non_unique");
	}

	// todo: unique index

	// default index name

}
