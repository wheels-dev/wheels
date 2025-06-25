component extends="wheels.tests.Test" {

	function test_encoding_nothing() {
		result = controller(name = "dummy").textAreaTag(
			name = "x",
			class = "x x",
			content = "Per's Test",
			encode = false,
			label = "Per's Label"
		);
		expected = "<label for=""x"">Per's Label<textarea class=""x x"" id=""x"" name=""x"">Per's Test</textarea></label>";
		assert("result eq expected");
	}

	function test_encoding_everything() {
		result = controller(name = "dummy").textAreaTag(
			name = "x",
			class = "x x",
			content = "Per's Test",
			encode = true,
			label = "Per's Label"
		);
		expected = "<label for=""x"">Per&##x27;s Label<textarea class=""x&##x20;x"" id=""x"" name=""x"">Per&##x27;s Test</textarea></label>";
		assert("result eq expected");
	}

	function test_encoding_only_attributes() {
		result = controller(name = "dummy").textAreaTag(
			name = "x",
			class = "x x",
			content = "Per's Test",
			encode = "attributes",
			label = "Per's Label"
		);
		expected = "<label for=""x"">Per's Label<textarea class=""x&##x20;x"" id=""x"" name=""x"">Per's Test</textarea></label>";
		assert("result eq expected");
	}

}
