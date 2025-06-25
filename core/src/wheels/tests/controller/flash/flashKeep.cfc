component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_flashKeep_saves_flash_items() {
		run_flashKeep_saves_flash_items();
		_controller.$setFlashStorage("cookie");
		run_flashKeep_saves_flash_items();
	}

	/**
	 * HELPERS
	 */

	function run_flashKeep_saves_flash_items() {
		_controller.flashInsert(tony = "Petruzzi", per = "Djurner", james = "Gibson");
		_controller.flashKeep("per,james");
		_controller.$flashClear();
		assert('_controller.flashCount() eq 2');
		assert('!_controller.flashKeyExists("tony")');
		assert('_controller.flashKeyExists("per")');
		assert('_controller.flashKeyExists("james")');
		assert('_controller.flash("per") eq "Djurner"');
		assert('_controller.flash("james") eq "Gibson"');
	}

}
