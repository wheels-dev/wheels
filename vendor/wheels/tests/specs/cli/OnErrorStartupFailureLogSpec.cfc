/**
 * Every copy of public/Application.cfc writes the failure behind the minimal
 * "Wheels failed to initialize" page to wheels.log before rendering it
 * (#3671). The page tells the operator to check the server log, so an entry
 * has to exist, and it has to name the root cause: Adobe CF wraps a failure
 * inside an application event in an event-handler exception whose message
 * hides the real one.
 *
 * Structural spec (no runtime), like OnErrorTeardownGuardSpec: the fallback
 * lives in each app's Application.cfc, which the suite cannot drive without
 * tearing down the application.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("onError minimal fallback logs the startup failure (##3671)", () => {

			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc",
				"examples/starter-app/public/Application.cfc",
				"examples/tweet/public/Application.cfc"
			];

			for (var rel in targets) {
				(function(relPath) {
					it("logs the root cause before rendering the minimal page in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						var render = $functionBody(content, "\$renderMinimalError", relPath);
						var logPos = reFindNoCase("\$logStartupFailure\s*\(\s*arguments\.Exception", render);
						var outputPos = reFindNoCase("WriteOutput\s*\(", render);
						expect(logPos > 0 && logPos < outputPos).toBeTrue(
							relPath & " $renderMinimalError() must call $logStartupFailure(arguments.Exception, ...) "
							& "before it writes the page (issue ##3671)."
						);

						var logger = $functionBody(content, "\$logStartupFailure", relPath);
						expect(reFindNoCase("WriteLog\s*\(\s*file\s*=\s*""wheels""\s*,\s*type\s*=\s*""error""", logger) > 0).toBeTrue(
							relPath & " $logStartupFailure() must WriteLog(file=""wheels"", type=""error"", ...)."
						);
						expect(reFindNoCase("^\s*try\s*\{", logger) > 0).toBeTrue(
							relPath & " $logStartupFailure() must wrap its body in try/catch so logging never masks the error."
						);

						var cause = $functionBody(content, "\$startupFailureCause", relPath);
						expect(findNoCase("RootCause", cause) > 0).toBeTrue(
							relPath & " $startupFailureCause() must walk RootCause so Adobe's event-handler wrapper does not hide the cause."
						);
					});
				})(rel);
			}

		});

	}

	/** Body of the named function, found by brace counting. */
	private string function $functionBody(required string content, required string namePattern, required string relPath) {
		var match = reFindNoCase(
			"function\s+" & arguments.namePattern & "\s*\([^\)]*\)\s*\{",
			arguments.content,
			1,
			true
		);
		expect(match.len[1] > 0).toBeTrue(
			arguments.relPath & " should declare " & arguments.namePattern & "()."
		);
		var bodyStart = match.pos[1] + match.len[1];
		var depth = 1;
		var bodyEnd = bodyStart;
		var iEnd = len(arguments.content);
		for (var i = bodyStart; i <= iEnd; i++) {
			var ch = mid(arguments.content, i, 1);
			if (ch == "{") {
				depth++;
			} else if (ch == "}") {
				depth--;
				if (depth == 0) {
					bodyEnd = i - 1;
					break;
				}
			}
		}
		return mid(arguments.content, bodyStart, bodyEnd - bodyStart + 1);
	}

}
