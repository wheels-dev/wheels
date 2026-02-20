component extends="wheels.tests.Test" {

	function setup() {
		results = {};
	}

	function test_deobfuscate_eb77359232() {
		results.param = deobfuscateParam("eb77359232");
		assert("results.param IS '999999999'");
	}

	function test_deobfuscate_9b1c6() {
		results.param = deobfuscateParam("9b1c6");
		assert("results.param IS 1");
	}

	function test_deobfuscate_ac10a() {
		results.param = deobfuscateParam("ac10a");
		assert("results.param IS 99");
	}

	function test_deobfuscate_b226582() {
		results.param = deobfuscateParam("b226582");
		assert("results.param IS 15765");
	}

	function test_deobfuscate_c06d44215() {
		results.param = deobfuscateParam("c06d44215");
		assert("results.param IS 69247541");
	}

	function test_becca2515_should_not_deobfuscate() {
		results.param = deobfuscateParam("becca2515");
		assert("results.param IS 'becca2515'");
	}

	function test_a15ba9_should_not_deobfuscate() {
		results.param = deobfuscateParam("a15ba9");
		assert("results.param IS 'a15ba9'");
	}

	function test_1111111111_should_not_deobfuscate() {
		results.param = deobfuscateParam("1111111111");
		assert("results.param IS '1111111111'");
	}

}
