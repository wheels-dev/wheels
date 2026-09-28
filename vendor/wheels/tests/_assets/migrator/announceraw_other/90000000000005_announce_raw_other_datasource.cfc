component extends="wheels.migrator.Migration" hint="raw queryExecute on a second datasource then announce — the multi-database app shape" {

	function up() {
		queryExecute("SELECT 1 AS x", {}, {datasource: "wheelstestdb_sqlite_tenant_b"});
		announce("raw SQL on a second datasource, then announce");
	}

	function down() {
	}

}
