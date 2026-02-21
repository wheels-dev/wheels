component extends="wheels.tests.Test" {

	function test_sentence_should_titleize() {
		local.controller = controller(name = "dummy");
		local.args = {};
		local.args.word = "this is a test to see if this works or not.";
		result = local.controller.titleize(argumentcollection = local.args);
		expected = "This Is A Test To See If This Works Or Not.";
		assert(!Compare(result, expected));
	}

}
