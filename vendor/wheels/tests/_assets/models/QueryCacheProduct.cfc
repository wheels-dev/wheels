component extends="Model" {

	/*
	 * Backs requestQueryCacheDataSourceSpec (#3844): the same finder issued against two
	 * datasources in one request. The spec creates `qc_products` in both the default test
	 * datasource and wheelstestdb_sqlite_tenant_b, with different rows in each.
	 */
	function config() {
		table("qc_products");
	}

}
