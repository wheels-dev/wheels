/**
 * Structural cross-engine guard for issue #3029.
 *
 * Bare tag-in-script statements such as a lone `cfabort` token terminated by a
 * semicolon are Lucee-only syntax. Adobe ColdFusion compiles them as a
 * reference to an undefined VARIABLE named "cfabort" and throws
 * "Variable CFABORT is undefined" at runtime. Dispatch.cfc's
 * enablePublicComponent=false 404 branch shipped exactly that, which turned
 * every stock-app homepage request in testing/production into an HTTP 500 on
 * every Adobe engine (discussion #3023). The branch had zero execution
 * coverage on any engine (it is validated by source inspection in
 * PublicComponentProductionSpec.cfc), so CI never caught it.
 *
 * An actual abort cannot execute inside a spec without killing the test
 * runner, so the practical gate is this structural scan: fail if any .cfc
 * under vendor/wheels contains a bare script-context statement of that form.
 * Use the script keyword `abort;` (or `exit;` etc.) instead.
 *
 * Scan rules (Anti-Pattern 14 spirit, line-anchored on purpose):
 * - Only .cfc files are scanned. Tag-context usage in .cfm templates is legal.
 * - The angle-bracketed tag form in legacy tag-based CFCs (e.g.
 *   wheelstest/system/util/XMLConverter.cfc) never matches because the tag
 *   form has no trailing semicolon and is preceded by an angle bracket.
 * - Comment-only lines are skipped via trimmed-prefix checks ("//", "*",
 *   "/*"). Deliberately NOT a global non-greedy comment-strip regex over the
 *   whole file — that shape hangs Lucee 7 on large sources.
 * - The forbidden token is built by concatenation below so this spec's own
 *   source never contains it in matchable form; the spec also skips its own
 *   file as belt and suspenders.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Cross-engine guard: bare tag-in-script abort statements (issue ##3029)", () => {

			it("vendor/wheels script code contains no bare cfabort statements", () => {
				// Build the token dynamically so the scan below can never match
				// this spec's own source text.
				var token = "cf" & "abort";

				// Bare statement form: the token at a statement boundary (line
				// start, whitespace, or after ; { }) followed by optional
				// whitespace and a semicolon.
				var pattern = "(^|[\s;{}])" & token & "\s*;";

				var selfName = "BareCfabortGuardSpec.cfc";
				var root = ExpandPath("/wheels");
				var files = DirectoryList(root, true, "path", "*.cfc");
				var offenders = [];

				for (var filePath in files) {
					if (ListLast(filePath, "/\") == selfName) {
						continue;
					}
					var content = FileRead(filePath);
					// Cheap pre-filter: most files never mention the token.
					if (!FindNoCase(token, content)) {
						continue;
					}
					// includeEmptyFields=true keeps blank lines so reported
					// line numbers match the actual source.
					var fileLines = ListToArray(content, Chr(10), true);
					var lineNumber = 0;
					for (var rawLine in fileLines) {
						lineNumber++;
						var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
						// Skip comment-only lines (line comments and block
						// comment bodies like the doc comment in
						// controller/rendering.cfc and the explanatory line
						// comment above the 404 branch in Dispatch.cfc).
						if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
							continue;
						}
						if (REFindNoCase(pattern, trimmed)) {
							ArrayAppend(offenders, Replace(filePath, root, "") & ":" & lineNumber);
						}
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"Found bare tag-in-script '#token#' statement(s) at: #ArrayToList(offenders, ', ')#. "
					& "That syntax is Lucee-only — Adobe ColdFusion throws 'Variable CFABORT is undefined' "
					& "at runtime. Use the script keyword form instead (the keyword without the cf prefix, "
					& "terminated by a semicolon). See issue ##3029."
				);
			});

		});

	}

}
