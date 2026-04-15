component extends="wheels.WheelsTest" {

	/**
	 * Helper: create a TestClient with a pre-set fake response for unit-testing
	 * assertion logic without making real HTTP calls.
	 */
	private any function $fakeClient(string body = "", numeric status = 200, struct headers = {}) {
		var fc = new wheels.wheelstest.TestClient();
		// Directly set internal state to test assertions in isolation
		fc.$setFakeResponse(
			statusCode = "#arguments.status# OK",
			fileContent = arguments.body,
			responseHeader = arguments.headers
		);
		return fc;
	}

	function run() {

		describe("TestClient", () => {

			beforeEach(() => {
				tc = $testClient();
			});

			describe("initialization", () => {

				it("initializes with default baseUrl", () => {
					var c = new wheels.wheelstest.TestClient();
					expect(c).toBeInstanceOf("wheels.wheelstest.TestClient");
				});

				it("initializes with custom baseUrl", () => {
					var c = new wheels.wheelstest.TestClient(baseUrl = "http://localhost:9999");
					expect(c).toBeInstanceOf("wheels.wheelstest.TestClient");
				});

			});

			describe("request methods", () => {

				it("get() makes HTTP GET request", () => {
					tc.get("/");
					expect(tc.statusCode()).toBeGT(0);
				});

				it("post() makes HTTP POST request", () => {
					tc.post("/");
					expect(tc.statusCode()).toBeGT(0);
				});

				it("put() makes HTTP PUT request", () => {
					tc.put("/");
					expect(tc.statusCode()).toBeGT(0);
				});

				it("patch() makes HTTP PATCH request", () => {
					tc.patch("/");
					expect(tc.statusCode()).toBeGT(0);
				});

				it("delete() makes HTTP DELETE request", () => {
					tc.delete("/");
					expect(tc.statusCode()).toBeGT(0);
				});

				it("visit() is alias for get()", () => {
					tc.visit("/");
					expect(tc.statusCode()).toBeGT(0);
				});

			});

			describe("assertions", () => {

				it("assertStatus() passes on correct status code", () => {
					tc.get("/");
					tc.assertStatus(tc.statusCode());
				});

				it("assertStatus() fails on wrong status code", () => {
					tc.get("/");
					expect(function() {
						tc.assertStatus(999);
					}).toThrow("TestBox.AssertionFailed");
				});

				it("assertOk() passes on 200 response", () => {
					tc.get("/");
					tc.assertOk();
				});

				it("assertNotFound() passes on 404 response", () => {
					tc.get("/wheels-nonexistent-route-that-should-404");
					tc.assertNotFound();
				});

				it("assertSee() finds text in response body", () => {
					tc.get("/");
					expect(Len(tc.content())).toBeGT(0, "Response body should not be empty");
					tc.assertSee(Left(tc.content(), 10));
				});

				it("assertSee() fails when text is not found", () => {
					tc.get("/");
					expect(function() {
						tc.assertSee("ZZZZZ_THIS_TEXT_SHOULD_NEVER_EXIST_ZZZZZ");
					}).toThrow("TestBox.AssertionFailed");
				});

				it("assertDontSee() confirms text is absent", () => {
					tc.get("/");
					tc.assertDontSee("ZZZZZ_THIS_TEXT_SHOULD_NEVER_EXIST_ZZZZZ");
				});

				it("assertDontSee() fails when text is present", () => {
					tc.get("/");
					expect(Len(tc.content())).toBeGT(0, "Response body should not be empty");
					var snippet = Left(tc.content(), 10);
					expect(function() {
						tc.assertDontSee(snippet);
					}).toThrow("TestBox.AssertionFailed");
				});

				it("assertJson() validates JSON response", () => {
					var fc = $fakeClient(body = '{"name":"wheels","version":4}');
					fc.assertJson();
					fc.assertJson({name: "wheels"});
				});

				it("assertJson() fails on non-JSON response", () => {
					var fc = $fakeClient(body = "<html>not json</html>");
					expect(function() {
						fc.assertJson();
					}).toThrow("TestBox.AssertionFailed");
				});

				it("assertRedirect() fails on non-redirect status", () => {
					tc.get("/");
					expect(function() {
						tc.assertRedirect();
					}).toThrow("TestBox.AssertionFailed");
				});

				it("assertRedirect() passes on 3xx status", () => {
					var fc = $fakeClient(status = 302, headers = {Location: "/dashboard"});
					fc.assertRedirect();
					fc.assertRedirect(to = "/dashboard");
				});

			});

			describe("request configuration", () => {

				it("withHeaders() adds custom headers", () => {
					tc.withHeaders({"X-Custom-Test": "hello"});
					tc.get("/");
					expect(tc.statusCode()).toBeGT(0);
				});

				it("withHeader() adds a single header", () => {
					tc.withHeader("X-Custom-Test", "hello");
					tc.get("/");
					expect(tc.statusCode()).toBeGT(0);
				});

				it("asJson() sets content type and returns client for chaining", () => {
					var result = tc.asJson();
					expect(result).toBeInstanceOf("wheels.wheelstest.TestClient");
				});

			});

			describe("response accessors", () => {

				beforeEach(() => {
					tc.get("/");
				});

				it("content() returns response body as string", () => {
					expect(tc.content()).toBeString();
				});

				it("statusCode() returns numeric status", () => {
					expect(tc.statusCode()).toBeNumeric();
				});

				it("headers() returns response headers struct", () => {
					expect(tc.headers()).toBeStruct();
				});

				it("response() returns full response struct", () => {
					expect(tc.response()).toBeStruct();
				});

			});

			describe("chaining", () => {

				it("supports fluent chaining: get().assertOk().assertSee()", () => {
					tc.get("/");
					expect(Len(tc.content())).toBeGT(0, "Response body should not be empty");
					tc.assertOk().assertSee(Left(tc.content(), 5));
				});

				it("supports withHeaders().get().assertStatus() chain", () => {
					tc.withHeader("Accept", "text/html").get("/");
					tc.assertStatus(tc.statusCode());
				});

			});

			describe("assertSeeInOrder", () => {

				it("passes when texts appear in order", () => {
					var fc = $fakeClient(body = "alpha beta gamma delta");
					fc.assertSeeInOrder(["alpha", "beta", "gamma"]);
				});

				it("fails when texts appear out of order", () => {
					var fc = $fakeClient(body = "alpha beta gamma delta");
					expect(function() {
						fc.assertSeeInOrder(["gamma", "alpha"]);
					}).toThrow("TestBox.AssertionFailed");
				});

			});

			describe("assertJsonPath", () => {

				it("resolves dot-notation paths in JSON", () => {
					var fc = $fakeClient(body = '{"user":{"name":"John","roles":["admin","editor"]}}');
					fc.assertJsonPath("user.name", "John");
				});

				it("resolves 1-based array indices in JSON", () => {
					var fc = $fakeClient(body = '{"items":["a","b","c"]}');
					fc.assertJsonPath("items.1", "a");
					fc.assertJsonPath("items.3", "c");
				});

				it("fails on missing path", () => {
					var fc = $fakeClient(body = '{"name":"wheels"}');
					expect(function() {
						fc.assertJsonPath("missing.key", "val");
					}).toThrow("TestBox.AssertionFailed");
				});

			});

			describe("assertHeader", () => {

				it("passes when header exists", () => {
					tc.get("/");
					tc.assertHeader("Content-Type");
				});

				it("passes when header matches value", () => {
					var fc = $fakeClient(headers = {"X-Custom": "hello"});
					fc.assertHeader("X-Custom", "hello");
				});

				it("fails when header is missing", () => {
					tc.get("/");
					expect(function() {
						tc.assertHeader("X-Nonexistent-Header-For-Test");
					}).toThrow("TestBox.AssertionFailed");
				});

			});

			describe("post with body", () => {

				it("sends form fields by default", () => {
					tc.post("/", {testField: "testValue"});
					expect(tc.statusCode()).toBeGT(0);
				});

				it("sends JSON body when asJson()", () => {
					tc.asJson().post("/", {testField: "testValue"});
					expect(tc.statusCode()).toBeGT(0);
				});

			});

		});

	}

}
