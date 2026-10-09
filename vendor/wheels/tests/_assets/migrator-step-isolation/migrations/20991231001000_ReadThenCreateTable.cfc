/**
 * A migration step that reads and writes through a model before it changes the schema
 * (MigrationStepIsolationSpec). On CockroachDB that fails inside a transaction at a weak
 * isolation level; the model calls join the step's transaction.
 */
component extends="wheels.migrator.Migration" {

	function up() {
		queryExecute("SELECT COUNT(*) AS cnt FROM #application.wheels.migratorTableName#", {}, {datasource = $migratorDataSource()});
		local.tag = model("Tag").create(name = "migrator_isolation_tag");
		local.tag.name = "migrator_isolation_tag_saved";
		local.tag.save();
		local.t = createTable(name = "migrator_isolation_items");
		local.t.string(columnNames = "name");
		local.t.create();
		addIndex(table = "migrator_isolation_items", columnNames = "name", indexName = "idx_migrator_isolation_name");
	}

	function down() {
		dropTable("migrator_isolation_items");
		removeRecord(table = "c_o_r_e_tags", where = "name IN ('migrator_isolation_tag', 'migrator_isolation_tag_saved')");
	}

}
