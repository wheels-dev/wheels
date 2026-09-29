component extends="wheels.WheelsTest" {

	/*
	 * Regression spec for issue 3759.
	 *
	 * Both test-runner endpoints treated directory= as a folder only. A dotted
	 * path naming one spec FILE passed the allowlist, discovered 0 bundles, and
	 * (before the CLI read the 3083 warnings) reported green. resolveScope() now
	 * recognizes a path that names an existing spec .cfc and records it as the
	 * single bundle to run; testBoxArgs() turns the scope into the TestBox
	 * constructor arguments both runners use.
	 */

	variables.CORE_DEFAULT = "wheels.tests.specs";
	variables.CORE_PATTERN = "^(wheels\.tests|vendor\.[a-z0-9][a-z0-9\-]*\.tests)(\.[a-zA-Z0-9_]+)*$";
	// An existing spec file and its folder, used as real fixtures.
	variables.FILE_SCOPE = "wheels.tests.specs.dispatch.TestScopeVisibilitySpec";
	variables.DIR_SCOPE = "wheels.tests.specs.dispatch";

	private struct function $coreScope(required string directory) {
		var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
		return resolver.resolveScope(
			url = {directory: arguments.directory},
			defaultDirectory = variables.CORE_DEFAULT,
			allowlistPattern = variables.CORE_PATTERN
		);
	}

	function run() {

		describe("single spec file scopes (issue 3759)", () => {

			describe("resolveScope", () => {

				it("records a dotted path to an existing spec file as the single bundle", () => {
					var scope = $coreScope(variables.FILE_SCOPE);
					expect(scope.bundle).toBe(variables.FILE_SCOPE);
					expect(scope.rejected).toBeFalse();
				});

				it("resolves the directory of a single spec file to its folder", () => {
					var scope = $coreScope(variables.FILE_SCOPE);
					expect(scope.resolved).toBe(variables.DIR_SCOPE);
				});

				it("leaves the bundle empty for a directory scope", () => {
					var scope = $coreScope(variables.DIR_SCOPE);
					expect(scope.bundle).toBe("");
					expect(scope.resolved).toBe(variables.DIR_SCOPE);
				});

				it("leaves the bundle empty when no such spec file exists", () => {
					var scope = $coreScope("wheels.tests.specs.dispatch.NoSuchSpecAnywhere");
					expect(scope.bundle).toBe("");
					expect(scope.resolved).toBe("wheels.tests.specs.dispatch.NoSuchSpecAnywhere");
				});

				it("never resolves a bundle for a rejected directory", () => {
					var scope = $coreScope("wheels.lib.Something");
					expect(scope.rejected).toBeTrue();
					expect(scope.bundle).toBe("");
				});

			});

			describe("testBoxArgs", () => {

				it("hands TestBox only the single bundle for a spec-file scope", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var tbArgs = resolver.testBoxArgs($coreScope(variables.FILE_SCOPE));
					expect(tbArgs.bundles).toBe([variables.FILE_SCOPE]);
					expect(StructKeyExists(tbArgs, "directory")).toBeFalse();
				});

				it("hands TestBox the directory for a folder scope", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var tbArgs = resolver.testBoxArgs($coreScope(variables.DIR_SCOPE));
					expect(tbArgs.directory).toBe(variables.DIR_SCOPE);
					expect(StructKeyExists(tbArgs, "bundles")).toBeFalse();
				});

				it("discovers exactly one bundle when TestBox is built from a spec-file scope", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var tbArgs = resolver.testBoxArgs($coreScope(variables.FILE_SCOPE));
					var tb = new wheels.wheelstest.system.TestBox(argumentCollection = tbArgs);
					var found = tb.getBundles();
					expect(ArrayLen(found)).toBe(1);
					expect(found[1]).toBe(variables.FILE_SCOPE);
				});

			});

			describe("injectScopeMetadata", () => {

				it("reports the resolved bundle in the payload", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = $coreScope(variables.FILE_SCOPE);
					var out = DeserializeJSON(resolver.injectScopeMetadata(
						resultJson = '{"totalPass":3}',
						scope = scope,
						bundlesDiscovered = 1,
						warnings = []
					));
					expect(out.bundleResolved).toBe(variables.FILE_SCOPE);
					expect(out.totalPass).toBe(3);
				});

			});

		});

	}

}
