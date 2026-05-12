component extends="wheels.WheelsTest" {

	function run() {

		describe("app-runner test directory resolution (issue 2489)", () => {

			it("defaults to tests.specs when url has no directory key", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = {})).toBe("tests.specs");
			});

			it("defaults to tests.specs when url.directory is empty string", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "" })).toBe("tests.specs");
			});

			it("defaults to tests.specs when url.directory is whitespace only", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "   " })).toBe("tests.specs");
			});

			it("accepts the bare 'tests' root", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "tests" })).toBe("tests");
			});

			it("accepts 'tests.specs'", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "tests.specs" })).toBe("tests.specs");
			});

			it("accepts 'tests.specs.models' (the canonical short-filter target)", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "tests.specs.models" }))
					.toBe("tests.specs.models");
			});

			it("accepts deeply nested paths down to a spec class", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "tests.specs.models.UserSpec" }))
					.toBe("tests.specs.models.UserSpec");
			});

			it("accepts segments containing underscores and digits", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "tests.specs.api_v2.User_Profile1" }))
					.toBe("tests.specs.api_v2.User_Profile1");
			});

			it("trims surrounding whitespace before validating", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "  tests.specs.models  " }))
					.toBe("tests.specs.models");
			});

			it("rejects bare short names (the silent-fallback trap)", () => {
				// The whole reason $normalizeTestFilter exists on the CLI side:
				// passing the bare name through here silently runs every spec,
				// which is exactly the surface the original issue reporter hit.
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "models" })).toBe("tests.specs");
				expect(resolver.resolveDirectory(url = { directory: "controllers" })).toBe("tests.specs");
				expect(resolver.resolveDirectory(url = { directory: "browser" })).toBe("tests.specs");
			});

			it("rejects paths that escape the tests namespace", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				// The security guarantee: only `tests.*` mappings are accepted,
				// so a caller cannot use this endpoint to compile arbitrary CFCs.
				expect(resolver.resolveDirectory(url = { directory: "wheels.tests.specs" })).toBe("tests.specs");
				expect(resolver.resolveDirectory(url = { directory: "vendor.wheels.lib" })).toBe("tests.specs");
				expect(resolver.resolveDirectory(url = { directory: "app.models" })).toBe("tests.specs");
			});

			it("rejects paths containing slashes", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "tests/specs/models" })).toBe("tests.specs");
				expect(resolver.resolveDirectory(url = { directory: "tests\specs\models" })).toBe("tests.specs");
			});

			it("rejects paths containing hyphens or other punctuation", () => {
				var resolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
				expect(resolver.resolveDirectory(url = { directory: "tests.specs.user-spec" })).toBe("tests.specs");
				expect(resolver.resolveDirectory(url = { directory: "tests.specs;" })).toBe("tests.specs");
				expect(resolver.resolveDirectory(url = { directory: "tests..specs" })).toBe("tests.specs");
				expect(resolver.resolveDirectory(url = { directory: "tests." })).toBe("tests.specs");
			});

		});

	}

}
