component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.testRunner = new cli.lucli.services.TestRunner(projectRoot = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("TestRunner Service", () => {

			describe("detectTestType()", () => {

				it("always returns app — vendor/wheels/tests existence is not a discriminator (##2318)", () => {
					// Both with and without vendor/wheels/tests, detectTestType
					// should return "app". Every Wheels app vendors the
					// framework's tests, so that signal is meaningless. Users
					// who explicitly want core tests pass --core (CLI) or
					// type:"core" (service).
					var withVendor = tempRoot & "/vendor/wheels/tests";
					directoryCreate(withVendor, true, true);
					var runner = new cli.lucli.services.TestRunner(projectRoot = tempRoot);
					expect(runner.detectTestType()).toBe("app");
				});

				it("returns app when vendor/wheels/tests does not exist", () => {
					// Use a temp dir without vendor/wheels/tests
					var cleanRoot = getTempDirectory() & "wheels-testrunner-" & createUUID();
					directoryCreate(cleanRoot, true);
					directoryCreate(cleanRoot & "/tests/specs", true);

					var runner = new cli.lucli.services.TestRunner(projectRoot = cleanRoot);
					var result = runner.detectTestType();
					expect(result).toBe("app");

					// Cleanup
					directoryDelete(cleanRoot, true);
				});

			});

			describe("resolveTestDirectory()", () => {

				it("returns core test directory for core type", () => {
					var result = testRunner.resolveTestDirectory(type = "core");
					expect(result).toInclude("wheels");
					expect(result).toInclude("tests");
					expect(result).toInclude("specs");
				});

				it("returns app test directory for app type", () => {
					var result = testRunner.resolveTestDirectory(type = "app");
					expect(result).toInclude("tests");
					expect(result).toInclude("specs");
				});

				it("appends filter to directory path", () => {
					var result = testRunner.resolveTestDirectory(type = "core", filter = "model");
					expect(result).toInclude("model");
				});

				it("appends filter for app type", () => {
					var result = testRunner.resolveTestDirectory(type = "app", filter = "controllers");
					expect(result).toInclude("controllers");
				});

			});

			describe("runViaHttp()", () => {

				it("returns error struct when no server is running on bogus port", () => {
					var result = testRunner.runViaHttp(serverPort = 59999);
					expect(result.success).toBeFalse();
					expect(structKeyExists(result, "message")).toBeTrue();
				});

			});

			describe("countSpecsOnDisk()", () => {

				it("returns the count of *Spec.cfc files in the requested dotted directory", () => {
					// Arrange — drop two specs into a temp tests/specs/models dir.
					var specsDir = tempRoot & "/tests/specs/countme";
					directoryCreate(specsDir, true, true);
					fileWrite(specsDir & "/AlphaSpec.cfc", "component {}");
					fileWrite(specsDir & "/BetaSpec.cfc",  "component {}");
					// A non-Spec file should not be counted.
					fileWrite(specsDir & "/Helper.cfc", "component {}");

					var runner = new cli.lucli.services.TestRunner(projectRoot = tempRoot);
					expect(runner.countSpecsOnDisk("tests.specs.countme")).toBe(2);
				});

				it("returns 0 for a missing directory", () => {
					var runner = new cli.lucli.services.TestRunner(projectRoot = tempRoot);
					expect(runner.countSpecsOnDisk("tests.specs.does.not.exist")).toBe(0);
				});

			});

			describe("listSpecsOnDisk()", () => {

				it("returns dotted bundle names for every *Spec.cfc on disk", () => {
					var specsDir = tempRoot & "/tests/specs/listme";
					directoryCreate(specsDir, true, true);
					fileWrite(specsDir & "/OneSpec.cfc", "component {}");
					fileWrite(specsDir & "/TwoSpec.cfc", "component {}");

					var runner = new cli.lucli.services.TestRunner(projectRoot = tempRoot);
					var names = runner.listSpecsOnDisk("tests.specs.listme");
					expect(arrayLen(names)).toBe(2);
					expect(arrayContains(names, "tests.specs.listme.OneSpec")).toBeTrue();
					expect(arrayContains(names, "tests.specs.listme.TwoSpec")).toBeTrue();
				});

				it("returns empty array for a missing directory", () => {
					var runner = new cli.lucli.services.TestRunner(projectRoot = tempRoot);
					expect(runner.listSpecsOnDisk("tests.specs.does.not.exist")).toHaveLength(0);
				});

			});

		});

	}

}
