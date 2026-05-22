component extends="wheels.WheelsTest" {

	function run() {

		describe("Reload — global includes mtime tracking (issue ##2792)", () => {

			var g = application.wo;
			var baseDir = ExpandPath("/wheels/tests/_tmp/reloadGlobals");

			beforeEach(() => {
				if (DirectoryExists(baseDir)) {
					DirectoryDelete(baseDir, true);
				}
				// DirectoryCreate(path, true) is Lucee-only (issue ##2567);
				// java.io.File.mkdirs() recurses parents on every engine.
				CreateObject("java", "java.io.File").init(baseDir).mkdirs();
			});

			afterEach(() => {
				if (DirectoryExists(baseDir)) {
					DirectoryDelete(baseDir, true);
				}
			});

			it("$snapshotGlobalIncludes returns a struct keyed by cfm file paths", () => {
				FileWrite(baseDir & "/fixtureA.cfm", "<cfscript>function fxA(){return 1;}</cfscript>");
				FileWrite(baseDir & "/fixtureB.cfm", "<cfscript>function fxB(){return 2;}</cfscript>");
				var snapshot = g.$snapshotGlobalIncludes(directory = baseDir);
				expect(snapshot).toBeStruct();
				expect(StructCount(snapshot)).toBe(2);
			});

			it("$snapshotGlobalIncludes returns an empty struct when the directory does not exist", () => {
				var missing = baseDir & "/does-not-exist";
				var snapshot = g.$snapshotGlobalIncludes(directory = missing);
				expect(snapshot).toBeStruct();
				expect(StructCount(snapshot)).toBe(0);
			});

			it("$globalIncludesChanged returns false when no files changed", () => {
				FileWrite(baseDir & "/stable.cfm", "<cfscript>function fxStable(){return 'stable';}</cfscript>");
				var snapshot = g.$snapshotGlobalIncludes(directory = baseDir);
				expect(g.$globalIncludesChanged(snapshot = snapshot, directory = baseDir)).toBeFalse();
			});

			it("$globalIncludesChanged returns true when a new cfm file appears", () => {
				FileWrite(baseDir & "/one.cfm", "<cfscript>function fxOne(){return 1;}</cfscript>");
				var snapshot = g.$snapshotGlobalIncludes(directory = baseDir);
				FileWrite(baseDir & "/two.cfm", "<cfscript>function fxTwo(){return 2;}</cfscript>");
				expect(g.$globalIncludesChanged(snapshot = snapshot, directory = baseDir)).toBeTrue();
			});

			it("$globalIncludesChanged returns true when a tracked cfm file is removed", () => {
				FileWrite(baseDir & "/keep.cfm", "<cfscript>function fxKeep(){return 1;}</cfscript>");
				FileWrite(baseDir & "/gone.cfm", "<cfscript>function fxGone(){return 2;}</cfscript>");
				var snapshot = g.$snapshotGlobalIncludes(directory = baseDir);
				FileDelete(baseDir & "/gone.cfm");
				expect(g.$globalIncludesChanged(snapshot = snapshot, directory = baseDir)).toBeTrue();
			});

			it("$globalIncludesChanged tolerates an empty starting snapshot", () => {
				var snapshot = {};
				FileWrite(baseDir & "/added.cfm", "<cfscript>function fxAdded(){return 1;}</cfscript>");
				expect(g.$globalIncludesChanged(snapshot = snapshot, directory = baseDir)).toBeTrue();
			});

			it("$reincludeGlobals re-evaluates the target cfm without throwing", () => {
				// CFML's `include` resolves via mappings, not absolute filesystem
				// paths — call $reincludeGlobals with the mapping-relative form.
				var mappingPath = "/wheels/tests/_tmp/reloadGlobals/reinclude.cfm";
				var absPath = ExpandPath(mappingPath);
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
				// that the bare ?reload=true workflow targets.
				FileWrite(absPath, "<cfscript>function fxReinclude(){return 'second';}</cfscript>");
				$assert.notThrows(function() {
					application.wo.$reincludeGlobals(file = "/wheels/tests/_tmp/reloadGlobals/reinclude.cfm");
				});
				expect(IsDefined("application.wo.fxReinclude")).toBeTrue();
			});

		});
	}
}
