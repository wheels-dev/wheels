component extends="wheels.migrator.Migration" hint="Synthetic migration whose up() throws — exercises the migrateIndividual() rollback path." {

	function up() {
		throw(
			type    = "Wheels.Test.SyntheticFailure",
			message = "synthetic failure",
			detail  = "intentional failure to exercise the rollback path in migrateIndividual()"
		);
	}

	function down() {
	}

}
