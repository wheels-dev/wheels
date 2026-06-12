component extends="wheels.WheelsTest" {

	function run() {

		// Shared struct so nested describe / beforeEach / afterEach / it closures
		// can read `g` and `baseDir` on Adobe CF 2023/2025. CFML closures cannot
		// reach an enclosing function's `local` scope on Adobe CF (CLAUDE.md
		// cross-engine invariant ##3); a struct is a reference type, so all
		// closures share the same object via `variables.ctx`.
		//
		// $includeConfig applies LCase() to the template path before including it,
		// so the on-disk fixture directory and filenames MUST be all-lowercase to
		// resolve on case-sensitive filesystems (Linux CI).
		var ctx = {
			g: application.wo,
			baseDir: ExpandPath("/wheels/tests/_tmp/includeconfig"),
			mapping: "/wheels/tests/_tmp/includeconfig"
		};

		describe("$includeConfig — config-template failures fail closed with a named error (issue ##3063)", () => {

			beforeEach(() => {
				if (DirectoryExists(ctx.baseDir)) {
					DirectoryDelete(ctx.baseDir, true);
				}
				// DirectoryCreate(path, true) is Lucee-only (issue ##2567);
				// java.io.File.mkdirs() recurses parents on every engine.
				CreateObject("java", "java.io.File").init(ctx.baseDir).mkdirs();
				StructDelete(request, "$includeConfigSpecRan");
			});

			afterEach(() => {
				if (DirectoryExists(ctx.baseDir)) {
					DirectoryDelete(ctx.baseDir, true);
				}
				StructDelete(request, "$includeConfigSpecRan");
			});

			it("rethrows a config-template failure as Wheels.ConfigIncludeFailed", () => {
				// Reproduces the ##3063 class of failure: a config/*.cfm file that
				// fails to compile or run (on Adobe CF a top-level `var di = ...` in
				// config/services.cfm is a compile error) is included during
				// onApplicationStart. The contract is fail-closed in EVERY
				// environment: the failure must surface as a NAMED, located error —
				// not the old masked app-wide 500, and not a silent boot on
				// framework defaults. A runtime throw (undefined-variable
				// reference) stands in for the engine-specific compile error so
				// the regression is portable to every CI engine.
				FileWrite(
					ctx.baseDir & "/badconfig.cfm",
					"<cfscript>writeOutput(undefinedConfigVarXyz);</cfscript>"
				);
				expect(function() {
					ctx.g.$includeConfig(template = ctx.mapping & "/badconfig.cfm");
				}).toThrow("Wheels.ConfigIncludeFailed");
			});

			it("names the failing template and preserves the original engine error (##3063 acceptance)", () => {
				// The whole point of ##3063: the developer must see WHAT broke,
				// WHERE, and WHY. The named error's message must carry the failing
				// template path plus the original engine message, and the original
				// exception type must survive into detail — a clear, located error
				// instead of the masked `Element WHEELS.ENGINEADAPTER is undefined`
				// secondary failure that used to hide the real cause.
				//
				// Cross-engine invariant ##11: `local.X = ...` inside catch does not
				// persist on BoxLang, so capture into a shared struct.
				FileWrite(
					ctx.baseDir & "/badconfig.cfm",
					"<cfscript>writeOutput(undefinedConfigVarXyz);</cfscript>"
				);
				var state = {caught = false, type = "", message = "", detail = ""};
				try {
					ctx.g.$includeConfig(template = ctx.mapping & "/badconfig.cfm");
				} catch (any e) {
					state.caught = true;
					state.type = e.type;
					state.message = e.message;
					state.detail = e.detail;
				}
				expect(state.caught).toBeTrue("expected $includeConfig to rethrow, but it returned normally (fail-open)");
				expect(state.type).toBe("Wheels.ConfigIncludeFailed");
				// Message names the failing template…
				expect(state.message).toInclude(ctx.mapping & "/badconfig.cfm");
				// …and carries the original engine message (every engine names the
				// undefined variable in its message).
				expect(state.message).toInclude("undefinedConfigVarXyz");
				// Original exception type is preserved in detail.
				expect(Len(state.detail)).toBeGT(0);
				expect(state.detail).toInclude("Original exception type:");
			});

			it("still executes a valid config template body (happy path unchanged)", () => {
				// Guards against the fail-closed contract breaking the happy path:
				// a healthy config file must still run, so its registrations take
				// effect, and must NOT throw.
				FileWrite(
					ctx.baseDir & "/goodconfig.cfm",
					"<cfscript>request.$includeConfigSpecRan = true;</cfscript>"
				);
				$assert.notThrows(function() {
					ctx.g.$includeConfig(template = ctx.mapping & "/goodconfig.cfm");
				});
				expect(StructKeyExists(request, "$includeConfigSpecRan")).toBeTrue();
				expect(request.$includeConfigSpecRan).toBeTrue();
			});

			it("a failing include does not poison a later, healthy include", () => {
				// $includeConfig holds no state between calls: after a failing file
				// throws (and the caller decides what to do with it), a subsequent
				// healthy include must still work. Note this is NOT log-and-continue
				// — the first call throws; app start would normally abort there.
				FileWrite(
					ctx.baseDir & "/badconfig.cfm",
					"<cfscript>writeOutput(undefinedConfigVarXyz);</cfscript>"
				);
				FileWrite(
					ctx.baseDir & "/goodconfig.cfm",
					"<cfscript>request.$includeConfigSpecRan = true;</cfscript>"
				);
				expect(function() {
					ctx.g.$includeConfig(template = ctx.mapping & "/badconfig.cfm");
				}).toThrow("Wheels.ConfigIncludeFailed");
				$assert.notThrows(function() {
					ctx.g.$includeConfig(template = ctx.mapping & "/goodconfig.cfm");
				});
				expect(StructKeyExists(request, "$includeConfigSpecRan")).toBeTrue();
			});

		});
	}
}
