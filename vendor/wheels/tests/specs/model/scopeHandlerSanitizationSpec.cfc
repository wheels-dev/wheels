component extends="wheels.WheelsTest" {

	function run() {

		describe("Tests that scope handler arguments are escaped (not rewritten) for quoted SQL interpolation", () => {

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

			it("preserves SQL keywords in legitimate values", () => {
				var m = application.wo.model("author");

				expect(m.$sanitizeScopeHandlerArgs({"1": "Union Pacific"})["1"]).toBe("Union Pacific");
				expect(m.$sanitizeScopeHandlerArgs({"1": "Estimated delay"})["1"]).toBe("Estimated delay");
				expect(m.$sanitizeScopeHandlerArgs({"1": "executor"})["1"]).toBe("executor");
				expect(m.$sanitizeScopeHandlerArgs({"1": "Benchmark Capital"})["1"]).toBe("Benchmark Capital");
			});

			it("preserves comment markers and semicolons (quote-escaping only)", () => {
				var m = application.wo.model("author");

				expect(m.$sanitizeScopeHandlerArgs({"1": "admin-- comment"})["1"]).toBe("admin-- comment");
				expect(m.$sanitizeScopeHandlerArgs({"1": "value; DROP TABLE users"})["1"]).toBe("value; DROP TABLE users");
				expect(m.$sanitizeScopeHandlerArgs({"1": "admin/* injected */value"})["1"]).toBe("admin/* injected */value");
			});

			it("still escapes quotes in values containing keywords", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "Djurner' OR '1'='1"});

				expect(result["1"]).toBe("Djurner'' OR ''1''=''1");

				var result2 = m.$sanitizeScopeHandlerArgs({"1": "x' UNION SELECT password FROM users --"});

				expect(result2["1"]).toBe("x'' UNION SELECT password FROM users --");
			});

		});

	}

}
