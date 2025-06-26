component extends="wheels.tests.Test" {

	function setup() {
		results = {};
	}

	function test_obfuscate_999999999() {
		results.param = obfuscateParam("999999999");
		assert("results.param IS 'eb77359232'");
	}

	function test_obfuscate_0162823571() {
		results.param = obfuscateParam("0162823571");
		assert("results.param IS '0162823571'");
	}

	function test_obfuscate_1() {
		results.param = obfuscateParam("1");
		assert("results.param IS '9b1c6'");
	}

	function test_obfuscate_99() {
		results.param = obfuscateParam("99");
		assert("results.param IS 'ac10a'");
	}

	function test_obfuscate_15765() {
		results.param = obfuscateParam("15765");
		assert("results.param IS 'b226582'");
	}

	function test_obfuscate_69247541() {
		results.param = obfuscateParam("69247541");
		assert("results.param IS 'c06d44215'");
	}

	function test_obfuscate_0413() {
		results.param = obfuscateParam("0413");
		assert("results.param IS '0413'");
	}

	function test_per_should_not_obfuscate() {
		results.param = obfuscateParam("per");
		assert("results.param IS 'per'");
	}

	/* Lucee 6 does obfuscate this to 'a47ffffe32'
	function test_1111111111_should_not_obfuscate() {
		results.param = obfuscateParam("1111111111");
		assert("results.param IS '1111111111'");
	}*/

}