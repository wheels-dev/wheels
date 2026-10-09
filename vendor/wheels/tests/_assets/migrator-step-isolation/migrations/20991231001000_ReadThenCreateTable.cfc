/**
 * A migration step that reads before it changes the schema (MigrationStepIsolationSpec). On
 * CockroachDB that fails inside a transaction at a weak isolation level.
 */
component extends="wheels.migrator.Migration" {

	function up() {
		queryExecute("SELECT COUNT(*) AS cnt FROM #application.wheels.migratorTableName#", {}, {datasource = $migratorDataSource()});
		local.t = createTable(name = "migrator_isolation_items");
		local.t.string(columnNames = "name");
		local.t.create();
		addIndex(table = "migrator_isolation_items", columnNames = "name", indexName = "idx_migrator_isolation_name");
	}

	function down() {
		dropTable("migrator_isolation_items");
	}

}
