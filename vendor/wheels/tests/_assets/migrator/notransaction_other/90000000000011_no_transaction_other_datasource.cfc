component extends="wheels.migrator.Migration" hint="opts out of the per-step transaction, then runs raw SQL on a second datasource (issue 3772)" {

	this.useTransaction = false;

	function up() {
		// A write, not just a read, so the spec can prove where it landed: an
		// engine that routes statements to the wrong datasource would create
		// the table in the primary database instead.
		queryExecute("CREATE TABLE notx_probe_3772 (id INTEGER)", {}, {datasource: "wheelstestdb_sqlite_tenant_b"});
		announce("DDL on a second datasource, without a transaction");
	}

	function down() {
	}

}
