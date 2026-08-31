/**
 * Asset for RocketUnitRunnerSpec: a legacy RocketUnit package where one test
 * passes and one throws, so the runner's error-handling path is exercised.
 */
component extends="wheels.Test" {

	function test01_passes() {
		assert("1 eq 1");
	}

	function test02_throws() {
		Throw(type = "Wheels.ProbeBoom", message = "deliberate boom");
	}

}
