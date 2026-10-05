/**
 * Every copy of public/Application.cfc writes the failure behind the minimal
 * "Wheels failed to initialize" page to wheels.log before rendering it, and
 * shows the root cause on the page only when showErrorInformation is on
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
						$requireRepoPath("cli/lucli/templates/app/public/Application.cfc");
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

						// The page follows showErrorInformation: full detail only when it is
						// true, nothing when any copy of it is false, the bare message
						// only before startup set it (##3671).
						// Logged in every environment: before, and outside, the decision about the page.
						var decidePos = reFindNoCase("\$startupFailureShowDetail\s*\(\s*\)", render);
						expect(logPos > 0 && logPos < decidePos).toBeTrue(
							relPath & " $renderMinimalError() must log before deciding what the page shows, so production still logs."
						);
						expect(reFindNoCase("\$startupFailureFrames\s*\(", $functionBody(content, "\$logStartupFailure", relPath)) > 0).toBeTrue(
							relPath & " $logStartupFailure() must log the whole tag context via $startupFailureFrames()."
						);
						expect(reFindNoCase("\$startupFailureShowDetail\s*\(\s*\)", render) > 0).toBeTrue(
							relPath & " $renderMinimalError() must decide what to show via $startupFailureShowDetail()."
						);
						expect(reFindNoCase("showDetail\s*==\s*""yes""\s*\)\s*\{\s*WriteOutput\s*\(\s*\$startupFailureDetailHtml", render) > 0).toBeTrue(
							relPath & " $renderMinimalError() must render $startupFailureDetailHtml() only when showDetail is ""yes""."
						);
						expect(reFindNoCase("showDetail\s*==\s*""unknown""", render) > 0).toBeTrue(
							relPath & " $renderMinimalError() must show the bare message only while showErrorInformation is unknown."
						);
						var decide = $functionBody(content, "\$startupFailureShowDetail", relPath);
						expect(reFindNoCase("showErrorInformation\)\s*\{\s*return\s+""no""", decide) > 0).toBeTrue(
							relPath & " $startupFailureShowDetail() must answer ""no"" as soon as any showErrorInformation is false."
						);
						expect(findNoCase("""$wheels""", decide) > 0 && findNoCase("""wheels""", decide) > 0).toBeTrue(
							relPath & " $startupFailureShowDetail() must read both application.$wheels and application.wheels."
						);
						expect(reFindNoCase("catch\s*\(\s*any\s+\w+\s*\)\s*\{\s*return\s+""unknown""", decide) > 0).toBeTrue(
							relPath & " $startupFailureShowDetail() must answer ""unknown"" when the application scope can't be read (##3379)."
						);
						var detailHtml = $functionBody(content, "\$startupFailureDetailHtml", relPath);
						var rawConcats = reMatchNoCase("html\s*&=\s*""[^""]*""\s*&\s*(?!encodeForHTML)[a-z\$]", detailHtml);
						expect(arrayLen(rawConcats)).toBe(0,
							relPath & " $startupFailureDetailHtml() must HTML-encode every value it writes: " & arrayToList(rawConcats, " | ")
						);

						var cause = $functionBody(content, "\$startupFailureCause", relPath);
						expect(findNoCase("RootCause", cause) > 0).toBeTrue(
							relPath & " $startupFailureCause() must walk RootCause so Adobe's event-handler wrapper does not hide the cause."
						);
					});
				})(rel);
			}

		});

		describe("showErrorInformation is never briefly true in production (##3671)", () => {

			var source = fileRead(expandPath("/wheels/events/init/debugging.cfm"));

			it("derives it from the environment in its only assignment", () => {
				var assignments = reMatchNoCase("showErrorInformation\s*=[^;]*;", source);
				expect(arrayLen(assignments)).toBe(1, "debugging.cfm must assign showErrorInformation exactly once: " & arrayToList(assignments, " | "));
				expect(reFindNoCase("showErrorInformation\s*=\s*application\.\$wheels\.environment\s*!=\s*""production""", assignments[1]) > 0).toBeTrue(
					"showErrorInformation must be set from the environment, not true-then-overridden: " & assignments[1]
				);
			});

			it("reads nothing from the request, so no Host can throw or steer a setting", () => {
				expect(findNoCase("request.cgi", source)).toBe(0, "debugging.cfm must not derive settings from the request");
				expect(findNoCase("server_name", source)).toBe(0, "debugging.cfm must not derive settings from the Host");
			});

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
