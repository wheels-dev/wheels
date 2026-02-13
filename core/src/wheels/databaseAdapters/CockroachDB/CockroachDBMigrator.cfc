component extends="wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator" {

	/**
	 * name of database adapter
	 */
	public string function adapterName() {
		return "CockroachDB";
	}

}
