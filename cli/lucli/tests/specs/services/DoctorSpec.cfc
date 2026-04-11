component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Doctor Service", () => {

			it("reports HEALTHY for a valid project", () => {
				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(results.status).toBe("HEALTHY");
				expect(arrayLen(results.issues)).toBe(0);
			});

			it("reports CRITICAL when a required directory is missing", () => {
				// Remove app/controllers
				if (directoryExists(tempRoot & "/app/controllers")) {
					directoryDelete(tempRoot & "/app/controllers", true);
				}

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(results.status).toBe("CRITICAL");
				expect(arrayLen(results.issues)).toBeGT(0);

				var issueText = arrayToList(results.issues, " ");
				expect(issueText).toInclude("app/controllers");

				// Restore for subsequent tests
				directoryCreate(tempRoot & "/app/controllers", true);
			});

			it("reports WARNING when a recommended directory is missing", () => {
				// Remove tests/specs if it exists
				var specsDir = tempRoot & "/tests/specs";
				var existed = directoryExists(specsDir);
				if (existed) {
					directoryDelete(specsDir, true);
				}

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();

				// Should not be CRITICAL (no required dirs missing)
				expect(results.status).notToBe("CRITICAL");
				expect(arrayLen(results.warnings)).toBeGT(0);

				// Restore
				if (existed) {
					directoryCreate(specsDir, true);
				}
			});

			it("reports CRITICAL when a required file is missing", () => {
				var routesPath = tempRoot & "/config/routes.cfm";
				var routesContent = "";
				if (fileExists(routesPath)) {
					routesContent = fileRead(routesPath);
					fileDelete(routesPath);
				}

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(results.status).toBe("CRITICAL");

				// Restore
				if (len(routesContent)) {
					fileWrite(routesPath, routesContent);
				}
			});

			it("warns when config routes.cfm has minimal content", () => {
				var routesPath = tempRoot & "/config/routes.cfm";
				var original = fileRead(routesPath);
				fileWrite(routesPath, "// "); // less than 10 chars of content

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();

				var warningText = arrayToList(results.warnings, " ");
				expect(warningText).toInclude("routes.cfm");

				fileWrite(routesPath, original);
			});

			it("generates recommendations based on issues", () => {
				// Remove tests to trigger recommendation
				var specsDir = tempRoot & "/tests/specs";
				var existed = directoryExists(specsDir);
				if (existed) {
					directoryDelete(specsDir, true);
				}

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(arrayLen(results.recommendations)).toBeGT(0);

				if (existed) {
					directoryCreate(specsDir, true);
				}
			});

			it("passes write permission check on writable directory", () => {
				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();

				var passedText = arrayToList(results.passed, " ");
				expect(passedText).toInclude("Write permission");
			});

		});

	}

}
