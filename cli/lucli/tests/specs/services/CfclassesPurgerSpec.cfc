/**
 * Regression coverage for onboarding finding F5 — `wheels reload` was not
 * invalidating Lucee's compiled-class cache, so source edits to models and
 * controllers silently missed until cfclasses was physically wiped.
 * CfclassesPurger is what `wheels reload` delegates to before triggering
 * the framework's `?reload=true` handler.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.purger = new cli.lucli.services.CfclassesPurger();
	}

	private string function makeTempCfclassesDir() {
		var root = getTempDirectory() & "wheels-cfclasses-#createUUID()#";
		directoryCreate(root, true);
		// Mirror the typical Lucee layout — class files at root, RPC subdir
		// for ephemeral compiled CFCs, classloader-resources.json metadata.
		fileWrite(root & "/Application_cfc$cf.class", "fake compiled class");
		fileWrite(root & "/Post_cfc$cf.class", "fake compiled class");
		directoryCreate(root & "/RPC/abc123", true);
		fileWrite(root & "/RPC/abc123/PostsController_cfc$cf.class", "fake compiled class");
		fileWrite(root & "/RPC/abc123/classloader-resources.json", "{}");
		return root;
	}

	function run() {
		describe("CfclassesPurger.purge", () => {

			it("deletes every file and subdirectory inside the cfclasses dir", () => {
				var dir = makeTempCfclassesDir();
				try {
					var r = variables.purger.purge(dir);
					expect(arrayLen(r.purged)).toBe(3); // 2 .class files + 1 RPC dir
					expect(arrayLen(r.failed)).toBe(0);
					expect(directoryExists(dir)).toBeTrue(); // dir itself preserved
					expect(arrayLen(directoryList(dir, false, "name"))).toBe(0);
				} finally {
					if (directoryExists(dir)) directoryDelete(dir, true);
				}
			});

			it("preserves the cfclasses directory itself so Lucee can repopulate it", () => {
				var dir = makeTempCfclassesDir();
				try {
					variables.purger.purge(dir);
					expect(directoryExists(dir)).toBeTrue();
				} finally {
					if (directoryExists(dir)) directoryDelete(dir, true);
				}
			});

			it("returns empty result when cfclassesDir is missing (server never started)", () => {
				var r = variables.purger.purge("/nonexistent/path/to/cfclasses");
				expect(arrayLen(r.purged)).toBe(0);
				expect(arrayLen(r.failed)).toBe(0);
			});

			it("returns empty result when cfclassesDir is an empty string", () => {
				var r = variables.purger.purge("");
				expect(arrayLen(r.purged)).toBe(0);
				expect(arrayLen(r.failed)).toBe(0);
			});

			it("is idempotent — purging an already-empty dir is a no-op", () => {
				var dir = getTempDirectory() & "wheels-cfclasses-empty-#createUUID()#";
				directoryCreate(dir, true);
				try {
					var r = variables.purger.purge(dir);
					expect(arrayLen(r.purged)).toBe(0);
					expect(arrayLen(r.failed)).toBe(0);
					expect(directoryExists(dir)).toBeTrue();
				} finally {
					if (directoryExists(dir)) directoryDelete(dir, true);
				}
			});
		});
	}
}
