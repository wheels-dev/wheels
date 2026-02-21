component extends="wheels.tests.Test" {

	function test_phrase_should_word_truncate() {
		local.controller = controller(name = "dummy");
		local.args = {};
		local.args.text = "CFWheels is a framework for ColdFusion";
		local.args.length = "4";
		result = local.controller.wordTruncate(argumentcollection = local.args);
		expected = "CFWheels is a framework...";
		assert("result eq expected");
	}

}
