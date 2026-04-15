component extends="wheels.WheelsTest" {

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
					tc.get("/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.internal.model");
					tc.assertJson();
				});

				it("assertJson() fails on non-JSON response", () => {
					tc.get("/");
					expect(function() {
						tc.assertJson();
					}).toThrow("TestBox.AssertionFailed");
				});

				it("assertRedirect() fails on non-redirect status", () => {
					tc.get("/");
					expect(function() {
						tc.assertRedirect();
					}).toThrow("TestBox.AssertionFailed");
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
					tc.get("/");
					var body = tc.content();
					expect(Len(body)).toBeGT(20, "Response body must be >20 chars for ordering test");
					tc.assertSeeInOrder([Mid(body, 1, 5), Mid(body, 10, 5)]);
				});

				it("fails when texts appear out of order", () => {
					tc.get("/");
					var body = tc.content();
					expect(Len(body)).toBeGT(20, "Response body must be >20 chars for ordering test");
					var first = Mid(body, 10, 5);
					var second = Mid(body, 1, 5);
					expect(function() {
						tc.assertSeeInOrder([first, second]);
					}).toThrow("TestBox.AssertionFailed");
				});

			});

			describe("assertJsonPath", () => {

				it("resolves dot-notation paths in JSON", () => {
					tc.get("/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.internal.model");
					tc.assertJson();
					var jsonData = tc.json();
					expect(StructKeyExists(jsonData, "totalPass")).toBeTrue("Expected JSON to contain totalPass key");
					tc.assertJsonPath("totalPass", jsonData.totalPass);
				});

			});

			describe("assertHeader", () => {

				it("passes when header exists", () => {
					tc.get("/");
					tc.assertHeader("Content-Type");
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
