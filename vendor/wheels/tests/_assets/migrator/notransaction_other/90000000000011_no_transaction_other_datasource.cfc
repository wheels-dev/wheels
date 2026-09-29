component extends="wheels.migrator.Migration" hint="opts out of the per-step transaction, then runs raw SQL on a second datasource (issue 3772)" {

	this.useTransaction = false;

	function up() {
		queryExecute("SELECT 1 AS x", {}, {datasource: "wheelstestdb_sqlite_tenant_b"});
		announce("raw SQL on a second datasource, without a transaction");
	}

	function down() {
	}

}
