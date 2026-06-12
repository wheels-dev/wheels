component extends="wheels.WheelsTest" {

	/*
	 * Regression spec for issue #3083.
	 *
	 * Both test-runner endpoints accept url.directory and validate it against an
	 * allowlist. When the value is rejected the runner SILENTLY substitutes the
	 * default root and runs the entire suite reporting green; when an accepted
	 * value names a single spec FILE, TestBox discovers 0 bundles and also reports
	 * green. Neither failure mode was observable from the response.
	 *
	 * The fix makes scope resolution observable: resolveScope() records whether the
	 * requested directory was rejected, scopeWarnings() turns a rejection or a
	 * 0-bundle discovery into a human/CI-readable warning, and injectScopeMetadata()
	 * threads directoryRequested / directoryResolved / directoryRejected /
	 * bundlesDiscovered / warnings into the JSON payload without dropping any of the
	 * runner's existing keys.
	 */

	// Core endpoint allowlist (vendor/wheels/tests/runner.cfm).
	variables.CORE_DEFAULT = "wheels.tests.specs";
	variables.CORE_PATTERN = "^(wheels\.tests|vendor\.[a-z0-9][a-z0-9\-]*\.tests)(\.[a-zA-Z0-9_]+)*$";

	function run() {

		describe("test-runner scope visibility (issue 3083)", () => {

			describe("resolveScope — app allowlist (^tests...)", () => {

				it("resolves an accepted directory and marks it not rejected", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = resolver.resolveScope(url = { directory: "tests.specs.models" });
					expect(scope.requested).toBe("tests.specs.models");
					expect(scope.resolved).toBe("tests.specs.models");
					expect(scope.rejected).toBeFalse();
				});

				it("records the silent fallback when a bare short name is rejected", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = resolver.resolveScope(url = { directory: "models" });
					expect(scope.requested).toBe("models");
					expect(scope.resolved).toBe("tests.specs");
					expect(scope.rejected).toBeTrue();
				});

				it("treats a missing directory key as a clean default, not a rejection", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = resolver.resolveScope(url = {});
					expect(scope.requested).toBe("");
					expect(scope.resolved).toBe("tests.specs");
					expect(scope.rejected).toBeFalse();
				});

			});

			describe("resolveScope — core allowlist (wheels.tests / vendor.<pkg>.tests)", () => {

				it("accepts a fully-qualified core path", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = resolver.resolveScope(
						url = { directory: "wheels.tests.specs.model" },
						defaultDirectory = variables.CORE_DEFAULT,
						allowlistPattern = variables.CORE_PATTERN
					);
					expect(scope.resolved).toBe("wheels.tests.specs.model");
					expect(scope.rejected).toBeFalse();
				});

				it("rejects an app-shaped path on the core endpoint and falls back to the full core suite", () => {
					// This is the exact repro from the issue: directory=tests.specs.model
					// against /wheels/core/tests ran 314 bundles / 4420 passes silently.
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = resolver.resolveScope(
						url = { directory: "tests.specs.model" },
						defaultDirectory = variables.CORE_DEFAULT,
						allowlistPattern = variables.CORE_PATTERN
					);
					expect(scope.requested).toBe("tests.specs.model");
					expect(scope.resolved).toBe("wheels.tests.specs");
					expect(scope.rejected).toBeTrue();
				});

			});

			describe("scopeWarnings", () => {

				it("warns when the requested directory was rejected", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = resolver.resolveScope(
						url = { directory: "tests.specs.model" },
						defaultDirectory = variables.CORE_DEFAULT,
						allowlistPattern = variables.CORE_PATTERN
					);
					var warnings = resolver.scopeWarnings(scope = scope, bundlesDiscovered = 314);
					expect(arrayLen(warnings)).toBeGT(0);
					expect(warnings[1]).toInclude("tests.specs.model");
				});

				it("warns when an accepted scope discovers zero bundles (the green single-file trap)", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = resolver.resolveScope(url = { directory: "tests.specs.models.UserSpec" });
					expect(scope.rejected).toBeFalse();
					var warnings = resolver.scopeWarnings(scope = scope, bundlesDiscovered = 0);
					expect(arrayLen(warnings)).toBe(1);
					expect(warnings[1]).toInclude("No test bundles");
				});

				it("emits no warnings for a clean, populated run", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = resolver.resolveScope(url = { directory: "tests.specs" });
					var warnings = resolver.scopeWarnings(scope = scope, bundlesDiscovered = 48);
					expect(arrayLen(warnings)).toBe(0);
				});

			});

			describe("injectScopeMetadata", () => {

				it("splices visibility fields into the JSON payload without dropping existing keys", () => {
					var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
					var scope = resolver.resolveScope(url = { directory: "models" });
					var warnings = resolver.scopeWarnings(scope = scope, bundlesDiscovered = 314);
					var payload = '{"totalPass":4420,"totalFail":0,"labels":[]}';
					var merged = resolver.injectScopeMetadata(
						resultJson = payload,
						scope = scope,
						bundlesDiscovered = 314,
						warnings = warnings
					);
					var parsed = DeserializeJSON(merged);
					// Original keys survive untouched.
					expect(parsed.totalPass).toBe(4420);
					expect(parsed.totalFail).toBe(0);
					// New visibility fields are present.
					expect(parsed.directoryRequested).toBe("models");
					expect(parsed.directoryResolved).toBe("tests.specs");
					expect(parsed.directoryRejected).toBeTrue();
					expect(parsed.bundlesDiscovered).toBe(314);
					expect(arrayLen(parsed.warnings)).toBeGT(0);
				});

			});

		});

	}

}
