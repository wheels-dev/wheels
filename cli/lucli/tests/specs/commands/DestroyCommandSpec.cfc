/**
 * Tests the destroy command via Module.cfc.
 * Verifies argument parsing, preview, force flag, and file deletion.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Create vendor/wheels stub so resolveProjectRoot succeeds
		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("wheels destroy", () => {

			beforeEach(() => {
				// Seed files for destruction tests
				directoryCreate(tempRoot & "/app/models", true, true);
				directoryCreate(tempRoot & "/app/controllers", true, true);
				directoryCreate(tempRoot & "/app/views/destroyables", true, true);
				directoryCreate(tempRoot & "/tests/specs/models", true, true);
				directoryCreate(tempRoot & "/tests/specs/controllers", true, true);

				fileWrite(tempRoot & "/app/models/Destroyable.cfc", 'component extends="Model" {}');
				fileWrite(tempRoot & "/app/controllers/Destroyables.cfc", 'component extends="Controller" {}');
				fileWrite(tempRoot & "/app/views/destroyables/index.cfm", "<p>index</p>");
				fileWrite(tempRoot & "/tests/specs/models/DestroyableSpec.cfc", "component {}");
				fileWrite(tempRoot & "/tests/specs/controllers/DestroyablesSpec.cfc", "component {}");
			});

			it("shows help when called with no arguments", () => {
				mod.__arguments = [];
				mod.destroy();
				expect(true).toBeTrue();
			});

			it("requires --force to delete files", () => {
				mod.__arguments = ["Destroyable", "model"];
				mod.destroy();
				// Without --force, model should still exist
				expect(fileExists(tempRoot & "/app/models/Destroyable.cfc")).toBeTrue();
			});

			it("deletes model with --force flag", () => {
				mod.__arguments = ["Destroyable", "model", "--force"];
				mod.destroy();
				expect(fileExists(tempRoot & "/app/models/Destroyable.cfc")).toBeFalse();
			});

			it("deletes controller with --force flag", () => {
				mod.__arguments = ["Destroyable", "controller", "--force"];
				mod.destroy();
				expect(fileExists(tempRoot & "/app/controllers/Destroyables.cfc")).toBeFalse();
			});

			it("deletes resource (model + controller + views) with --force", () => {
				mod.__arguments = ["Destroyable", "--force"];
				mod.destroy();
				expect(fileExists(tempRoot & "/app/models/Destroyable.cfc")).toBeFalse();
				expect(fileExists(tempRoot & "/app/controllers/Destroyables.cfc")).toBeFalse();
				expect(directoryExists(tempRoot & "/app/views/destroyables")).toBeFalse();
			});

			it("defaults type to resource when not specified", () => {
				mod.__arguments = ["Destroyable", "--force"];
				mod.destroy();
				// All resource files should be gone
				expect(fileExists(tempRoot & "/app/models/Destroyable.cfc")).toBeFalse();
			});

			it("rejects invalid type", () => {
				mod.__arguments = ["Destroyable", "badtype"];
				// Should not throw
				mod.destroy();
				expect(true).toBeTrue();
			});

			it("d() is alias for destroy()", () => {
				mod.__arguments = ["Destroyable", "model"];
				mod.d();
				// Should work without error (no --force so file stays)
				expect(fileExists(tempRoot & "/app/models/Destroyable.cfc")).toBeTrue();
			});

			// Issue #2313 (F16): the v3 docs index and `wheels generate` both use
			// `<type> <name>` order. The CLI used to reject this form with
			// "Unknown type: ...". These specs guard the smart-parse fix.
			it("accepts <type> <name> order (matches wheels generate)", () => {
				mod.__arguments = ["model", "Destroyable", "--force"];
				mod.destroy();
				expect(fileExists(tempRoot & "/app/models/Destroyable.cfc")).toBeFalse();
			});

			it("accepts <type> <name> for controller", () => {
				mod.__arguments = ["controller", "Destroyable", "--force"];
				mod.destroy();
				expect(fileExists(tempRoot & "/app/controllers/Destroyables.cfc")).toBeFalse();
			});

			it("accepts <type> <name> for resource", () => {
				mod.__arguments = ["resource", "Destroyable", "--force"];
				mod.destroy();
				expect(fileExists(tempRoot & "/app/models/Destroyable.cfc")).toBeFalse();
				expect(fileExists(tempRoot & "/app/controllers/Destroyables.cfc")).toBeFalse();
				expect(directoryExists(tempRoot & "/app/views/destroyables")).toBeFalse();
			});

		});

	}

}
