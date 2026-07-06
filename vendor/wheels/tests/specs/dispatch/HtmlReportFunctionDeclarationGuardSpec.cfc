/**
 * Structural cross-engine guard for issue #3251 (item 1).
 *
 * vendor/wheels/tests/html.cfm renders the TestBox HTML report and is included
 * into the cached Public.cfc singleton by both the core runner
 * (vendor/wheels/tests/runner.cfm) and the app runner
 * (vendor/wheels/tests/app-runner.cfm). On Adobe ColdFusion a *named* function
 * declaration in an included .cfm leaks into the component scope, so the second
 * request that includes the template throws "Routines cannot be declared more
 * than once" — a hard HTTP 500. html.cfm originally declared
 * `function processNestedSuites()`, which 500'd `/wheels/core/tests?format=html`
 * and `/wheels/app/tests?format=html` on every Adobe engine.
 *
 * The fix declares the helper as a variables-scoped function EXPRESSION
 * (`variables.processNestedSuites = function(){...}`), the same pattern the core
 * runner already uses for its helpers to dodge Adobe's
 * DuplicateFunctionDefinitionException. CI exercises the runners with
 * `format=json`, never the `format=html` render path, so a regression here is
 * invisible to the normal suite — hence this source-level guard.
 *
 * Scan rules (Anti-Pattern 14 spirit, line-anchored on purpose):
 * - Only html.cfm is scanned (a .cfm view included into a component).
 * - A named declaration matches `function <name>(`; a function EXPRESSION
 *   (`= function(`) and the JS IIFE in the inline <script> (`(function () {`)
 *   have no identifier after the `function` keyword and never match.
 * - Comment-only lines are skipped via trimmed-prefix checks. Deliberately NOT
 *   a global non-greedy comment-strip regex over the whole file — that shape
 *   hangs Lucee 7 on large sources.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Cross-engine guard: html.cfm declares no named functions (issue ##3251)", () => {

			it("vendor/wheels/tests/html.cfm contains no bare named function declarations", () => {
				var templatePath = ExpandPath("/wheels/tests/html.cfm");
				expect(FileExists(templatePath)).toBeTrue(
					"Expected vendor/wheels/tests/html.cfm to exist at #templatePath#."
				);

				// A named declaration: the `function` keyword as a whole word,
				// then whitespace, then an identifier character (the name). A
				// function expression assigns `... = function(` (no name) and the
				// inline-<script> IIFE is `(function () {` (no name), so neither
				// matches.
				var pattern = "\bfunction\s+[a-zA-Z_]";

				var content = FileRead(templatePath);
				var fileLines = ListToArray(content, Chr(10), true);
				var offenders = [];
				var lineNumber = 0;
				for (var rawLine in fileLines) {
					lineNumber++;
					var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
					// Skip comment-only lines (this template's own doc/// lines
					// mention the word "function").
					if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
						continue;
					}
					if (REFindNoCase(pattern, trimmed)) {
						ArrayAppend(offenders, "line " & lineNumber & ": " & trimmed);
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"Found named function declaration(s) in html.cfm at: #ArrayToList(offenders, ' | ')#. "
					& "A named function in an included .cfm leaks into the cached Public.cfc scope on Adobe "
					& "and throws 'Routines cannot be declared more than once' on the second request, 500ing "
					& "the format=html test report. Declare the helper as a variables-scoped function "
					& "expression instead (variables.name = function(){...}). See issue ##3251."
				);
			});

		});

	}

}
