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

			it("strips semicolons and comment markers from injection attempts", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "'; DROP TABLE users; --"});

				// semicolons stripped, -- stripped, then quotes escaped
				expect(result["1"]).toBe("'' DROP TABLE users ");
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

			it("escapes backslash-quote bypass attempts and strips comments", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "test\' OR 1=1 --"});

				// -- stripped, then backslash escaped, then quote escaped
				expect(result["1"]).toBe("test\\'' OR 1=1 ");
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

			it("strips SQL line comment sequences", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "admin-- comment"});

				expect(result["1"]).toBe("admin comment");
			});

			it("strips SQL block comment markers", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "admin/* injected */value"});

				expect(result["1"]).toBe("admin injected value");
			});

			it("strips semicolons to prevent stacked queries", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "value; DROP TABLE users"});

				expect(result["1"]).toBe("value DROP TABLE users");
			});

			it("handles all dangerous patterns combined", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": Chr(0) & "val'; DROP TABLE x;/* comment */--end"});

				// null bytes stripped, -- stripped, /* */ stripped, ; stripped, \ escaped, ' escaped
				expect(result["1"]).toBe("val'' DROP TABLE x comment end");
			});

			it("strips UNION keyword from injection attempts", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "foo UNION SELECT password FROM users"});

				expect(result["1"]).notToInclude("UNION");
			});

			it("strips EXEC and EXECUTE keywords", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "EXEC xp_cmdshell"});

				expect(result["1"]).notToInclude("EXEC");
				expect(result["1"]).notToInclude("xp_");
			});

			it("strips BENCHMARK and SLEEP keywords", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "BENCHMARK(10000000,SHA1('test'))"});

				expect(result["1"]).notToInclude("BENCHMARK");

				var result2 = m.$sanitizeScopeHandlerArgs({"1": "SLEEP(5)"});

				expect(result2["1"]).notToInclude("SLEEP");
			});

			it("does not strip partial keyword matches in normal values", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "executor"});

				// "executor" should remain because EXEC is not a whole-word match
				expect(result["1"]).toBe("executor");
			});

			it("strips WAITFOR and DELAY keywords from time-based injection", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "WAITFOR DELAY ''00:00:05''"});

				expect(result["1"]).notToInclude("WAITFOR");
				expect(result["1"]).notToInclude("DELAY");
			});

			it("strips INTO OUTFILE from file-write injection", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "test'' INTO OUTFILE ''/tmp/dump"});

				expect(result["1"]).notToInclude("INTO OUTFILE");
			});

			it("strips LOAD_FILE function from file-read injection", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "LOAD_FILE(''/etc/passwd'')"});

				expect(result["1"]).notToInclude("LOAD_FILE");
			});

			it("strips CHAR function from encoding bypass injection", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "CHAR(0x41)"});

				expect(result["1"]).notToInclude("CHAR(");
			});

			it("does not strip DELAY or WAITFOR as partial word matches", () => {
				var m = application.wo.model("author");
				var result = m.$sanitizeScopeHandlerArgs({"1": "delayed"});

				expect(result["1"]).toBe("delayed");

				var result2 = m.$sanitizeScopeHandlerArgs({"1": "waitforward"});

				expect(result2["1"]).toBe("waitforward");
			});

		});

	}

}
