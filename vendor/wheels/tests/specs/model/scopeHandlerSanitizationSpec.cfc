component extends="wheels.WheelsTest" {

	function run() {

		describe("Tests that scope handler arguments are sanitized against SQL injection", () => {

			it("escapes single quotes in string arguments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "O'Brien"});

				expect(result["1"]).toBe("O''Brien");
			});

			it("escapes SQL injection attempt in arguments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "Djurner' OR '1'='1"});

				expect(result["1"]).toBe("Djurner'' OR ''1''=''1");
			});

			it("escapes DROP TABLE injection in arguments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "'; DROP TABLE users; --"});

				expect(result["1"]).toBe("''; DROP TABLE users; --");
			});

			it("leaves clean string arguments unchanged", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "Djurner"});

				expect(result["1"]).toBe("Djurner");
			});

			it("handles multiple arguments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "O'Brien", "2": "It's"});

				expect(result["1"]).toBe("O''Brien");
				expect(result["2"]).toBe("It''s");
			});

			it("preserves numeric arguments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": 42});

				expect(result["1"]).toBe(42);
			});

			it("preserves boolean arguments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": true});

				expect(result["1"]).toBeTrue();
			});

			it("preserves struct arguments without modification", () => {
				var m = application.wo.model("author");
				var inner = {foo: "bar'baz"};
				var result = m.$sanitizeScopeHandlerArgs({"1": inner});

				expect(result["1"]).toBeStruct();
				expect(result["1"].foo).toBe("bar'baz");
			});

			it("preserves array arguments without modification", () => {
				var m = application.wo.model("author");
				var arr = ["it's", "test"];
				var result = m.$sanitizeScopeHandlerArgs({"1": arr});

				expect(result["1"]).toBeArray();
			});

			it("handles empty arguments struct", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({});

				expect(result).toBeStruct();
				expect(structIsEmpty(result)).toBeTrue();
			});

			it("handles empty string arguments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": ""});

				expect(result["1"]).toBe("");
			});

			it("escapes backslashes in string arguments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "test\path"});

				expect(result["1"]).toBe("test\\path");
			});

			it("escapes backslash-quote bypass attempts", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "test\' OR 1=1 --"});

				expect(result["1"]).toBe("test\\'' OR 1=1 --");
			});

			it("strips null bytes from string arguments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "test" & Chr(0) & "injection"});

				expect(result["1"]).toBe("testinjection");
			});

			it("handles combined backslash quote and null byte attacks", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": Chr(0) & "O\'Brien"});

				expect(result["1"]).toBe("O\\''Brien");
			});


		});

	}

}
