component extends="wheels.WheelsTest" {

	/*
	 * Structural guard for issue #3029.
	 *
	 * A bare `cfabort;` statement in script context is Lucee-only: Adobe CF
	 * (2018/2021/2023/2025) parses it as a reference to an undefined VARIABLE
	 * named `cfabort` and throws `Variable CFABORT is undefined` at runtime.
	 * The portable form is the script keyword `abort;` (or the parenthesized
	 * `cfabort();`).
	 *
	 * We cannot drive the real Dispatch.$request() 404 branch from a unit test
	 * without a full request fixture, and an actual `abort` cannot execute
	 * inside a spec without killing the TestBox runner. So the practical gate
	 * is a source scan across vendor/wheels framework code (tests excluded),
	 * paired with the documented manual cross-engine repro in the issue.
	 */
	function run() {

		describe("Dispatch / cross-engine: no bare cfabort statements in script context", () => {

			// Strip tag comments (<!--- --->), block comments (/* */), and line
			// comments (//) BEFORE scanning — a mention of "cfabort" in a comment
			// is not a runtime statement and must not trip the guard.
			// See CLAUDE.md Anti-Pattern #14.
			var stripCfmlComments = function(required string source) {
				var out = arguments.source;
				out = REReplace(out, "(?s)<!---.*?--->", " ", "all");
				out = REReplace(out, "(?s)/\*.*?\*/", " ", "all");
				out = REReplace(out, "//[^\n\r]*", " ", "all");
				return out;
			};

			it("vendor/wheels framework code never uses a bare `cfabort;` (Adobe parses it as an undefined variable)", () => {
				var root = ExpandPath("/wheels");
				var files = DirectoryList(
					path = root,
					recurse = true,
					filter = "*.cfc",
					type = "file"
				);

				expect(ArrayLen(files)).toBeGT(0, "No framework CFCs found to scan.");

				var offenders = [];
				for (var filePath in files) {
					// Tests legitimately discuss cfabort in strings/comments and
					// don't ship to runtime; skip the spec tree.
					if (FindNoCase("#root#/tests/", Replace(filePath, "\", "/", "all"))) {
						continue;
					}

					var stripped = stripCfmlComments(FileRead(filePath));

					// Match the bare statement form `cfabort;` / `cfabort ;`.
					// The tag form `<cfabort>` ends in `>`, and the parenthesized
					// script form `cfabort()` has a `(` before any `;`, so neither
					// matches `cfabort` + optional-whitespace + `;`.
					if (REFindNoCase("cfabort[[:space:]]*;", stripped)) {
						ArrayAppend(offenders, Replace(filePath, root, "/wheels", "one"));
					}
				}

				expect(offenders).toBeEmpty(
					"Bare `cfabort;` is Lucee-only and crashes every Adobe engine with "
					& "`Variable CFABORT is undefined`. Use the portable `abort;` keyword. "
					& "Offending file(s): " & ArrayToList(offenders, ", ")
				);
			});

		});

	}

}
