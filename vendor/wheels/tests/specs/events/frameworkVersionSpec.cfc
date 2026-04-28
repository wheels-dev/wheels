component extends="wheels.WheelsTest" {

	// Boot-time integration tests for application.wheels.version. The version
	// resolution logic itself lives in BuildInfo.cfc and is exercised in
	// services/BuildInfoSpec.cfc — these tests assert the integration with
	// onapplicationstart and the legacy $readFrameworkVersion delegate.

	function run() {

		g = application.wo;

		describe("Framework version resolution", () => {

			it("exposes application.wheels.version as a non-empty string after boot", () => {
				expect(StructKeyExists(application.wheels, "version")).toBeTrue();
				expect(Len(application.wheels.version) > 0).toBeTrue("application.wheels.version is empty");
			});

			it("does not expose the literal unreplaced build placeholder at runtime", () => {
				expect(application.wheels.version).notToBe("@build.version@");
			});

			it("caches a BuildInfo instance on application.wheels.buildInfo at boot", () => {
				expect(StructKeyExists(application.wheels, "buildInfo")).toBeTrue();
				expect(IsObject(application.wheels.buildInfo)).toBeTrue();
				expect(application.wheels.buildInfo.version()).toBe(application.wheels.version);
			});

			it("$readFrameworkVersion delegates to BuildInfo and returns the same string as application.wheels.version", () => {
				expect(g.$readFrameworkVersion()).toBe(application.wheels.version);
			});

		});

	}

}
