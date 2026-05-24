component extends="wheels.migrator.Migration" hint="issue ##2789 repro — seed a tag via Model.create() inside up()" {

	function up() {
		// Issue #2789 repro: calling model().create() inside up() must persist
		// the row when the migrator's outer transaction commits. Without the
		// fix, Wheels Model's default transaction='commit' opens a nested
		// cftransaction whose savepoint/commit semantics collide with the
		// migrator's outer transaction (MSSQL silently rolls the row back).
		model("Tag").create(name = "issue2789_via_model_create");

		// Also capture the flag's value during up() so the spec can assert
		// the migrator actually set it. We stash on application scope (request
		// is per-call) so the spec can read it after migrateTo returns.
		application.$issue2789FlagDuringUp = (
			StructKeyExists(request, "$wheelsTransactionWrapper")
			&& request.$wheelsTransactionWrapper
		);
	}

	function down() {
		// removeRecord uses raw queryExecute (no nested transaction), safe for
		// every adapter regardless of whether the fix is in place.
		removeRecord(table = "c_o_r_e_tags", where = "name = 'issue2789_via_model_create'");
	}

}
