component extends="wheels.migrator.Migration" hint="announce-only up/down — hardener B1" {

	function up() {
		announce("announce only up");
	}

	function down() {
		announce("announce only down");
	}

}
