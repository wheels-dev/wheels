/**
 * A TestClient created inside a test-runner request sends the test context
 * by default, however it is constructed: $testClient(), `new
 * wheels.wheelstest.TestClient()`, or an app subclass. Its requests then reach
 * the same isolated test application (and datasource) as the spec code.
 * testContext=false addresses the live application.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("TestClient test context", () => {

			it("a directly constructed TestClient reaches the spec's application and datasource", () => {
				if (!$isolated()) {
					skip("this run is not in the isolated test application (set WHEELS_ENV to development or testing)");
				}
				var payload = $infoVia(new wheels.wheelstest.TestClient(baseUrl = $getTestBaseUrl()));
				expect(payload.application.name).toBe(
					application.applicationName,
					"new TestClient() must reach the test application, saw `#payload.application.name#`"
				);
				expect(payload.database.datasourceName).toBe(application.wheels.dataSourceName);
			});

			it("a TestClient subclass that calls super.init() does too", () => {
				if (!$isolated()) {
					skip("this run is not in the isolated test application (set WHEELS_ENV to development or testing)");
				}
				var payload = $infoVia(new wheels.tests._assets.wheelstest.SubclassedTestClient(baseUrl = $getTestBaseUrl()));
				expect(payload.application.name).toBe(
					application.applicationName,
					"a TestClient subclass must reach the test application, saw `#payload.application.name#`"
				);
			});

			it("testContext=false addresses the live application", () => {
				if (!$isolated()) {
					skip("this run is not in the isolated test application (set WHEELS_ENV to development or testing)");
				}
				var ctx = new wheels.events.TestContext();
				var payload = $infoVia(new wheels.wheelstest.TestClient(baseUrl = $getTestBaseUrl(), testContext = false));
				expect(ctx.isIsolatedApplicationName(payload.application.name)).toBeFalse(
					"testContext=false must reach the live application, saw `#payload.application.name#`"
				);
			});

			it("currentRequestIsIsolated() reflects the current application and environment", () => {
				var ctx = new wheels.events.TestContext();
				var expected = $isolated() && ListFindNoCase("development,testing", application.wheels.environment) > 0;
				expect(ctx.currentRequestIsIsolated()).toBe(expected);
			});

		});

	}

	private boolean function $isolated() {
		return new wheels.events.TestContext().isIsolatedApplicationName(application.applicationName);
	}

	private struct function $infoVia(required any httpClient) {
		arguments.httpClient.get(path = "/wheels/info", params = {format = "json"});
		expect(arguments.httpClient.statusCode()).toBe(200, "/wheels/info?format=json must be reachable");
		var payload = arguments.httpClient.json();
		expect(IsStruct(payload) && StructKeyExists(payload, "application") && StructKeyExists(payload.application, "name")).toBeTrue();
		return payload;
	}

}
