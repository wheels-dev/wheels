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

		describe("$includeConfig — config-template failures must not crash app start (issue ##3063)", () => {

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

			it("does not propagate a failure thrown by a config template", () => {
				// Reproduces the #3063 class of failure: a config/*.cfm file that
				// fails to compile or run (on Adobe CF a top-level `var di = ...` in
				// config/services.cfm is a compile error) is included during
				// onApplicationStart. Before the fix the failure cascaded out of
				// $includeConfig, aborting application start and surfacing as a
				// masked app-wide HTTP 500. A runtime throw stands in for the
				// engine-specific compile error so the regression is portable.
				// Referencing an undefined variable throws at runtime on every
				// engine — a portable stand-in for the engine-specific compile
				// failure, and it avoids nested quotes in the fixture body.
				FileWrite(
					ctx.baseDir & "/badconfig.cfm",
					"<cfscript>writeOutput(undefinedConfigVarXyz);</cfscript>"
				);
				$assert.notThrows(function() {
					ctx.g.$includeConfig(template = ctx.mapping & "/badconfig.cfm");
				});
			});

			it("still executes a valid config template body after the fix", () => {
				// Guards against the hardening swallowing the happy path: a healthy
				// config file must still run, so its registrations take effect.
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

			it("recovers and keeps loading later config after one file fails", () => {
				// A failing file must not poison subsequent $includeConfig calls —
				// the environment-specific services.cfm include should still run
				// even if the base file blew up.
				FileWrite(
					ctx.baseDir & "/badconfig.cfm",
					"<cfscript>writeOutput(undefinedConfigVarXyz);</cfscript>"
				);
				FileWrite(
					ctx.baseDir & "/goodconfig.cfm",
					"<cfscript>request.$includeConfigSpecRan = true;</cfscript>"
				);
				$assert.notThrows(function() {
					ctx.g.$includeConfig(template = ctx.mapping & "/badconfig.cfm");
					ctx.g.$includeConfig(template = ctx.mapping & "/goodconfig.cfm");
				});
				expect(StructKeyExists(request, "$includeConfigSpecRan")).toBeTrue();
			});

		});
	}
}
