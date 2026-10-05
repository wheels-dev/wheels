component extends="wheels.migrator.Migration" hint="issue ##4134: a slow migration that counts its runs, for the two-instance race spec" {

	function up() {
		if (!StructKeyExists(application, "$migrationLockRaceRuns")) {
			application.$migrationLockRaceRuns = 0;
		}
		application.$migrationLockRaceRuns++;
		application.$migrationLockRaceInside = true;
		sleep(2500);
	}

	function down() {
	}

}
