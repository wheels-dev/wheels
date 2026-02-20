component extends="wheels.tests.Test" {

	function setup() {
		request.$wheelsMigrationOutput = "";
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_annouce_appends_announcement() {
		napalm = "I love the smell of napalm in the morning!";
		truth = "You can't handle the truth!";

		migration.announce(napalm);
		migration.announce(truth);

		actual = request.$wheelsMigrationOutput;
		expected = napalm & Chr(13) & truth & Chr(13);

		assert("actual eq expected");
	}

}
