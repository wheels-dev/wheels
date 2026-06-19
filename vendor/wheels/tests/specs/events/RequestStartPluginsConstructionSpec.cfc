/**
 * Structural guard for issue ##2897 (Stage 3 quick win, PR A).
 *
 * EventMethods.cfc##$runOnRequestStart used to construct
 * `local.Mixins = new wheels.Plugins()` unconditionally at the top of every
 * request even though the instance is only ever used inside the
 * `!StructIsEmpty(application.wheels.mixins)` guard. For mixin-free apps the
 * construction was 100% wasted work — and not cheap: each `new wheels.Plugins()`
 * also runs the 4,000+ line `wheels.Global` pseudo-constructor, including the
 * `$promoteIncludedGlobalsToThis()` isCustomFunction scan over ~200 inherited
 * UDFs. The fix hoists the construction inside the mixins-nonempty guard, so
 * mixin-free requests skip it entirely.
 *
 * Why this gate is structural (honest design note): the construction site has
 * no injection seam — `new wheels.Plugins()` is a direct constructor call and
 * `wheels.Plugins` keeps no instance counter — and executing
 * $runOnRequestStart inside a spec drags in the full request lifecycle (debug
 * points, cgi copying, plugin reloads, maintenance handling) without making
 * the construction observable anyway. So, like security/BareCfabortGuardSpec
 * and events/OnAppStartBareHelperGuardSpec, the practical gate is a
 * line-anchored source scan with comment-prefix skipping (deliberately NOT a
 * global comment-strip regex — that shape hangs Lucee 7 on large sources).
 * When Stage 3 proper (shared PluginObj) lands, constructions may disappear
 * from this function entirely; the specs below are written to keep passing in
 * that case.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$runOnRequestStart Plugins construction (issue ##2897 Stage 3)", () => {

			it("constructs wheels.Plugins only inside the mixins-nonempty guard", () => {
				var body = $runOnRequestStartBody();
				var guardLine = 0;
				var offenders = [];
				var lineNumber = 0;

				for (var rawLine in body.lines) {
					lineNumber++;
					var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
					// Skip comment-only lines; constructor mentions in prose are not calls.
					if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
						continue;
					}
					if (guardLine == 0 && FindNoCase("StructIsEmpty(application.wheels.mixins)", trimmed)) {
						guardLine = lineNumber;
					}
					if (FindNoCase("new wheels.Plugins(", trimmed) && (guardLine == 0 || lineNumber < guardLine)) {
						ArrayAppend(offenders, "line #body.startLine + lineNumber - 1#");
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"new wheels.Plugins() constructed before/outside the "
					& "!StructIsEmpty(application.wheels.mixins) guard in "
					& "events/EventMethods.cfc##$runOnRequestStart at: #ArrayToList(offenders, ', ')#. "
					& "Unconditional construction pays a throwaway Plugins + Global "
					& "pseudo-constructor on every request of every mixin-free app "
					& "(issue ##2897, Stage 3)."
				);
			});

			it("still initializes mixins inside the guard when plugins or packages provide them", () => {
				var body = $runOnRequestStartBody();
				var source = ArrayToList(body.lines, Chr(10));
				var guardPos = FindNoCase("StructIsEmpty(application.wheels.mixins)", source);
				var initPos = FindNoCase("$initializeMixins(variables)", source);

				expect(guardPos).toBeGT(
					0,
					"events/EventMethods.cfc##$runOnRequestStart no longer gates mixin "
					& "integration on !StructIsEmpty(application.wheels.mixins)."
				);
				expect(initPos).toBeGT(
					guardPos,
					"events/EventMethods.cfc##$runOnRequestStart no longer calls "
					& "$initializeMixins(variables) inside the mixins guard — plugin/package "
					& "mixins would never integrate into Application.cfc."
				);
			});

		});

	}

	/**
	 * Extracts the $runOnRequestStart function body lines from
	 * events/EventMethods.cfc (from its declaration up to the next function
	 * declaration). Returns {lines, startLine} where startLine is the 1-based
	 * file line of the declaration, so failure messages can report real
	 * file line numbers.
	 */
	public struct function $runOnRequestStartBody() {
		var content = FileRead(ExpandPath("/wheels/events/EventMethods.cfc"));
		// includeEmptyFields=true keeps blank lines so line numbers match the source.
		var fileLines = ListToArray(content, Chr(10), true);
		var declarationPattern = "(public|private)\s+\w+\s+function\s+";
		var result = {lines = [], startLine = 0};
		var inBody = false;
		var lineNumber = 0;

		for (var rawLine in fileLines) {
			lineNumber++;
			if (!inBody) {
				if (REFindNoCase(declarationPattern & "\$runOnRequestStart\b", rawLine)) {
					inBody = true;
					result.startLine = lineNumber;
					ArrayAppend(result.lines, rawLine);
				}
				continue;
			}
			// Next function declaration ends the body.
			if (REFindNoCase(declarationPattern & "[\w$]+\s*\(", rawLine)) {
				break;
			}
			ArrayAppend(result.lines, rawLine);
		}

		expect(result.startLine).toBeGT(
			0,
			"Could not locate the $runOnRequestStart declaration in events/EventMethods.cfc — "
			& "update RequestStartPluginsConstructionSpec.cfc if the function was renamed."
		);
		return result;
	}

}
