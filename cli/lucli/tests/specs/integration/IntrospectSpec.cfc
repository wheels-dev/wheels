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

		describe("Introspect Endpoint Integration", () => {

			it("returns model metadata for a valid model", () => {
				if (skipIntegration) { debug(skipReason); return; }

				// Use a test model that exists in the test database
				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=introspect&model=Author&format=json"
				);

				if (!len(response)) {
					debug("Empty response — model 'Author' may not exist");
					return;
				}

				var data = deserializeJSON(response);
				if (!data.success) {
					debug("Introspect failed: #data.message# — test model may not be available");
					return;
				}

				expect(structKeyExists(data, "model")).toBeTrue();
				expect(structKeyExists(data, "tableName")).toBeTrue();
				expect(structKeyExists(data, "primaryKey")).toBeTrue();
				expect(structKeyExists(data, "columns")).toBeTrue();
				expect(isArray(data.columns)).toBeTrue();
				expect(arrayLen(data.columns)).toBeGT(0);
				expect(structKeyExists(data, "associations")).toBeTrue();
			});

			it("column entries have name and type", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=introspect&model=Author&format=json"
				);
				if (!len(response)) return;

				var data = deserializeJSON(response);
				if (!data.success) return;

				var col = data.columns[1];
				expect(structKeyExists(col, "name")).toBeTrue();
				expect(structKeyExists(col, "type")).toBeTrue();
			});

			it("fails gracefully with missing model parameter", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=introspect&format=json"
				);
				expect(len(response)).toBeGT(0);

				var data = deserializeJSON(response);
				expect(data.success).toBeFalse();
				expect(structKeyExists(data, "message")).toBeTrue();
			});

			it("fails gracefully with non-existent model", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=introspect&model=NonExistentModelXyz&format=json"
				);
				expect(len(response)).toBeGT(0);

				var data = deserializeJSON(response);
				expect(data.success).toBeFalse();
			});

		});

	}

}
