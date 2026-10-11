/**
 * Structural cross-engine guard for CLAUDE.md cross-engine invariant 16a.
 *
 * A parenthesized `new` expression used as a call receiver — that is,
 * `(new <dotted.Name>(<args>)).<method>(...)` — fails to COMPILE on Adobe
 * ColdFusion 2023 and 2025 with
 * "Invalid construct: Either argument or name is missing"
 * (coldfusion.compiler.CFMLParserBase$MissingNameException). Lucee 6/7 and
 * BoxLang accept it, so only the Adobe legs fail. Worse, the core suite
 * compiles every spec through directory="wheels.tests.specs", so a single
 * occurrence zeroes the ENTIRE Adobe engine leg (tests="0" on every database)
 * instead of failing one test. It was hit by JobClassRoundTripSpec.
 *
 * The construct never reaches runtime on Adobe — it kills compilation of the
 * bundle — so there is no behaviour to assert at runtime. The gate is a
 * structural scan of the spec source, mirroring BareCfabortGuardSpec.
 *
 * Scan rules (CLAUDE.md anti-pattern 14 spirit):
 * - Every .cfc under vendor/wheels is scanned, recursively: the specs (one occurrence zeroes the
 *   Adobe leg) and the framework itself (which has to compile on Adobe too).
 *   A commented-out example must not count, so comments are stripped first
 *   (line `//`, block, and tag comments). Newlines are preserved while
 *   stripping so the reported file:line still matches the real source.
 * - The matching pattern is assembled from fragments at runtime and this file
 *   is skipped by name, so the guard can never flag its own source.
 * - Only a GROUPING paren counts: `expect(new X()).toBe...()` and `foo(new X()).bar()` call a
 *   method on a call's result, which compiles everywhere, so the opening paren must not follow an
 *   identifier or a closing character.
 *
 * Known limits (each can only miss an offender, never flag a valid line): the scan is per line, so a
 * construct split across lines isn't seen; constructor arguments nest at most one level of parens;
 * and `//` stripping isn't quote-aware, so a `//` inside a string (a URL) hides the rest of its line.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Cross-engine guard: no parenthesized new receiver (invariant 16a)", () => {

			it("matches only a parenthesized new used as a call receiver", () => {
				var pattern = $receiverPattern();
				var offending = [
					"x = (new wheels.Job()).queueStats();",
					"r = ( new A.B(x = f(1)) ) . go ( );",
					"(new wheels.Job()).run();"
				];
				var allowed = [
					"expect(new wheels.Job()).toBeComponent();",
					"var o = foo(new X()).bar();",
					"x = new X().m();",
					"f(new X().m());",
					"var j = new wheels.Job(); j.m();"
				];
				for (var line in offending) {
					expect(REFindNoCase(pattern, line) > 0).toBeTrue("should flag: " & line);
				}
				for (var line in allowed) {
					expect(REFindNoCase(pattern, line) > 0).toBeFalse("should not flag: " & line);
				}
			});

			it("contains no parenthesized new receiver calls", () => {
				var pattern = $receiverPattern();
				var newKeyword = "new";

				var selfName = "ParenthesizedNewReceiverGuardSpec.cfc";
				var root = ExpandPath("/wheels");
				// Copy into a fresh array: BoxLang's DirectoryList() returns a
				// fixed-size array and ArrayAppend on it throws with no message
				// (CLAUDE.md invariant 20).
				var files = [];
				for (var listedFile in DirectoryList(root, true, "path", "*.cfc")) {
					ArrayAppend(files, listedFile);
				}

				var offenders = [];

				for (var filePath in files) {
					// Never flag this guard's own source (belt and suspenders:
					// the pattern is already built from fragments).
					if (FindNoCase(selfName, filePath)) {
						continue;
					}
					var content = FileRead(filePath);
					// Cheap pre-filter: every receiver contains the `new` token.
					if (!FindNoCase(newKeyword, content)) {
						continue;
					}
					var stripped = $stripCommentsKeepLines(content);
					// includeEmptyFields=true keeps blank lines so reported line
					// numbers match the actual source.
					var fileLines = ListToArray(stripped, Chr(10), true);
					var lineNumber = 0;
					for (var rawLine in fileLines) {
						lineNumber++;
						if (REFindNoCase(pattern, rawLine)) {
							ArrayAppend(
								offenders,
								Replace(Replace(filePath, root, ""), "\", "/", "all") & ":" & lineNumber
							);
						}
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"Found parenthesized-new call receiver(s) at: #ArrayToList(offenders, ', ')#. "
					& "A parenthesized new expression in receiver position fails to compile on Adobe ColdFusion "
					& "2023 and 2025 ('Invalid construct: Either argument or name is missing') and zeroes the "
					& "entire Adobe engine leg. Hoist the instance into a variable and call the method on the "
					& "variable instead. See CLAUDE.md cross-engine invariant 16a."
				);
			});

		});

	}

	/**
	 * The receiver pattern, assembled from parts so this spec's own source never contains the matched
	 * construct in one contiguous literal.
	 */
	private string function $receiverPattern() {
		var newKeyword = "new";
		var dottedName = "[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*";
		var args = "[^()]*(?:\([^()]*\)[^()]*)*";
		// The opening paren must be a grouping paren: not after an identifier, `.`, `)` or `]`, which
		// would make it a call's argument list (`expect(new X()).toBe()`, which compiles everywhere).
		var groupingParen = "(?:^|[^A-Za-z0-9_$.\])])";
		// Two `\)` closes: the inner one ends the constructor's argument list, the outer one ends the
		// parenthesized receiver. Missing the second close makes the pattern match
		// `func(new X().m())`, where the leading `(` is the enclosing call's, not a grouping paren.
		return groupingParen & "\(\s*" & newKeyword & "\s+" & dottedName & "\s*\("
			& args
			& "\)\s*\)\s*\.\s*[A-Za-z_$][A-Za-z0-9_$]*\s*\(";
	}

	/**
	 * Strip CFML tag, block, and line comments before scanning so a
	 * commented-out example does not count (CLAUDE.md anti-pattern 14),
	 * preserving newlines so the reported file:line still matches the source.
	 */
	private string function $stripCommentsKeepLines(required string source) {
		var result = "";
		var text = arguments.source;
		var maxPos = Len(text);
		var pos = 1;
		// Resolve once whether each comment shape is present at all, so the
		// loop below does not rescan to end-of-file for a shape that is absent.
		var hasTag = Find("<!---", text) > 0;
		var hasBlock = Find("/*", text) > 0;
		var hasLine = Find("//", text) > 0;

		while (pos <= maxPos) {
			var nextTag = hasTag ? Find("<!---", text, pos) : 0;
			var nextBlock = hasBlock ? Find("/*", text, pos) : 0;
			var nextLine = hasLine ? Find("//", text, pos) : 0;
			var next = 0;
			var kind = "";

			if (nextTag > 0 && (next == 0 || nextTag < next)) {
				next = nextTag;
				kind = "tag";
			}
			if (nextBlock > 0 && (next == 0 || nextBlock < next)) {
				next = nextBlock;
				kind = "block";
			}
			if (nextLine > 0 && (next == 0 || nextLine < next)) {
				next = nextLine;
				kind = "line";
			}

			if (next == 0) {
				result &= Mid(text, pos, maxPos - pos + 1);
				break;
			}

			result &= Mid(text, pos, next - pos);

			if (kind == "line") {
				var newlineAt = Find(Chr(10), text, next);
				if (newlineAt == 0) {
					pos = maxPos + 1;
				} else {
					result &= Chr(10);
					pos = newlineAt + 1;
				}
			} else if (kind == "block") {
				var blockCloseAt = Find("*/", text, next + 2);
				var blockEnd = (blockCloseAt == 0) ? maxPos + 1 : blockCloseAt + 2;
				result &= $newlinesIn(Mid(text, next, blockEnd - next));
				pos = blockEnd;
			} else {
				var tagCloseAt = Find("--->", text, next + 4);
				var tagEnd = (tagCloseAt == 0) ? maxPos + 1 : tagCloseAt + 4;
				result &= $newlinesIn(Mid(text, next, tagEnd - next));
				pos = tagEnd;
			}
		}

		return result;
	}

	/**
	 * Number of newlines in a comment body, re-emitted so stripping a
	 * multi-line comment keeps subsequent line numbers aligned.
	 */
	private string function $newlinesIn(required string text) {
		// Count every newline: ListLen() skips empty elements, so blank lines inside a comment would be
		// lost and reported line numbers after it would drift.
		var newlineCount = Len(arguments.text) - Len(Replace(arguments.text, Chr(10), "", "all"));
		return (newlineCount > 0) ? RepeatString(Chr(10), newlineCount) : "";
	}

}
