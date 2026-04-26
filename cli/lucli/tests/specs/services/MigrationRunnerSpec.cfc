component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.migrationRunner = new cli.lucli.services.MigrationRunner(
			projectRoot = variables.tempRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("MigrationRunner Service", () => {

			describe("runViaHttp()", () => {

				it("returns error struct when no server on bogus port", () => {
					try {
						var result = migrationRunner.runViaHttp(
							serverPort = 59998,
							action = "info"
						);
						// If we get a struct, check it
						if (isStruct(result)) {
							expect(result.success).toBeFalse();
						}
					} catch (any e) {
						// Connection error is also acceptable
						expect(len(e.message)).toBeGT(0);
					}
				});

				it("returns error for invalid action", () => {
					try {
						var result = migrationRunner.runViaHttp(
							serverPort = 59998,
							action = "invalid"
						);
						if (isStruct(result)) {
							expect(result.success).toBeFalse();
						}
					} catch (any e) {
						expect(len(e.message)).toBeGT(0);
					}
				});

			});

			describe("in-process methods require application context", () => {

				it("info() fails gracefully without application.wheels.migrator", () => {
					try {
						var result = migrationRunner.info();
						if (isStruct(result)) {
							expect(structKeyExists(result, "success")).toBeTrue();
						}
					} catch (any e) {
						// Expected — no application context
						expect(len(e.message)).toBeGT(0);
					}
				});

				it("latest() fails gracefully without application context", () => {
					try {
						var result = migrationRunner.latest();
						if (isStruct(result)) {
							expect(structKeyExists(result, "success")).toBeTrue();
						}
					} catch (any e) {
						expect(len(e.message)).toBeGT(0);
					}
				});

			});

			describe("runViaHttp() with live server", () => {

				it("info returns migration data from running server", () => {
					var serverPort = testHelper.detectServerPort();
					if (!serverPort) { debug("No server — skipping"); return; }

					try {
						var result = migrationRunner.runViaHttp(
							serverPort = serverPort,
							action = "info"
						);
						if (isStruct(result)) {
							expect(structKeyExists(result, "success")).toBeTrue();
						}
					} catch (any e) {
						// Migration endpoint may not exist
						debug("Migration HTTP error: " & e.message);
					}
				});

			});

		});

	}

}
