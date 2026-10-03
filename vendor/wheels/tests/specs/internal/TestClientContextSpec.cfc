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

			it("sends neither the header nor the cookie to a host other than the test server", () => {
				if (!$isolated()) {
					skip("this run is not in the isolated test application (set WHEELS_ENV to development or testing)");
				}
				var ctx = new wheels.events.TestContext();
				// No request is made: the defaults are inspected right after init().
				var external = new wheels.tests._assets.wheelstest.InspectableTestClient(baseUrl = "https://external-service.example").capturedDefaults();
				expect(StructKeyExists(external.headers, ctx.headerName())).toBeFalse("an external baseUrl must not get the test-context header");
				expect(StructKeyExists(external.cookies, ctx.cookieName())).toBeFalse("an external baseUrl must not get the test-context cookie");
				// Control: a loopback client in the same run does carry both.
				var loopback = new wheels.tests._assets.wheelstest.InspectableTestClient(baseUrl = "http://127.0.0.1:8080").capturedDefaults();
				expect(StructKeyExists(loopback.headers, ctx.headerName())).toBeTrue();
				expect(StructKeyExists(loopback.cookies, ctx.cookieName())).toBeTrue();
			});

			it("treats only loopback hosts and the configured test base URL as the test server", () => {
				var c = new wheels.wheelstest.TestClient(baseUrl = "https://external-service.example", testContext = false);
				for (var candidate in ["http://localhost:8080/x", "http://LOCALHOST", "http://127.0.0.1", "https://127.1.2.3:60007", "http://[::1]:8080/"]) {
					expect(c.$isTestHost(candidate)).toBeTrue(candidate);
				}
				for (var candidate in [
					"https://external-service.example",
					"http://localhost.example.com",
					"http://127.0.0.1.example.com",
					"http://example.com/localhost",
					"http://example.com/?host=127.0.0.1",
					"http://localhost@example.com",
					"http://127.0.0.256",
					"not a url",
					""
				]) {
					expect(c.$isTestHost(candidate)).toBeFalse(candidate);
				}
			});

			it("treats the configured testClientBaseUrl host as the test server", () => {
				var c = new wheels.wheelstest.TestClient(baseUrl = "http://127.0.0.1", testContext = false);
				var saved = {exists = StructKeyExists(application.wheels, "testClientBaseUrl"), value = ""};
				if (saved.exists) {
					saved.value = application.wheels.testClientBaseUrl;
				}
				var result = {configured = false, other = true};
				application.wheels.testClientBaseUrl = "https://myapp.test:8443";
				try {
					result.configured = c.$isTestHost("https://myapp.test:8443/users");
					result.other = c.$isTestHost("https://otherapp.test");
				} finally {
					// Restore the setting even if a check throws, so later specs see the original.
					if (saved.exists) {
						application.wheels.testClientBaseUrl = saved.value;
					} else {
						StructDelete(application.wheels, "testClientBaseUrl");
					}
				}
				expect(result.configured).toBeTrue();
				expect(result.other).toBeFalse();
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
