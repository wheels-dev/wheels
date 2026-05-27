component extends="wheels.migrator.Migration" hint="issue ##2789 repro — seed a tag via Model.create() inside up()" {

	function up() {
		// Issue #2789 repro: model().create() inside up() must persist after the outer transaction commits.
		model("Tag").create(name = "issue2789_via_model_create");

		// Capture the flag's value during up() so the spec can assert the migrator set it.
		request.$issue2789FlagDuringUp = (
			StructKeyExists(request, "$wheelsTransactionWrapper")
			&& request.$wheelsTransactionWrapper
		);
	}

	function down() {
		// Issue #2789: raw queryExecute avoids nested transaction; safe across all adapters.
		removeRecord(table = "c_o_r_e_tags", where = "name = 'issue2789_via_model_create'");
	}

}
