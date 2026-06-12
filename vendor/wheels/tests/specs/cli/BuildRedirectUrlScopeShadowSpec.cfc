/**
 * Regression for issue ##3053 — "Adobe CF: every password reload and URL env
 * switch returns HTTP 500 — local.url shadows the url scope in
 * $buildRedirectUrl (##3036 regression)".
 *
 * #3036 added six unscoped URL-scope reads (StructKeyExists(url, "reload"),
 * url.password, ...) to public/Application.cfc::$buildRedirectUrl(), a function
 * that has always declared a STRING local named `local.url` (the redirect
 * target it builds from cgi.path_info / cgi.script_name). On Adobe ColdFusion
 * unscoped name resolution binds the bare `url` reads to that string local
 * BEFORE the URL scope, so StructKeyExists(url, "reload") throws
 * "You have attempted to dereference a scalar variable of type class
 * java.lang.String as a structure with members" — an HTTP 500 fired before
 * applicationStop(), so every password-gated reload and every URL environment
 * switch becomes non-functional on Adobe. Lucee masks the bug because `url` is
 * a reserved scope name that always wins over a local. This is CLAUDE.md
 * cross-engine anti-pattern ##11 (never name a local after a reserved scope)
 * verbatim.
 *
 * The fix renames the string local (local.url -> local.redirectUrl) so the
 * bare `url.*` reads resolve to the URL scope on every engine. All four
 * same-lineage copies of public/Application.cfc must carry it, mirroring
 * ReloadEnvironmentSwitchParitySpec.cfc.
 *
 * Structural spec (no runtime): the runtime repro requires the Adobe docker
 * harness (the bug is invisible on Lucee, which is what the local SQLite
 * runner uses), so this asserts the static defect is gone — no reserved-scope
 * `local.url` may coexist with unscoped url-scope reads inside
 * $buildRedirectUrl(). This is the regression guard the issue's acceptance
 * criteria call for ("a reserved-scope shadowing in this file can't ship green
 * again").
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$buildRedirectUrl reserved-scope shadow (issue ##3053)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc",
				"examples/tweet/public/Application.cfc",
				"examples/starter-app/public/Application.cfc"
			];

			// Slice out just the $buildRedirectUrl() body. In every copy the
			// function is immediately followed by `private void function
			// loadEnvFile(...)`, so that marker is a stable end boundary.
			var bodyOf = function(content) {
				var startMarker = "function $buildRedirectUrl(";
				var endMarker = "function loadEnvFile(";
				var startPos = Find(startMarker, content);
				if (startPos == 0) {
					return "";
				}
				var endPos = Find(endMarker, content, startPos);
				if (endPos == 0) {
					endPos = Len(content) + 1;
				}
				return Mid(content, startPos, endPos - startPos);
			};

			for (var rel in targets) {
				// Capture the loop variable so the closure binds the current
				// value, not the final iteration's.
				(function(relPath) {

					it("does not shadow the url scope with a string local.url in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);
						var fnBody = bodyOf(content);

						expect(Len(fnBody) > 0).toBeTrue(
							relPath & " must contain a $buildRedirectUrl() function."
						);

						// Sanity: the function still reads the URL scope unscoped
						// (the #3036 environment-switch detection). If these reads
						// ever move out the test below would pass vacuously.
						expect(
							fnBody contains 'StructKeyExists(url, "reload")'
						).toBeTrue(
							relPath & " $buildRedirectUrl() must still read the URL scope "
							& "(StructKeyExists(url, ""reload"")) for the environment-switch "
							& "detection added in ##3036."
						);

						// The bug: a STRING local named `url` declared in the same
						// function. On Adobe CF the bare url.* reads bind to this
						// string and throw a ScopeCastException -> HTTP 500. The fix
						// renames it (local.url -> local.redirectUrl).
						expect(
							ArrayLen(reMatchNoCase("local\.url\b", fnBody))
						).toBe(
							0,
							relPath & " $buildRedirectUrl() declares a string `local.url` while "
							& "reading the unscoped URL scope. On Adobe CF the bare `url` reads "
							& "resolve to that string local and throw a ScopeCastException (HTTP "
							& "500) before applicationStop(), breaking every password reload and "
							& "URL environment switch (issue ##3053). Rename it to local.redirectUrl "
							& "so the url.* reads resolve to the URL scope on every engine."
						);
					});

				})(rel);
			}

		});

	}

}
