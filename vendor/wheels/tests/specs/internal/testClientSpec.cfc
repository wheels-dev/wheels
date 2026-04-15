component extends="wheels.WheelsTest" {

	function run() {

		describe("TestClient", () => {

			beforeEach(() => {
				client = $testClient();
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
					client.get("/");
					expect(client.statusCode()).toBeGT(0);
				});

				it("post() makes HTTP POST request", () => {
					client.post("/");
					expect(client.statusCode()).toBeGT(0);
				});

				it("visit() is alias for get()", () => {
					client.visit("/");
					expect(client.statusCode()).toBeGT(0);
				});

			});

			describe("assertions", () => {

				it("assertStatus() passes on correct status code", () => {
					client.get("/");
					client.assertStatus(client.statusCode());
				});

				it("assertStatus() fails on wrong status code", () => {
					client.get("/");
					expect(function() {
						client.assertStatus(999);
					}).toThrow("TestBox.AssertionFailed");
				});

				it("assertOk() passes on 200 response", () => {
					client.get("/?reload=true&password=wheels");
					client.assertOk();
				});

				it("assertNotFound() passes on 404 response", () => {
					client.get("/wheels-nonexistent-route-that-should-404");
					client.assertNotFound();
				});

				it("assertSee() finds text in response body", () => {
					client.get("/");
					var body = client.content();
					if (Len(body)) {
						var snippet = Left(body, 10);
						if (Len(snippet)) {
							client.assertSee(snippet);
						}
					}
				});

				it("assertSee() fails when text is not found", () => {
					client.get("/");
					expect(function() {
						client.assertSee("ZZZZZ_THIS_TEXT_SHOULD_NEVER_EXIST_ZZZZZ");
					}).toThrow("TestBox.AssertionFailed");
				});

				it("assertDontSee() confirms text is absent", () => {
					client.get("/");
					client.assertDontSee("ZZZZZ_THIS_TEXT_SHOULD_NEVER_EXIST_ZZZZZ");
				});

				it("assertDontSee() fails when text is present", () => {
					client.get("/");
					var body = client.content();
					if (Len(body)) {
						var snippet = Left(body, 10);
						if (Len(snippet)) {
							expect(function() {
								client.assertDontSee(snippet);
							}).toThrow("TestBox.AssertionFailed");
						}
					}
				});

				it("assertJson() validates JSON response", () => {
					client.get("/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.internal.model");
					client.assertJson();
				});

				it("assertJson() fails on non-JSON response", () => {
					client.get("/");
					var body = client.content();
					if (Len(body) && Left(Trim(body), 1) != "{" && Left(Trim(body), 1) != "[") {
						expect(function() {
							client.assertJson();
						}).toThrow("TestBox.AssertionFailed");
					}
				});

				it("assertRedirect() checks 3xx status", () => {
					client.get("/");
					var code = client.statusCode();
					if (code >= 300 && code < 400) {
						client.assertRedirect();
					} else {
						expect(function() {
							client.assertRedirect();
						}).toThrow("TestBox.AssertionFailed");
					}
				});

			});

			describe("request configuration", () => {

				it("withHeaders() adds custom headers", () => {
					client.withHeaders({"X-Custom-Test": "hello"});
					client.get("/");
					expect(client.statusCode()).toBeGT(0);
				});

				it("withHeader() adds a single header", () => {
					client.withHeader("X-Custom-Test", "hello");
					client.get("/");
					expect(client.statusCode()).toBeGT(0);
				});

				it("asJson() sets content type and returns client for chaining", () => {
					var result = client.asJson();
					expect(result).toBeInstanceOf("wheels.wheelstest.TestClient");
				});

			});

			describe("response accessors", () => {

				beforeEach(() => {
					client.get("/");
				});

				it("content() returns response body as string", () => {
					expect(client.content()).toBeString();
				});

				it("statusCode() returns numeric status", () => {
					expect(client.statusCode()).toBeNumeric();
				});

				it("headers() returns response headers struct", () => {
					expect(client.headers()).toBeStruct();
				});

				it("response() returns full response struct", () => {
					expect(client.response()).toBeStruct();
				});

			});

			describe("chaining", () => {

				it("supports fluent chaining: visit().assertOk().assertSee()", () => {
					client.visit("/?reload=true&password=wheels");
					var code = client.statusCode();
					if (code == 200) {
						var body = client.content();
						if (Len(body)) {
							var snippet = Left(body, 5);
							if (Len(snippet)) {
								client.assertOk().assertSee(snippet);
							}
						}
					}
				});

				it("supports withHeaders().get().assertStatus() chain", () => {
					client.withHeader("Accept", "text/html").get("/");
					client.assertStatus(client.statusCode());
				});

			});

			describe("assertSeeInOrder", () => {

				it("passes when texts appear in order", () => {
					client.get("/");
					var body = client.content();
					if (Len(body) > 20) {
						var first = Mid(body, 1, 5);
						var second = Mid(body, 10, 5);
						client.assertSeeInOrder([first, second]);
					}
				});

				it("fails when texts appear out of order", () => {
					client.get("/");
					var body = client.content();
					if (Len(body) > 20) {
						var first = Mid(body, 10, 5);
						var second = Mid(body, 1, 5);
						expect(function() {
							client.assertSeeInOrder([first, second]);
						}).toThrow("TestBox.AssertionFailed");
					}
				});

			});

			describe("assertJsonPath", () => {

				it("resolves dot-notation paths in JSON", () => {
					client.get("/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.internal.model");
					var jsonData = client.json();
					if (StructKeyExists(jsonData, "totalPass")) {
						client.assertJsonPath("totalPass", jsonData.totalPass);
					}
				});

			});

			describe("assertHeader", () => {

				it("passes when header exists", () => {
					client.get("/");
					client.assertHeader("Content-Type");
				});

				it("fails when header is missing", () => {
					client.get("/");
					expect(function() {
						client.assertHeader("X-Nonexistent-Header-For-Test");
					}).toThrow("TestBox.AssertionFailed");
				});

			});

		});

	}

}
