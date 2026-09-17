/**
 * Console command contracts.
 *
 * `consoleExec` is private and makes a real HTTP call, so reserved-scope
 * cover stays source-level (see ReloadCommandSpec). Exit-code and model
 * validation wiring is asserted both at source (print-then-throw, no
 * silent `return ""` on ping failure) and by exercising the public
 * `$consoleModelHasErrors` helper.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Module.cfc::consoleExec — reserved-scope shadowing", () => {

			it("does not declare a bare `url` parameter that the URL scope would shadow", () => {
				var pattern = "function consoleExec\(\s*required\s+string\s+url\b";
				expect(reFind(pattern, variables.moduleSource) > 0).toBeFalse(
					"consoleExec must not use `url` as a parameter name — it collides with the CFML URL scope and breaks /models, /routes, /version, /datasource (issue ##2582)."
				);
			});

			it("does not pass a bare `url` reference into makeHttpPost", () => {
				expect(variables.moduleSource).notToInclude(
					"makeHttpPost(url,",
					"makeHttpPost must receive an unshadowed string argument; bare `url` resolves to the URL scope struct on a request."
				);
			});

		});

		describe("Module.cfc::console — non-zero exit on eval / connect failure", () => {

			it("throws Wheels.ConsoleFailed from $consoleFail instead of returning empty on ping failure", () => {
				expect(variables.moduleSource).toInclude("Wheels.ConsoleFailed");
				expect(variables.moduleSource).toInclude("$consoleFail(");
				expect(reFindNoCase("function\s+\$consoleFail\s*\(", variables.moduleSource)).toBeGT(0);
			});

			it("console() does not return empty string after a failed ping", () => {
				var startIdx = reFindNoCase("(?m)^[ \t]*public\s+string\s+function\s+console\s*\(", variables.moduleSource);
				expect(startIdx).toBeGT(0);
				var nextFn = reFindNoCase("(?m)^[ \t]*(public|private)\s+\w+\s+function\s+", variables.moduleSource, startIdx + 1);
				var bodyLen = nextFn > startIdx ? nextFn - startIdx : 2500;
				var body = mid(variables.moduleSource, startIdx, bodyLen);
				expect(body).toInclude("$consoleFail(");
				expect(body).toInclude("One or more console expressions failed");
				expect(find("return """";", body)).toBeGT(0, "successful sessions still return empty string");
				// The pre-fix pattern: print "Console connection failed" then `return ""`.
				expect(reFind("Console connection failed[\s\S]{0,200}return\s+"""";", body)).toBe(0);
			});

			it("consoleExec returns boolean so the REPL can record a failed expression", () => {
				expect(reFindNoCase("private\s+boolean\s+function\s+consoleExec\s*\(", variables.moduleSource)).toBeGT(0);
			});

			it("throws on EOF when any expression failed", () => {
				expect(variables.moduleSource).toInclude("if (hadError)");
				expect(variables.moduleSource).toInclude("One or more console expressions failed");
			});

		});

		describe("$consoleModelHasErrors — invalid create is a failed expression", () => {

			it("is true when the model payload reports _hasErrors", () => {
				expect(mod.$consoleModelHasErrors('{"title":"Console Post","_hasErrors":true,"_errors":["publishedAt: [empty]"]}')).toBeTrue();
			});

			it("is false when the model payload reports no errors", () => {
				expect(mod.$consoleModelHasErrors('{"title":"Console Post","_hasErrors":false,"_key":1}')).toBeFalse();
			});

			it("is false when the payload has no _hasErrors key (new() / finders)", () => {
				expect(mod.$consoleModelHasErrors('{"title":"Console Post","_isNew":true}')).toBeFalse();
			});

			it("is false for non-JSON", () => {
				expect(mod.$consoleModelHasErrors("not-json")).toBeFalse();
			});

		});

	}

}
