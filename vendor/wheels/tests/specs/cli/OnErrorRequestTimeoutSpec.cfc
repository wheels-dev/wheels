/**
 * A request timeout (or any error once the application is already running)
 * reaches onError's minimal fallback through the catch after the main handler,
 * not the `!StructKeyExists(application, "wo")` startup path. In that case the
 * fallback must NOT say "Wheels failed to initialize" (the app did initialize),
 * and it must extend the request timeout before logging so the wheels.log entry
 * the page points at actually gets written after a timeout (#3965).
 *
 * Structural spec (no runtime), like OnErrorStartupFailureLogSpec: the fallback
 * lives in each app's Application.cfc, which the suite cannot drive without
 * tearing down the application.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("onError fallback distinguishes a running-app error from a startup failure (##3965)", () => {

			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc",
				"examples/starter-app/public/Application.cfc",
				"examples/tweet/public/Application.cfc"
			];

			for (var rel in targets) {
				(function(relPath) {
					it("in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						// $renderMinimalError must take a startupPhase flag so the two
						// call sites can report a startup failure vs a running-app error.
						var render = $functionBody(content, "\$renderMinimalError", relPath);
						expect(reFindNoCase("startupPhase", render) > 0).toBeTrue(
							relPath & " $renderMinimalError() must take a startupPhase flag to distinguish a startup failure from a running-app error."
						);

						// onError must pass startupPhase=false on the running-app path (the
						// catch after the main handler), so a request timeout after startup
						// is not reported as "failed to initialize".
						var onError = $functionBody(content, "onError", relPath);
						expect(reFindNoCase("\$renderMinimalError\s*\([^)]*false", onError) > 0).toBeTrue(
							relPath & " onError() must call $renderMinimalError(..., false) on the running-app (post-startup) path."
						);

						// The fallback must extend the request timeout (via onErrorRequestTimeout,
						// like the non-fallback path) before logging, so WriteLog survives a
						// request timeout and the wheels.log entry gets written.
						expect(reFindNoCase("onErrorRequestTimeout", render) > 0).toBeTrue(
							relPath & " $renderMinimalError() must extend the request timeout via onErrorRequestTimeout before logging, so the log can be written after a timeout."
						);

						// The minimal page must not UNCONDITIONALLY claim a startup failure:
						// a non-startup message has to exist alongside the startup one.
						expect(reFindNoCase("could not complete this request", render) > 0).toBeTrue(
							relPath & " $renderMinimalError() must render a running-app message (not only 'failed to initialize') when startupPhase is false."
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
