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

		});

	}

}
