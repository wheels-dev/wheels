component extends="wheels.WheelsTest" {

	function run() {

		// Shared struct so nested describe / beforeEach / afterEach / it closures
		// can read `g` and `baseDir` on Adobe CF 2023/2025. CFML closures cannot
		// reach an enclosing function's `local` scope on Adobe CF (CLAUDE.md
		// cross-engine invariant ##3); a struct is a reference type, so all
		// closures share the same object via `variables.ctx`.
		var ctx = {
			g: application.wo,
			baseDir: ExpandPath("/wheels/tests/_tmp/reloadGlobals")
		};

		describe("Reload — global includes mtime tracking (issue ##2792)", () => {

			beforeEach(() => {
				if (DirectoryExists(ctx.baseDir)) {
					DirectoryDelete(ctx.baseDir, true);
				}
				// DirectoryCreate(path, true) is Lucee-only (issue ##2567);
				// java.io.File.mkdirs() recurses parents on every engine.
				CreateObject("java", "java.io.File").init(ctx.baseDir).mkdirs();
			});

			afterEach(() => {
				if (DirectoryExists(ctx.baseDir)) {
					DirectoryDelete(ctx.baseDir, true);
				}
			});

			it("$snapshotGlobalIncludes returns a struct keyed by cfm file paths", () => {
				FileWrite(ctx.baseDir & "/fixtureA.cfm", "<cfscript>function fxA(){return 1;}</cfscript>");
				FileWrite(ctx.baseDir & "/fixtureB.cfm", "<cfscript>function fxB(){return 2;}</cfscript>");
				var snapshot = ctx.g.$snapshotGlobalIncludes(directory = ctx.baseDir);
				expect(snapshot).toBeStruct();
				expect(StructCount(snapshot)).toBe(2);
			});

			it("$snapshotGlobalIncludes returns an empty struct when the directory does not exist", () => {
				var missing = ctx.baseDir & "/does-not-exist";
				var snapshot = ctx.g.$snapshotGlobalIncludes(directory = missing);
				expect(snapshot).toBeStruct();
				expect(StructCount(snapshot)).toBe(0);
			});

			it("$globalIncludesChanged returns false when no files changed", () => {
				FileWrite(ctx.baseDir & "/stable.cfm", "<cfscript>function fxStable(){return 'stable';}</cfscript>");
				var snapshot = ctx.g.$snapshotGlobalIncludes(directory = ctx.baseDir);
				expect(ctx.g.$globalIncludesChanged(snapshot = snapshot, directory = ctx.baseDir)).toBeFalse();
			});

			it("$globalIncludesChanged returns true when a new cfm file appears", () => {
				FileWrite(ctx.baseDir & "/one.cfm", "<cfscript>function fxOne(){return 1;}</cfscript>");
				var snapshot = ctx.g.$snapshotGlobalIncludes(directory = ctx.baseDir);
				FileWrite(ctx.baseDir & "/two.cfm", "<cfscript>function fxTwo(){return 2;}</cfscript>");
				expect(ctx.g.$globalIncludesChanged(snapshot = snapshot, directory = ctx.baseDir)).toBeTrue();
			});

			it("$globalIncludesChanged returns true when a tracked cfm file is removed", () => {
				FileWrite(ctx.baseDir & "/keep.cfm", "<cfscript>function fxKeep(){return 1;}</cfscript>");
				FileWrite(ctx.baseDir & "/gone.cfm", "<cfscript>function fxGone(){return 2;}</cfscript>");
				var snapshot = ctx.g.$snapshotGlobalIncludes(directory = ctx.baseDir);
				FileDelete(ctx.baseDir & "/gone.cfm");
				expect(ctx.g.$globalIncludesChanged(snapshot = snapshot, directory = ctx.baseDir)).toBeTrue();
			});

			it("$globalIncludesChanged tolerates an empty starting snapshot", () => {
				var snapshot = {};
				FileWrite(ctx.baseDir & "/added.cfm", "<cfscript>function fxAdded(){return 1;}</cfscript>");
				expect(ctx.g.$globalIncludesChanged(snapshot = snapshot, directory = ctx.baseDir)).toBeTrue();
			});

			it("$globalIncludesChanged returns true when a tracked cfm file is modified", () => {
				// Exercise the DateCompare != 0 branch — the "developer edited
				// an existing helper" path the PR is designed to serve.
				// Backdate the snapshot entry rather than sleeping for a fresh
				// mtime, so the test is deterministic across filesystems with
				// different mtime granularities (ext4 nanosecond vs APFS/HFS+
				// 1-second).
				FileWrite(ctx.baseDir & "/modified.cfm", "<cfscript>function fxV1(){return 1;}</cfscript>");
				var snapshot = ctx.g.$snapshotGlobalIncludes(directory = ctx.baseDir);
				var key = ListFirst(StructKeyList(snapshot));
				snapshot[key] = DateAdd("s", -60, snapshot[key]);
				expect(ctx.g.$globalIncludesChanged(snapshot = snapshot, directory = ctx.baseDir)).toBeTrue();
			});

			it("$reincludeGlobals re-evaluates the target cfm without throwing", () => {
				// CFML's `include` resolves via mappings, not absolute filesystem
				// paths — call $reincludeGlobals with the mapping-relative form.
				var absPath = ExpandPath("/wheels/tests/_tmp/reloadGlobals/reinclude.cfm");
				FileWrite(absPath, "<cfscript>function fxReinclude(){return 'first';}</cfscript>");
				$assert.notThrows(function() {
					application.wo.$reincludeGlobals(file = "/wheels/tests/_tmp/reloadGlobals/reinclude.cfm");
				});
				// The contract: re-including must make the function callable
				// on application.wo. Without this assertion, a silent no-op
				// on any engine would slip through.
				expect(IsDefined("application.wo.fxReinclude")).toBeTrue();

				// After overwriting the file, re-running the include should also
				// succeed — covers the "developer just changed a helper" path
				// that the bare ?reload=true workflow targets. Assert the
				// *return value* changes so an Adobe-only silent no-op (the
				// old version stays bound to `this`) can't slip past CI.
				FileWrite(absPath, "<cfscript>function fxReinclude(){return 'second';}</cfscript>");
				$assert.notThrows(function() {
					application.wo.$reincludeGlobals(file = "/wheels/tests/_tmp/reloadGlobals/reinclude.cfm");
				});
				expect(application.wo.fxReinclude()).toBe("second");
			});

		});
	}
}
