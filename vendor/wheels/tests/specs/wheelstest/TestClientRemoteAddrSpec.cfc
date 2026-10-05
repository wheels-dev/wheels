/**
 * F23 — TestClient client address.
 *
 * A TestClient can set the client address (REMOTE_ADDR) for a request so per-client behaviour
 * (RateLimiter, IP allow/deny rules) is testable. The client sends an X-Wheels-Test-Remote-Addr
 * header; in the isolated test application (development/testing only) Dispatch maps it onto the
 * middleware request context's `remoteAddr` field — the field RateLimiter and IP rules already read.
 * It never mutates the cgi scope, and it is honoured ONLY inside the isolated test context, which
 * itself only binds in development/testing from a loopback peer with the per-server secret
 * (events/testcontext.cfm). So an outside client cannot spoof its address.
 *
 * Gating is verified three ways: honoured when isolated, ignored when not isolated, and the env gate
 * the isolated bind depends on excludes production (so an isolated bind cannot occur there).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("F23 TestClient client address", () => {

			// ── The gated resolver (TestContext.$testClientRemoteAddr), unit-level ──

			it("resolves the X-Wheels-Test-Remote-Addr header when the request is isolated", () => {
				var tc = new wheels.events.TestContext();
				var cgiScope = {"http_x_wheels_test_remote_addr" = "203.0.113.9"};
				expect(tc.$testClientRemoteAddr(cgiScope = cgiScope, isolated = true)).toBe("203.0.113.9");
			});

			it("ignores the header when the request is NOT isolated (non-isolated request)", () => {
				var tc = new wheels.events.TestContext();
				var cgiScope = {"http_x_wheels_test_remote_addr" = "203.0.113.9"};
				expect(tc.$testClientRemoteAddr(cgiScope = cgiScope, isolated = false)).toBe("");
			});

			it("returns empty when the header is absent, even if isolated", () => {
				var tc = new wheels.events.TestContext();
				expect(tc.$testClientRemoteAddr(cgiScope = {}, isolated = true)).toBe("");
			});

			it("the env gate the isolated bind depends on excludes production", () => {
				// currentRequestIsIsolated() returns true only when the app is the isolated test app AND
				// $environmentAllowsTestContext(environment) is true — so production can never be isolated,
				// which is why the override is ignored in production even if an isolated name appeared.
				var tc = new wheels.events.TestContext();
				expect(tc.$environmentAllowsTestContext("production")).toBeFalse();
				expect(tc.$environmentAllowsTestContext("development")).toBeTrue();
				expect(tc.$environmentAllowsTestContext("testing")).toBeTrue();
			});

			// ── End-to-end through the middleware request context ──

			it("fromAddress() makes middleware see that client address", () => {
				var httpClient = $testClient();
				httpClient.fromAddress("203.0.113.9").get("/_remoteaddr/show");
				expect(httpClient.statusCode()).toBe(200, "the probe request did not complete with 200");
				expect(Trim(httpClient.content())).toBe(
					"203.0.113.9",
					"the middleware request context did not carry the test client address"
				);
			});

			it("without fromAddress(), middleware see no test override", () => {
				var httpClient = $testClient();
				httpClient.get("/_remoteaddr/show");
				expect(httpClient.statusCode()).toBe(200, "the probe request did not complete with 200");
				expect(Trim(httpClient.content())).toBe(
					"none",
					"a test override leaked without fromAddress() being called"
				);
			});

		});

	}

}
