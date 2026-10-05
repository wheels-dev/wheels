/**
 * Structural cross-engine guard: a try/catch/finally around app code loses its finally on BoxLang abort.
 *
 * On BoxLang, when a request ends with `abort` (or `cflocation`), a `finally` whose `try` ALSO has a
 * `catch` clause is SKIPPED — even a `catch (any e) { rethrow; }` that never runs. A catch-FREE
 * `try { ... } finally { ... }` runs its finally on abort as expected. Lucee and Adobe run the finally
 * either way; no transaction is involved. See CLAUDE.md Cross-Engine Invariant 22.
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
 * skipped by a request abort and is out of scope for this guard.
 *
 * Scan notes (Anti-Pattern 14 spirit):
 * - Comments and string literals are blanked with a single-pass char state machine (NOT a global
 *   non-greedy regex, which hangs Lucee 7), so braces/keywords inside them are not miscounted.
 * - Only files containing BOTH "catch" and "finally" are parsed (cheap pre-filter), so the char scan
 *   runs on a handful of files.
 * - A brace-depth frame stack associates each catch/finally with its owning try, so a NESTED
 *   outer-finally / inner-catch (the safe shape) is correctly NOT flagged.
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

				// Collect source files. BoxLang's DirectoryList() returns a fixed-size array, so copy into
				// a fresh one before appending (invariant 20).
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
					// Scope to production framework source: the test suites run in the harness, not a
					// production request, so a try/catch/finally there is not an abort-skip risk.
					if (FindNoCase("/tests/", rel) || FindNoCase("/wheelstest/", rel)) {
						continue;
					}

					var content = FileRead(filePath);
					// Only files with BOTH keywords can possibly hold a try/catch/finally.
					if (!FindNoCase("catch", content) || !FindNoCase("finally", content)) {
						continue;
					}

					// ── Blank comments and string literals (single pass, state carried across lines) ──
					var lines = ListToArray(content, Chr(10), true);
					var inBlockComment = false;
					var inString = false;
					var stringChar = "";
					var depth = 0;
					// Stack of open try frames: each {owner: brace depth the try sits at, hasCatch: boolean}.
					var frames = [];
					var lineNo = 0;

					for (var rawLine in lines) {
						lineNo++;
						var line = Replace(rawLine, Chr(13), "", "all");
						var clean = "";
						var i = 1;
						var n = Len(line);
						while (i <= n) {
							var ch = Mid(line, i, 1);
							var two = (i < n) ? Mid(line, i, 2) : "";
							if (inBlockComment) {
								if (two == "*/") {
									inBlockComment = false;
									i += 2;
									continue;
								}
								i++;
								continue;
							}
							if (inString) {
								// CFML escapes the quote by doubling it; treat a doubled quote as staying in.
								if (ch == stringChar) {
									if (two == stringChar & stringChar) {
										i += 2;
										continue;
									}
									inString = false;
									stringChar = "";
									i++;
									continue;
								}
								i++;
								continue;
							}
							if (two == "/*") {
								inBlockComment = true;
								i += 2;
								continue;
							}
							if (two == "//") {
								break;
							}
							if (ch == """" || ch == "'") {
								inString = true;
								stringChar = ch;
								i++;
								continue;
							}
							clean &= ch;
							i++;
						}

						// Keyword detection on the cleaned line. catch/finally as statement continuations
						// (preceded by line-start, whitespace, or a closing brace).
						var hasTry = REFindNoCase("(^|[\s;}])try\s*\{", clean) > 0;
						var hasCatchKw = REFindNoCase("(^|[\s}])catch\s*[({]", clean) > 0;
						var hasFinallyKw = REFindNoCase("(^|[\s}])finally\s*\{", clean) > 0;

						// A catch/finally continues the innermost open try (its body sits one level deeper,
						// so at this point depth is owner+1 and the top frame owns it).
						if (hasCatchKw && ArrayLen(frames)) {
							frames[ArrayLen(frames)].hasCatch = true;
						}
						if (hasFinallyKw && ArrayLen(frames) && frames[ArrayLen(frames)].hasCatch) {
							ArrayAppend(offenders, {file = rel, line = lineNo});
						}
						if (hasTry) {
							ArrayAppend(frames, {owner = depth, hasCatch = false});
						}

						// Net brace change, then pop any frame whose block has fully closed.
						var opens = Len(clean) - Len(Replace(clean, "{", "", "all"));
						var closes = Len(clean) - Len(Replace(clean, "}", "", "all"));
						depth += (opens - closes);
						while (ArrayLen(frames) && depth <= frames[ArrayLen(frames)].owner) {
							ArrayDeleteAt(frames, ArrayLen(frames));
						}
					}
				}

				// Partition into allowlisted vs reported (inline so nothing is called out of the closure).
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
					& "to ALLOWLIST with a reason. Currently allowlisted (not failures): #ArrayToList(allowed, ', ')#."
				);
			});

		});

	}

}
