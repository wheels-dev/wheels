/**
 * Regression gate for the 4.0.6 first-boot EmptyStackException on
 * Adobe CF 2023 + CommandBox (issue ##3379, separate from the torn-down
 * application.wo / onError String[] stacks on that same issue).
 *
 * Field stack: onapplicationstart.cfc:409 `$createObjectFromRoot` →
 * Public.$init → Adobe `NeoPageContext.popSuperScope` EmptyStack. 4.0.5
 * Public.$init is include helpers + return only. 4.0.6 and develop call
 * `$scanAndPromoteIncludedGlobals()` (a parent-class method on Global)
 * immediately after the raw `include` in the same `$init` body. Adobe's
 * first compile of helpers.cfm after a cold start unbalances the
 * super-scope stack; a later request succeeds.
 *
 * This VM cannot run Adobe CF 2023 + CommandBox, so the field EmptyStack
 * cannot be reproduced here. What CI can prove:
 *   1. `$init` does not throw on the LuCLI engine.
 *   2. The ##3302 promote still lands helpers.cfm UDFs on `this`.
 *   3. The promote scan runs after `$includePublicHelpers` returns — not
 *      nested inside the same method as the raw include.
 *   4. `$init`'s own body contains no raw `include` statement, so the
 *      nest cannot silently return.
 */
component extends="wheels.WheelsTest" {

	function run() {

		var ctx = {fixturePath: "wheels.tests._assets.global.PublicInitTraceFixture"};

		describe("Public.$init include/promote un-nest (issue ##3379 first-boot EmptyStack)", () => {

			it("Public.$init does not throw", () => {
				var state = {threw = false, message = ""};
				try {
					var publicCfc = CreateObject("component", "wheels.Public");
					publicCfc.$init();
				} catch (any e) {
					state.threw = true;
					state.message = e.message;
				}
				expect(state.threw).toBeFalse(
					"Public.$init threw: " & state.message
				);
			});

			it("still promotes helpers.cfm functions onto this (##3302 contract)", () => {
				var publicCfc = CreateObject("component", "wheels.Public");
				publicCfc.$init();
				expect(StructKeyExists(publicCfc, "$$findMatchingRoutes")).toBeTrue(
					"expected $$findMatchingRoutes from helpers.cfm on this after $init"
				);
				expect(IsCustomFunction(publicCfc["$$findMatchingRoutes"])).toBeTrue();
				expect(StructKeyExists(publicCfc, "pageHeader")).toBeTrue(
					"expected pageHeader from helpers.cfm on this after $init"
				);
				expect(IsCustomFunction(publicCfc.pageHeader)).toBeTrue();
			});

			it("the $createObjectFromRoot boot path still returns a promoted Public instance", () => {
				var publicCfc = application.wo.$createObjectFromRoot(
					path = "wheels",
					fileName = "Public",
					method = "$init"
				);
				expect(IsObject(publicCfc)).toBeTrue();
				expect(StructKeyExists(publicCfc, "$$findMatchingRoutes")).toBeTrue();
				expect(IsCustomFunction(publicCfc["$$findMatchingRoutes"])).toBeTrue();
			});

			it("promote runs after $includePublicHelpers returns, not mid-include", () => {
				var fixture = CreateObject("component", ctx.fixturePath);
				fixture.$resetInitTrace();
				fixture.$init();
				var trace = fixture.$getInitTrace();
				expect(ArrayLen(trace)).toBe(
					3,
					"expected [include-start, include-return, promote], got [" & ArrayToList(trace) & "]"
				);
				expect(trace[1]).toBe("include-start");
				expect(trace[2]).toBe("include-return");
				expect(trace[3]).toBe("promote");
			});

			it("$init body contains no raw include (structural nest guard)", () => {
				var filePath = ExpandPath("/wheels/Public.cfc");
				var content = FileRead(filePath);
				var fileLines = ListToArray(content, Chr(10), true);
				var inInit = false;
				var offenders = [];
				var lineNumber = 0;
				for (var rawLine in fileLines) {
					lineNumber++;
					var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
					if (ReFindNoCase("function\s+\$init\s*\(", trimmed)) {
						inInit = true;
						continue;
					}
					if (inInit && ReFindNoCase("function\s+\$includePublicHelpers\s*\(", trimmed)) {
						break;
					}
					if (inInit && ReFindNoCase("(public|private|package|remote)?\s*(any|void|struct|array|string|boolean|numeric|query|date)?\s*function\s+", trimmed)) {
						break;
					}
					if (!inInit) {
						continue;
					}
					if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
						continue;
					}
					if (ReFindNoCase("^\s*include\s+", trimmed)) {
						ArrayAppend(offenders, "raw include at line " & lineNumber);
					}
				}
				expect(inInit).toBeTrue("expected to find Public.$init in Public.cfc");
				expect(ArrayLen(offenders)).toBe(
					0,
					"Public.$init must not contain a raw include (nest with promote scan): " & ArrayToList(offenders)
				);
			});

		});
	}

}
