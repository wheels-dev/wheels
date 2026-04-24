/**
 * Regression coverage for GH #2279.
 *
 * `wheels new` copies vendor/wheels/ from whatever source `resolveFrameworkSource`
 * finds. In a dev checkout of the wheels-dev/wheels monorepo that source carries
 * an unreplaced "@build.version@" placeholder in box.json — the release build
 * pipeline substitutes it, but a raw checkout does not. Without rewrite, the
 * placeholder propagates into the generated app and the homepage reports
 * "0.0.0-dev" forever.
 *
 * These specs exercise FrameworkInstaller.rewriteVersionPlaceholder in isolation
 * via the filesystem: we stand up a fake monorepo layout in a temp dir, run the
 * helper, and assert the copy's placeholder was substituted with
 * "<rootversion>-dev". The service is isolated from Module.cfc so tests don't
 * need a `modules.BaseModule` mapping.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.installer = new cli.lucli.services.FrameworkInstaller();
	}

	private struct function buildFixture(required string rootBoxContent, required string frameworkBoxContent) {
		var fixture = {};
		fixture.root = getTempDirectory() & "wheels-fw-fixture-#createUUID()#";
		fixture.sourceWheels = fixture.root & "/vendor/wheels";
		fixture.targetWheels = fixture.root & "/target/vendor/wheels";
		directoryCreate(fixture.sourceWheels, true, true);
		directoryCreate(fixture.targetWheels, true, true);
		fileWrite(fixture.root & "/box.json", arguments.rootBoxContent);
		fileWrite(fixture.sourceWheels & "/box.json", arguments.frameworkBoxContent);
		// Simulate the directoryCopy() that copyFrameworkToVendor already did:
		// the target starts with the same placeholder as the source.
		fileWrite(fixture.targetWheels & "/box.json", arguments.frameworkBoxContent);
		return fixture;
	}

	function run() {

		describe("FrameworkInstaller.rewriteVersionPlaceholder (GH ##2279)", () => {

			it("substitutes the placeholder with <rootversion>-dev when source is the wheels monorepo (slug match)", () => {
				var f = buildFixture(
					'{"name":"Wheels.fw","slug":"wheels","version":"4.0.0"}',
					'{"version":"@build.version@"}'
				);
				var rewrote = installer.rewriteVersionPlaceholder(f.sourceWheels, f.targetWheels);
				var after = deserializeJSON(fileRead(f.targetWheels & "/box.json"));
				expect(rewrote).toBeTrue();
				expect(after.version).toBe("4.0.0-dev");
				directoryDelete(f.root, true);
			});

			it("substitutes even when only the name marker matches (belt-and-suspenders)", () => {
				var f = buildFixture(
					'{"name":"Wheels.fw","version":"4.1.0"}',
					'{"version":"@build.version@"}'
				);
				var rewrote = installer.rewriteVersionPlaceholder(f.sourceWheels, f.targetWheels);
				var after = deserializeJSON(fileRead(f.targetWheels & "/box.json"));
				expect(rewrote).toBeTrue();
				expect(after.version).toBe("4.1.0-dev");
				directoryDelete(f.root, true);
			});

			it("leaves the placeholder untouched when the enclosing box.json does not identify the monorepo", () => {
				var f = buildFixture(
					'{"name":"SomeUserApp","slug":"user-app","version":"2.1.0"}',
					'{"version":"@build.version@"}'
				);
				var rewrote = installer.rewriteVersionPlaceholder(f.sourceWheels, f.targetWheels);
				expect(rewrote).toBeFalse();
				expect(fileRead(f.targetWheels & "/box.json")).toInclude("@build.version@");
				directoryDelete(f.root, true);
			});

			it("no-ops when the framework box.json already has a real version (released bundle)", () => {
				var f = buildFixture(
					'{"name":"Wheels.fw","slug":"wheels","version":"4.0.0"}',
					'{"version":"4.0.0"}'
				);
				var rewrote = installer.rewriteVersionPlaceholder(f.sourceWheels, f.targetWheels);
				var after = deserializeJSON(fileRead(f.targetWheels & "/box.json"));
				expect(rewrote).toBeFalse();
				expect(after.version).toBe("4.0.0");
				directoryDelete(f.root, true);
			});

			it("no-ops when the monorepo root box.json is also unreplaced (pathological both-placeholder)", () => {
				var f = buildFixture(
					'{"name":"Wheels.fw","slug":"wheels","version":"@build.version@"}',
					'{"version":"@build.version@"}'
				);
				var rewrote = installer.rewriteVersionPlaceholder(f.sourceWheels, f.targetWheels);
				expect(rewrote).toBeFalse();
				expect(fileRead(f.targetWheels & "/box.json")).toInclude("@build.version@");
				directoryDelete(f.root, true);
			});

			it("no-ops when the source's enclosing directory has no box.json (unusual third-party layout)", () => {
				var root = getTempDirectory() & "wheels-fw-noroot-#createUUID()#";
				var sourceWheels = root & "/vendor/wheels";
				var targetWheels = root & "/target/vendor/wheels";
				directoryCreate(sourceWheels, true, true);
				directoryCreate(targetWheels, true, true);
				var placeholder = '{"version":"@build.version@"}';
				fileWrite(sourceWheels & "/box.json", placeholder);
				fileWrite(targetWheels & "/box.json", placeholder);
				var rewrote = installer.rewriteVersionPlaceholder(sourceWheels, targetWheels);
				expect(rewrote).toBeFalse();
				expect(fileRead(targetWheels & "/box.json")).toInclude("@build.version@");
				directoryDelete(root, true);
			});

		});

	}

}
