component extends="wheels.migrator.Migration" hint="issue ##4134: counts how often up() runs, so the migration lock spec can check each migration ran once" {

	function up() {
		if (!StructKeyExists(application, "$migrationLockSpecRuns")) {
			application.$migrationLockSpecRuns = 0;
		}
		application.$migrationLockSpecRuns++;
	}

	function down() {
	}

}
