/**
 * Structural cross-engine guard for issue #3054.
 *
 * `vendor/wheels/events/onapplicationstart.cfc` is declared as a bare
 * `component {` — no `extends`, and event CFCs are NOT integrated via the
 * `$integrateComponents()` mixin pass that model/controller objects get. So
 * the only `$`-prefixed helpers it can legally call are (a) methods defined
 * locally inside the same component, or (b) framework helpers reached through
 * the `application.wo.$X(...)` receiver. A bare call to a helper that lives in
 * `wheels.Global` (e.g. `$location()` at line 488) is genuinely out of scope:
 * Lucee throws `No matching function [$LOCATION] found`, the application start
 * aborts, and the engine discards the half-started app.
 *
 * In #3054 that lone bare `$location(url = local.url, addToken = false)` call
 * — on the `redirectAfterReload=true` + `url.reload` present branch that the
 * production/maintenance URL env-switch always hits — turned
 * `?reload=production&password=<secret>` into an HTTP 500 that silently
 * reverted the app to the file-configured environment. Every other one of the
 * 27 helper calls in the file already goes through `application.wo.$X(...)`.
 *
 * That branch only runs during a real application cold start, so it cannot be
 * exercised from inside a spec without booting a full app cycle. The practical
 * gate — in the spirit of BareCfabortGuardSpec — is this structural scan: for
 * every non-mixin (`component {` with no `extends`) event CFC, fail if any
 * bare `$helper(...)` call references a helper that is not defined locally in
 * the same file. Route it through `application.wo.$helper(...)` instead.
 *
 * Scan rules (line-anchored on purpose, mirroring BareCfabortGuardSpec):
 * - Only .cfc files under vendor/wheels/events are scanned.
 * - Only files whose declaration is a bare `component {` (no `extends=`) are
 *   checked — an `extends="wheels.Global"` CFC like EventMethods.cfc inherits
 *   the helper surface, so bare `$X()` calls there are legitimate.
 * - Member-access calls (`application.wo.$location(...)`, `obj.$foo()`) are
 *   skipped — the char before `$` is `.`.
 * - Function definitions (`function $resolveAllowEnvironmentSwitchViaUrl(`)
 *   are skipped — the preceding text ends with the `function` keyword.
 * - A bare call to a helper defined locally in the same file (e.g.
 *   `$resolveAllowEnvironmentSwitchViaUrl(...)` at line 366, defined at line
 *   501) is legitimate and skipped.
 * - Comment-only lines are skipped via trimmed-prefix checks ("//", "*",
 *   "/*"). Deliberately NOT a global comment-strip regex — that shape hangs
 *   Lucee 7 on large sources.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Cross-engine guard: bare framework-helper calls in non-mixin event CFCs (issue ##3054)", () => {

			it("non-mixin event CFCs never call an out-of-scope framework helper without application.wo", () => {

				// "$word(" — a $-prefixed call token, optional whitespace before
				// the opening paren.
				var callPattern = "\$[A-Za-z_][A-Za-z0-9_]*\s*\(";
				// A $-prefixed method definition.
				var defPattern = "function[[:space:]]+\$[A-Za-z_][A-Za-z0-9_]*";

				// The "/wheels" mapping resolves to the framework dir
				// (vendor/wheels), so the events package sits directly under it.
				var root = ExpandPath("/wheels");
				var eventsDir = root & "/events";
				var files = DirectoryList(eventsDir, true, "path", "*.cfc");
				var offenders = [];

				for (var filePath in files) {
					var content = FileRead(filePath);

					// Classify the component: only bare `component {` (no
					// `extends`) lacks the framework helper surface. Inspect the
					// declaration head (everything up to the component's opening
					// brace) — in event CFCs the first "{" is the component brace.
					var headEnd = Find("{", content);
					var head = headEnd > 0 ? Left(content, headEnd) : content;
					var isBareComponent =
						REFindNoCase("component", head) > 0
						&& REFindNoCase("extends", head) == 0;
					if (!isBareComponent) {
						continue;
					}

					// Helpers defined locally in this file — bare calls to these
					// resolve against the component's own scope and are fine.
					var localMethods = {};
					var defMatches = REMatch(defPattern, content);
					for (var rawDef in defMatches) {
						// rawDef looks like "function   $resolveFoo"
						var localName = Trim(ReplaceNoCase(rawDef, "function", "", "one"));
						localMethods[localName] = true;
					}

					var fileLines = ListToArray(content, Chr(10), true);
					var lineNumber = 0;
					for (var rawLine in fileLines) {
						lineNumber++;
						var line = Replace(rawLine, Chr(13), "", "all");
						var trimmed = Trim(line);
						// Skip comment-only lines (line + block comment bodies).
						if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
							continue;
						}

						var searchStart = 1;
						var m = REFind(callPattern, line, searchStart, true);
						while (m.pos[1] > 0) {
							var matchPos = m.pos[1];
							var matchLen = m.len[1];
							var matchText = Mid(line, matchPos, matchLen);
							// "$word(" -> "$word"
							var methodName = "$" & Trim(ListFirst(Mid(matchText, 2, Len(matchText) - 1), "("));

							var precedingChar = matchPos > 1 ? Mid(line, matchPos - 1, 1) : "";
							var precedingText = matchPos > 1 ? Left(line, matchPos - 1) : "";
							var isMemberCall = precedingChar == ".";
							// "function $name(" — definition, not a call site.
							var isDefinition = REFindNoCase("function[[:space:]]+$", precedingText) > 0;
							var isLocalHelper = StructKeyExists(localMethods, methodName);

							if (!isMemberCall && !isDefinition && !isLocalHelper) {
								ArrayAppend(
									offenders,
									Replace(filePath, root, "") & ":" & lineNumber & " (" & methodName & ")"
								);
							}

							searchStart = matchPos + matchLen;
							m = REFind(callPattern, line, searchStart, true);
						}
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"Found bare framework-helper call(s) in non-mixin event CFC(s) at: "
					& ArrayToList(offenders, ", ") & ". "
					& "A bare `component {` event CFC cannot resolve `wheels.Global` helpers in scope — "
					& "Lucee throws 'No matching function' and the application cold start aborts. "
					& "Route the call through `application.wo.$helper(...)` instead. See issue ##3054."
				);
			});

		});

	}

}
