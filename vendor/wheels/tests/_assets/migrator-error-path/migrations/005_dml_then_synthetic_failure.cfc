component extends="wheels.migrator.Migration" hint="Synthetic migration whose up() writes DML then throws — exercises redoMigration()'s transactional rollback." {

	function up() {
		// DML write that must be rolled back when the throw below aborts the
		// migration. Uses model().create() so the write participates in the
		// migrator's outer transaction (same pattern as the issue #2789 fixture).
		model("Tag").create(name = "redo_rollback_probe");
		throw(
			type    = "Wheels.Test.SyntheticFailure",
			message = "synthetic failure after DML",
			detail  = "intentional failure to exercise the transactional rollback in redoMigration()"
		);
	}

	function down() {
		// No-op: redoMigration() calls down() before up(); there is nothing to tear down.
	}

}
