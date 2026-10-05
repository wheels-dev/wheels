/**
 * Structural cross-engine guard: a try/catch/finally around app code loses its finally on BoxLang abort.
 *
 * On BoxLang, when a request ends with `abort` (or `cflocation`), a `finally` whose `try` ALSO has a
 * `catch` clause is SKIPPED — even a `catch (any e) { rethrow; }` that never runs. A catch-FREE
 * `try { ... } finally { ... }` runs its finally on abort as expected, and so does one whose finally
 * issues a transaction action; the catch clause alone decides. Lucee and Adobe run the finally either
 * way; no transaction is involved. See CLAUDE.md Cross-Engine Invariant 22.
 *
 * The practical consequence: any framework cleanup that MUST run even when app code (an action, a
 * filter, a callback, a view/include, a mailer render, a job handler) ends the request with an abort
 * has to live in a finally whose try carries NO catch. The safe shape when you also need a catch is to
 * NEST: an outer catch-free `try { ... } finally { <cleanup> }` wrapping an inner `try { ... } catch { ... }`
 * (what withAdvisoryLock's transaction path and invokeWithTransaction both do).
 *
 * This spec fails if any production framework source has a single `try` with BOTH a `catch` and a
 * `finally`. New code that needs both must nest instead. Known, reviewed exceptions are in the
 * allowlist below with a reason.
 *
 * Scope: `*.cfc` and `*.cfm` under vendor/wheels, EXCLUDING `/tests/` and `/wheelstest/` — that code
 * runs in the test harness, not on a production request path, so a try/catch/finally there cannot be
 * skipped by a request abort and is out of scope for this guard. SCRIPT syntax only: the tag-based
 * cftry / cfcatch / cffinally form (and tag-style comments) is not scanned; there are no tag-based
 * finally blocks in production vendor/wheels today. (Angle-bracket tag syntax is omitted here on
 * purpose: Lucee's tag scanner parses a literal cf-tag even inside a comment.)
 *
 * Detection ($scanTryCatchFinally): comments and string literals are first blanked to spaces by a
 * single-pass char state machine (NOT a global regex, which hangs Lucee 7), preserving length and
 * newlines so line numbers stay accurate. The cleaned text is then brace-matched over the whole file:
 * each `try {` is matched to its closing `}`, and the following `catch (...) {} / finally {}` chain is
 * walked. A try is an offender iff its own chain has BOTH a catch and a finally. Because the matcher
 * works on real brace depth (not line adjacency), a NESTED outer-finally / inner-catch is correctly
 * classified as clean. $scanTryCatchFinally is exercised directly by the self-test below.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Cross-engine guard: no try/catch/finally around app code (BoxLang drops the finally on abort)", () => {

			it("vendor/wheels production source has no single try with both a catch and a finally", () => {
				var selfName = "TryCatchFinallyGuardSpec.cfc";
				var root = ExpandPath("/wheels");

				// Reviewed, intentional exceptions: path-suffix match => reason.
				var allowList = {
					"/model/locking.cfm": "$advisoryLockTransactionBody outer try: the lock release already runs in an inner catch-free finally (invariant 22, PR ##4330); the outer catch/rollback is tracked separately."
				};

				// BoxLang's DirectoryList() returns a fixed-size array, so copy before appending (invariant 20).
				var files = [];
				for (var listed in DirectoryList(root, true, "path", "*.cfc")) {
					ArrayAppend(files, listed);
				}
				for (var listed in DirectoryList(root, true, "path", "*.cfm")) {
					ArrayAppend(files, listed);
				}

				var offenders = [];
				for (var filePath in files) {
					var rel = Replace(Replace(filePath, root, "", "one"), "\", "/", "all");
					if (ListLast(rel, "/") == selfName) {
						continue;
					}
					if (FindNoCase("/tests/", rel) || FindNoCase("/wheelstest/", rel)) {
						continue;
					}
					var content = FileRead(filePath);
					// Only files with BOTH keywords can hold a single try/catch/finally.
					if (!FindNoCase("catch", content) || !FindNoCase("finally", content)) {
						continue;
					}
					for (var hitLine in $scanTryCatchFinally(content)) {
						ArrayAppend(offenders, {file = rel, line = hitLine});
					}
				}

				// Partition into allowlisted vs reported.
				var reported = [];
				var allowed = [];
				for (var off in offenders) {
					var isAllowed = false;
					for (var key in allowList) {
						if (FindNoCase(key, off.file)) {
							isAllowed = true;
							break;
						}
					}
					if (isAllowed) {
						ArrayAppend(allowed, off.file & ":" & off.line);
					} else {
						ArrayAppend(reported, off.file & ":" & off.line);
					}
				}

				expect(ArrayLen(reported)).toBe(
					0,
					"Found try/catch/finally in production framework source at: #ArrayToList(reported, ', ')#. "
					& "On BoxLang the finally is SKIPPED when the request ends with abort (invariant 22). If the "
					& "finally must run on abort, NEST instead: an outer catch-free try/finally holding the "
					& "cleanup, wrapping an inner try/catch. If the pattern is intentional and abort-safe, add it "
					& "to the allowlist with a reason. Currently allowlisted (not failures): #ArrayToList(allowed, ', ')#."
				);
			});

			it("the try/catch/finally scanner classifies the known shapes correctly", () => {
				var nl = Chr(10);
				// OFFENDERS — a single try with both a catch and a finally, in the shapes the old
				// line-based scan got wrong (rev1-r3) plus the plain multi-line case.
				var offenderShapes = {
					"multiline" = ["try {", "  a();", "} catch (any e) {", "  b();", "} finally {", "  c();", "}"],
					"allman-own-line" = ["try {", "  a();", "}", "catch (any e) {", "  b();", "}", "finally {", "  c();", "}"],
					"sameline-catch-then-finally" = ["try {", "  a();", "} catch (any e) { b(); }", "finally {", "  c();", "}"],
					"one-line-full" = ["try { a(); } catch (any e) { b(); } finally { c(); }"]
				};
				// CLEAN — no single try owns both; includes the safe nested shapes.
				var cleanShapes = {
					"catch-free-try-finally" = ["try {", "  a();", "} finally {", "  c();", "}"],
					"nested-one-line-inner" = ["try {", "  try { a(); } catch (any e) {}", "} finally {", "  c();", "}"],
					"nested-multiline" = ["try {", "  try {", "    a();", "  } catch (any e) {", "    b();", "  }", "} finally {", "  c();", "}"],
					"try-catch-no-finally" = ["try {", "  a();", "} catch (any e) {", "  b();", "}"]
				};

				for (var name in offenderShapes) {
					var hits = $scanTryCatchFinally(ArrayToList(offenderShapes[name], nl));
					expect(ArrayLen(hits) > 0).toBeTrue("scanner MISSED an offender shape: " & name);
				}
				for (var name in cleanShapes) {
					var hits = $scanTryCatchFinally(ArrayToList(cleanShapes[name], nl));
					expect(ArrayLen(hits)).toBe(0, "scanner FALSE-POSITIVED a clean shape: " & name & " -> lines " & ArrayToList(hits, ","));
				}
			});

		});

	}

	/**
	 * Return the 1-based line numbers of every single try that has BOTH a catch and a finally in its
	 * own chain. Comments and strings are blanked first; detection is whole-file brace matching.
	 */
	public array function $scanTryCatchFinally(required string source) {
		var src = $blankCommentsAndStrings(arguments.source);
		var n = Len(src);
		var offenders = [];
		var pos = 1;
		while (pos <= n) {
			var m = REFind("(^|[^A-Za-z0-9_$])try[\s]*\{", src, pos, true);
			if (!ArrayLen(m.pos) || m.pos[1] == 0) {
				break;
			}
			var bodyOpen = m.pos[1] + m.len[1] - 1; // position of the try body's '{'
			var bodyClose = $matchBrace(src, bodyOpen);
			if (bodyClose == 0) {
				break; // unbalanced; stop scanning this file
			}
			var hasCatch = false;
			var hasFinally = false;
			var cur = bodyClose + 1;
			while (cur <= n) {
				var rest = Mid(src, cur, n - cur + 1);
				var cm = REFind("^[\s]*(catch[\s]*\([^)]*\)|finally)[\s]*\{", rest, 1, true);
				if (!ArrayLen(cm.pos) || cm.pos[1] == 0) {
					break; // no further catch/finally continuation
				}
				var kw = Mid(rest, cm.pos[2], cm.len[2]);
				if (Left(kw, 5) == "catch") {
					hasCatch = true;
				} else {
					hasFinally = true;
				}
				var blockOpen = cur + (cm.pos[1] + cm.len[1] - 1) - 1; // the continuation block's '{'
				var blockClose = $matchBrace(src, blockOpen);
				if (blockClose == 0) {
					break;
				}
				cur = blockClose + 1;
				if (hasFinally) {
					break; // finally is always last in a try chain
				}
			}
			if (hasCatch && hasFinally) {
				ArrayAppend(offenders, $lineOf(src, bodyOpen));
			}
			pos = bodyOpen + 1; // advance past this try's '{' so nested trys are found on their own
		}
		return offenders;
	}

	/**
	 * Blank CFML line/block comments and string literals to spaces, preserving length and newlines so
	 * positions and line numbers are unchanged. Single char pass — no global regex (Lucee 7 hang).
	 */
	public string function $blankCommentsAndStrings(required string src) {
		var n = Len(arguments.src);
		var out = [];
		var inBlock = false;
		var inString = false;
		var strChar = "";
		var i = 1;
		while (i <= n) {
			var ch = Mid(arguments.src, i, 1);
			var two = (i < n) ? Mid(arguments.src, i, 2) : "";
			if (inBlock) {
				if (two == "*/") {
					ArrayAppend(out, "  ");
					i += 2;
					inBlock = false;
					continue;
				}
				ArrayAppend(out, ch == Chr(10) ? Chr(10) : " ");
				i++;
				continue;
			}
			if (inString) {
				if (ch == strChar) {
					if (two == strChar & strChar) {
						ArrayAppend(out, "  ");
						i += 2;
						continue;
					}
					inString = false;
					ArrayAppend(out, " ");
					i++;
					continue;
				}
				ArrayAppend(out, ch == Chr(10) ? Chr(10) : " ");
				i++;
				continue;
			}
			if (two == "/*") {
				inBlock = true;
				ArrayAppend(out, "  ");
				i += 2;
				continue;
			}
			if (two == "//") {
				while (i <= n && Mid(arguments.src, i, 1) != Chr(10)) {
					ArrayAppend(out, " ");
					i++;
				}
				continue;
			}
			if (ch == """" || ch == "'") {
				inString = true;
				strChar = ch;
				ArrayAppend(out, " ");
				i++;
				continue;
			}
			ArrayAppend(out, ch);
			i++;
		}
		return ArrayToList(out, "");
	}

	/**
	 * Index of the `}` that matches the `{` at openPos, or 0 if unbalanced. Operates on text whose
	 * comments and strings are already blanked, so every brace is structural.
	 */
	public numeric function $matchBrace(required string src, required numeric openPos) {
		var depth = 0;
		var i = arguments.openPos;
		var n = Len(arguments.src);
		while (i <= n) {
			var ch = Mid(arguments.src, i, 1);
			if (ch == "{") {
				depth++;
			} else if (ch == "}") {
				depth--;
				if (depth == 0) {
					return i;
				}
			}
			i++;
		}
		return 0;
	}

	/**
	 * 1-based line number of a character position (count of newlines before it, plus one).
	 */
	public numeric function $lineOf(required string src, required numeric pos) {
		var prefix = arguments.pos > 1 ? Left(arguments.src, arguments.pos - 1) : "";
		return 1 + (Len(prefix) - Len(Replace(prefix, Chr(10), "", "all")));
	}

}
