/**
 * Guard for issue ##3730: the first request after every cold start failed on
 * Adobe CF 2023 and 2025 with java.util.EmptyStackException at
 * `NeoPageContext.popSuperScope`, thrown from the
 * `application.wo.$createObjectFromRoot(... "Public" ...)` call in
 * onapplicationstart.cfc.
 *
 * Cause (an Adobe engine bug, reproduced without Wheels): a mixin UDF runs on
 * a plain wheels.Global and creates a Global subclass. The subclass's
 * pseudo-constructor copies that same running UDF onto its `this`
 * ($promoteIncludedGlobalsToThis). The first time that happens in a JVM, the
 * call's epilogue pops a super scope its prologue never pushed. Creating any
 * Global subclass outside a mixin call first initializes the engine state.
 * onapplicationstart.$init() does that with wheels.events.SuperScopePrimer
 * before anything else runs.
 *
 * The failure happens once per JVM, on a cold start, so the suite (running in
 * an already-started JVM) cannot reproduce it. The gate is structural, like
 * OnAppStartBareHelperGuardSpec: line-anchored, skips comment lines, and uses
 * no global comment-strip regex. The cold-start proof is recorded on the PR.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Adobe super-scope primer (##3730)", () => {

			it("SuperScopePrimer is a wheels.Global subclass", () => {
				var primer = CreateObject("component", "wheels.events.SuperScopePrimer");
				expect(IsInstanceOf(primer, "wheels.Global")).toBeTrue(
					"SuperScopePrimer must extend wheels.Global: only a Global subclass primes the Global mixins."
				);
			});

			it("SuperScopePrimer declares no functions of its own", () => {
				var meta = GetComponentMetadata("wheels.events.SuperScopePrimer");
				var declared = StructKeyExists(meta, "functions") && IsArray(meta.functions) ? ArrayLen(meta.functions) : 0;
				expect(declared).toBe(
					0,
					"SuperScopePrimer must stay empty; its pseudo-constructor is Global's."
				);
			});

			it("onapplicationstart.$init creates the primer before any application.wo call", () => {
				var content = FileRead(ExpandPath("/wheels/events/onapplicationstart.cfc"));
				var fileLines = ListToArray(content, Chr(10), true);
				var state = {inInit = false, lineNumber = 0, primerLine = 0, firstStatementLine = 0, firstWoLine = 0, firstCreateFromRootLine = 0};
				for (var rawLine in fileLines) {
					state.lineNumber++;
					var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
					if (!state.inInit) {
						if (ReFindNoCase("function\s+\$init\s*\(", trimmed)) {
							state.inInit = true;
						}
						continue;
					}
					if (ReFindNoCase("^(public|private|package|remote)\s+[a-z]*\s*function\s+", trimmed)) {
						break;
					}
					if (!Len(trimmed) || Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
						continue;
					}
					if (state.firstStatementLine == 0) {
						state.firstStatementLine = state.lineNumber;
					}
					if (state.primerLine == 0 && ReFindNoCase("CreateObject\s*\(\s*""component""\s*,\s*""wheels\.events\.SuperScopePrimer""\s*\)", trimmed)) {
						state.primerLine = state.lineNumber;
					}
					if (state.firstWoLine == 0 && FindNoCase("application.wo.", trimmed)) {
						state.firstWoLine = state.lineNumber;
					}
					if (state.firstCreateFromRootLine == 0 && FindNoCase("$createObjectFromRoot(", trimmed)) {
						state.firstCreateFromRootLine = state.lineNumber;
					}
				}
				expect(state.inInit).toBeTrue("expected to find $init in onapplicationstart.cfc");
				expect(state.primerLine > 0).toBeTrue(
					"onapplicationstart.$init must create wheels.events.SuperScopePrimer (##3730)."
				);
				expect(state.primerLine).toBe(
					state.firstStatementLine,
					"Creating the primer must be the first statement of onapplicationstart.$init."
				);
				expect(state.firstWoLine > state.primerLine).toBeTrue(
					"The primer must be created before the first application.wo call."
				);
				expect(state.firstCreateFromRootLine > state.primerLine).toBeTrue(
					"The primer must be created before $createObjectFromRoot creates wheels.Public."
				);
			});

		});

	}

}
