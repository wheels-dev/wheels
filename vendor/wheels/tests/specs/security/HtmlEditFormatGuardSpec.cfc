/**
 * Structural cross-engine guard for the removed `HtmlEditFormat` BIF.
 *
 * Adobe ColdFusion 2025 does not provide `HtmlEditFormat` — calling it throws
 * "Variable HTMLEDITFORMAT is undefined" and 500s whatever surface made the
 * call. An earlier fix replaced the call in `public/views/packagelist.cfm`, but
 * three sibling call sites survived: the debug bar's complexity panel, the
 * development error page's code frame, the docs viewer's extended examples, and
 * the legacy RocketUnit failure message. The compat matrix caught them only on
 * the Adobe 2025 legs, which do not run on PRs — twelve `Variable HTMLEDITFORMAT
 * is undefined` errors per adobe2025 leg.
 *
 * An Adobe-2025-only BIF miss cannot be reproduced on the Lucee runner, so the
 * gate is this scan of the shipped sources. Every call site must go through
 * `$encodeForDisplayText()` (`global/util.cfm`), which prefers the BIF where it
 * exists (it preserves "/" for readable file paths, #3548) and falls back to
 * `EncodeForHTML` on Adobe 2025.
 *
 * Scan rules:
 * - Only the call form (`HtmlEditFormat(`) is matched, so prose mentions are
 *   harmless once the comments are updated; comment-only lines are skipped
 *   anyway (Anti-Pattern 14 spirit, the same line-anchored approach as
 *   `BareCfabortGuardSpec` — a whole-file comment-strip regex hangs Lucee 7).
 * - `global/util.cfm` is allowlisted: the wrapper has to name the BIF to probe
 *   for it.
 * - The token is built by concatenation so this spec's own source never
 *   contains it in matchable form, and the spec skips itself regardless.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Cross-engine guard: no direct HtmlEditFormat calls (issue ##3645)", () => {

			it("shipped vendor/wheels sources call $encodeForDisplayText instead of the BIF", () => {
				var token = "Html" & "EditFormat";
				var pattern = token & "\s*\(";
				var wrapperSuffix = "/global/util.cfm";
				var selfName = "HtmlEditFormatGuardSpec.cfc";
				var root = ExpandPath("/wheels");

				// Copy into a fresh array: BoxLang returns a fixed-size array from
				// DirectoryList() and ArrayAppend on it throws with no message.
				var files = [];
				for (var listedFile in DirectoryList(root, true, "path", "*.cfc")) {
					ArrayAppend(files, listedFile);
				}
				for (var listedTemplate in DirectoryList(root, true, "path", "*.cfm")) {
					ArrayAppend(files, listedTemplate);
				}

				var offenders = [];
				for (var filePath in files) {
					var normalized = Replace(filePath, "\", "/", "all");
					// The framework's own specs are not shipped code, and this
					// spec names the BIF by construction.
					if (FindNoCase("/tests/", normalized) || ListLast(normalized, "/") == selfName) {
						continue;
					}
					// The sanctioned wrapper probes for the BIF, so it may name it.
					if (Right(normalized, Len(wrapperSuffix)) == wrapperSuffix) {
						continue;
					}
					var content = FileRead(filePath);
					// Cheap pre-filter: most files never mention the token.
					if (!FindNoCase(token, content)) {
						continue;
					}
					// includeEmptyFields=true keeps blank lines so reported line
					// numbers match the actual source.
					var fileLines = ListToArray(content, Chr(10), true);
					var lineNumber = 0;
					for (var rawLine in fileLines) {
						lineNumber++;
						var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
						if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
							continue;
						}
						if (REFindNoCase(pattern, trimmed)) {
							ArrayAppend(offenders, Replace(normalized, Replace(root, "\", "/", "all"), "") & ":" & lineNumber);
						}
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"Found direct '#token#()' call(s) at: #ArrayToList(offenders, ', ')#. "
					& "Adobe ColdFusion 2025 does not provide that BIF, so the call throws "
					& "'Variable HTMLEDITFORMAT is undefined'. Use $encodeForDisplayText() "
					& "from global/util.cfm instead. See issue ##3645."
				);
			});

		});

	}

}
