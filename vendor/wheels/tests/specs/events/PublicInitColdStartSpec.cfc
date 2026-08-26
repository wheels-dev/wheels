/**
 * Structural + executable guard for the 4.0.6 first-boot EmptyStack.
 *
 * Adobe CF 2023 + CommandBox threw java.util.EmptyStackException at
 * NeoPageContext.popSuperScope during onapplicationstart.cfc's
 * $createObjectFromRoot → Public.$init on the first request after a cold
 * start. Reverting Public.$init to the 4.0.5 include-and-return shape
 * cleared it; a later reload that compiled a second time also succeeded.
 *
 * The 4.0.5 → 4.0.6 delta inside $init is the $scanAndPromoteIncludedGlobals()
 * call added by 6bff0544 (##3302). That inherited Global method after a
 * first-compile include empties Adobe's super-scope stack, so $init's
 * return pops an empty stack. The suite cannot boot Adobe CF 2023 +
 * CommandBox, so this spec pins the contract that prevents the nest:
 * Public.$init does not call the scan, and onapplicationstart promotes
 * after $createObjectFromRoot returns so the ##3302 helpers-on-this
 * feature still runs once the include nest has unwound.
 *
 * Line-anchored comment-prefix skipping, same as
 * OnAppStartBareHelperGuardSpec / BareCfabortGuardSpec. Not a global
 * comment-strip regex — that shape hangs Lucee 7 on large sources.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Public.$init first-boot promote deferral (issue ##3379)", () => {

			it("Public.$init does not call $scanAndPromoteIncludedGlobals", () => {
				var body = $publicInitBody();
				var offenders = [];
				var lineNumber = 0;

				for (var rawLine in body.lines) {
					lineNumber++;
					var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
					if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
						continue;
					}
					if (FindNoCase("$scanAndPromoteIncludedGlobals", trimmed)) {
						ArrayAppend(offenders, "line #body.startLine + lineNumber - 1#");
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"Public.$init calls $scanAndPromoteIncludedGlobals at: #ArrayToList(offenders, ', ')#. "
					& "That inherited scan after the helpers.cfm include empties Adobe CF's "
					& "super-scope stack on the first compile after a CommandBox cold start "
					& "(EmptyStackException at onapplicationstart.cfc $createObjectFromRoot). "
					& "Keep $init as include-and-return and promote after $init returns."
				);
			});

			it("onapplicationstart promotes Public helpers after $createObjectFromRoot returns", () => {
				var content = FileRead(ExpandPath("/wheels/events/onapplicationstart.cfc"));
				var fileLines = ListToArray(content, Chr(10), true);
				var createLine = 0;
				var promoteLine = 0;
				var lineNumber = 0;

				for (var rawLine in fileLines) {
					lineNumber++;
					var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
					if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
						continue;
					}
					if (
						createLine == 0
						&& FindNoCase("$createObjectFromRoot", trimmed)
						&& FindNoCase("Public", trimmed)
						&& FindNoCase("$init", trimmed)
					) {
						createLine = lineNumber;
					}
					if (
						createLine > 0
						&& promoteLine == 0
						&& FindNoCase("$scanAndPromoteIncludedGlobals", trimmed)
					) {
						promoteLine = lineNumber;
					}
				}

				expect(createLine).toBeGT(
					0,
					"events/onapplicationstart.cfc no longer creates wheels.Public via "
					& "$createObjectFromRoot(..., method=""$init"")."
				);
				expect(promoteLine).toBeGT(
					createLine,
					"events/onapplicationstart.cfc no longer calls $scanAndPromoteIncludedGlobals() "
					& "after $createObjectFromRoot returns the Public instance. The ##3302 "
					& "helpers-on-this promote would never run on first boot."
				);
			});

			it("debug-IP Public creates also promote after $init returns", () => {
				// These paths replace application.wheels.public after $init.
				// Without a follow-up scan they would drop the ##3302
				// helpers-on-this surface on Lucee 6 / Adobe.
				var repoRoot = ExpandPath("/wheels/../..");
				var targets = [
					"cli/lucli/templates/app/public/Application.cfc",
					"public/Application.cfc",
					"examples/starter-app/public/Application.cfc",
					"examples/tweet/public/Application.cfc"
				];
				for (var relPath in targets) {
					var content = FileRead(repoRoot & "/" & relPath);
					var fileLines = ListToArray(content, Chr(10), true);
					var createLine = 0;
					var promoteLine = 0;
					var lineNumber = 0;
					for (var rawLine in fileLines) {
						lineNumber++;
						var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
						if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
							continue;
						}
						if (
							createLine == 0
							&& FindNoCase("$createObjectFromRoot", trimmed)
							&& FindNoCase("Public", trimmed)
							&& FindNoCase("$init", trimmed)
						) {
							createLine = lineNumber;
						}
						if (
							createLine > 0
							&& promoteLine == 0
							&& FindNoCase("$scanAndPromoteIncludedGlobals", trimmed)
						) {
							promoteLine = lineNumber;
						}
					}
					expect(createLine).toBeGT(
						0,
						relPath & " no longer creates wheels.Public via $createObjectFromRoot."
					);
					expect(promoteLine).toBeGT(
						createLine,
						relPath & " creates Public via $init but does not call "
						& "$scanAndPromoteIncludedGlobals() afterwards."
					);
				}
			});

			it("promotes helpers.cfm functions onto this after $init returns", () => {
				var publicCfc = CreateObject("component", "wheels.Public").$init();
				var promotedKeys = publicCfc.$scanAndPromoteIncludedGlobals();

				expect(IsArray(promotedKeys)).toBeTrue();
				expect(StructKeyExists(publicCfc, "$$findMatchingRoutes")).toBeTrue(
					"expected $$findMatchingRoutes from helpers.cfm on this after the "
					& "deferred $scanAndPromoteIncludedGlobals() call (##3302)"
				);
				expect(IsCustomFunction(publicCfc["$$findMatchingRoutes"])).toBeTrue();
			});

		});

	}

	/**
	 * Extracts the $init function body lines from Public.cfc (from its
	 * declaration up to the next function declaration). Returns
	 * {lines, startLine} where startLine is the 1-based file line of the
	 * declaration, so failure messages can report real file line numbers.
	 */
	public struct function $publicInitBody() {
		var content = FileRead(ExpandPath("/wheels/Public.cfc"));
		var fileLines = ListToArray(content, Chr(10), true);
		var declarationPattern = "(public|private)\s+\w+\s+function\s+";
		var result = {lines = [], startLine = 0};
		var inBody = false;
		var lineNumber = 0;

		for (var rawLine in fileLines) {
			lineNumber++;
			if (!inBody) {
				if (REFindNoCase(declarationPattern & "\$init\b", rawLine)) {
					inBody = true;
					result.startLine = lineNumber;
					ArrayAppend(result.lines, rawLine);
				}
				continue;
			}
			if (REFindNoCase(declarationPattern & "[\w$]+\s*\(", rawLine)) {
				break;
			}
			ArrayAppend(result.lines, rawLine);
		}

		expect(result.startLine).toBeGT(
			0,
			"Could not locate the $init declaration in Public.cfc — "
			& "update PublicInitColdStartSpec.cfc if the function was renamed."
		);
		return result;
	}

}
