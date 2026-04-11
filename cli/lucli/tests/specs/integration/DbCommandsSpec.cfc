component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.serverPort = testHelper.detectServerPort();
		variables.skipIntegration = (variables.serverPort == 0);
		if (variables.skipIntegration) {
			variables.skipReason = "No running server detected — skipping integration tests";
		}
		variables.baseUrl = "http://localhost:#variables.serverPort#";
	}

	function run() {

		describe("DB Commands Integration", () => {

			it("dbStatus returns valid JSON with migrations", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=dbStatus&format=json"
				);
				expect(len(response)).toBeGT(0);

				var data = deserializeJSON(response);
				expect(data.success).toBeTrue();
				expect(structKeyExists(data, "migrations")).toBeTrue();
				expect(isArray(data.migrations)).toBeTrue();
				expect(structKeyExists(data, "summary")).toBeTrue();
				expect(data.summary.total).toBeGTE(0);
				expect(data.summary.applied).toBeGTE(0);
				expect(data.summary.pending).toBeGTE(0);
			});

			it("dbStatus migration entries have required fields", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=dbStatus&format=json"
				);
				var data = deserializeJSON(response);

				if (arrayLen(data.migrations) > 0) {
					var m = data.migrations[1];
					expect(structKeyExists(m, "version")).toBeTrue();
					expect(structKeyExists(m, "description")).toBeTrue();
					expect(structKeyExists(m, "status")).toBeTrue();
				}
			});

			it("dbVersion returns current version", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=dbVersion&format=json"
				);
				expect(len(response)).toBeGT(0);

				var data = deserializeJSON(response);
				expect(data.success).toBeTrue();
				expect(structKeyExists(data, "version")).toBeTrue();
			});

		});

	}

}
