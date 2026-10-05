/**
 * TestClient sends a valid authenticity token to forgery-protected actions, the
 * way a browser does: it picks the token up from a page it fetched (the
 * csrf-token meta tag, else an authenticityToken hidden field) and sends it on
 * POST/PUT/PATCH/DELETE as the X-CSRF-Token header, plus the authenticityToken
 * field on a form body. The token belongs to the session: it is dropped when the
 * session cookie changes (a login rotates it) and never shared between clients.
 *
 * The HTTP specs drive CsrfTestClientProbe under /_csrfclient (tests/routes.cfm).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("TestClient CSRF tokens over HTTP (session store)", () => {

			it("captures the token from csrfMetaTags() and sends it on POST, PUT, PATCH and DELETE", () => {
				var tc = $testClient();
				tc.get("/_csrfclient/meta").assertOk();
				expect(Len(tc.csrfToken())).toBeGT(0);
				tc.post("/_csrfclient/save", {"name" = "x"}).assertOk().assertSee("saved:POST");
				tc.put("/_csrfclient/save", {"name" = "x"}).assertOk().assertSee("saved:PUT");
				tc.patch("/_csrfclient/save", {"name" = "x"}).assertOk().assertSee("saved:PATCH");
				tc.delete("/_csrfclient/save").assertOk().assertSee("saved:DELETE");
			});

			it("captures the token from an authenticityToken hidden field", () => {
				var tc = $testClient();
				tc.get("/_csrfclient/field").assertOk();
				expect(Len(tc.csrfToken())).toBeGT(0);
				tc.post("/_csrfclient/save").assertOk().assertSee("saved:POST");
			});

			it("sends the token as the header on a JSON body", () => {
				var tc = $testClient();
				tc.get("/_csrfclient/meta");
				tc.asJson().post("/_csrfclient/save", {"name" = "x"}).assertOk();
			});

			it("is refused without a token, and with a wrong one", () => {
				var tc = $testClient();
				tc.post("/_csrfclient/save").assertStatus(403);
				tc.get("/_csrfclient/meta");
				tc.withoutCsrfToken().post("/_csrfclient/save").assertStatus(403);
				expect(tc.csrfToken()).toBe("");
				tc.withCsrfToken("not-the-token").post("/_csrfclient/save").assertStatus(403);
			});

			it("lets an explicit header or field win over the captured token", () => {
				var tc = $testClient();
				tc.get("/_csrfclient/meta");
				tc.post("/_csrfclient/save", {}, {"X-CSRF-Token" = "explicit-bad"}).assertStatus(403);
				tc.post("/_csrfclient/save", {"authenticityToken" = "explicit-bad"}).assertStatus(403);
				// And the captured token still works when the test passes neither.
				tc.post("/_csrfclient/save").assertOk();
			});

			it("fetchCsrfToken() fetches a page for its token, and says so when there is none", () => {
				var tc = $testClient();
				tc.fetchCsrfToken("/_csrfclient/meta").post("/_csrfclient/save").assertOk();
				var state = {type = ""};
				try {
					$testClient().fetchCsrfToken("/_csrfclient/plain");
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.TestClient.CsrfTokenNotFound");
			});

			it("never shares a token between clients", () => {
				var first = $testClient();
				first.get("/_csrfclient/meta");
				var second = $testClient();
				expect(second.csrfToken()).toBe("");
				second.post("/_csrfclient/save").assertStatus(403);
			});

			it("drops the token when a login rotates the session, and the next page refreshes it", () => {
				var tc = $testClient();
				tc.get("/_csrfclient/meta");
				var before = tc.csrfToken();
				tc.post("/_csrfclient/login").assertOk().assertSee("logged in");
				expect(tc.csrfToken()).toBe("");
				tc.get("/_csrfclient/meta");
				expect(Len(tc.csrfToken())).toBeGT(0);
				tc.post("/_csrfclient/save").assertOk();
				expect(Len(before)).toBeGT(0);
			});

		});

		describe("TestClient CSRF tokens over HTTP (cookie store)", () => {

			beforeEach(() => {
				_savedStore = application.wheels.csrfStore;
				application.wheels.csrfStore = "cookie";
			});

			afterEach(() => {
				application.wheels.csrfStore = _savedStore;
			});

			it("round-trips the cookie-store token and its cookie", () => {
				var tc = $testClient();
				tc.get("/_csrfclient/meta").assertOk();
				expect(Len(tc.csrfToken())).toBeGT(0);
				tc.post("/_csrfclient/save").assertOk().assertSee("saved:POST");
				tc.delete("/_csrfclient/save").assertOk();
				tc.withoutCsrfToken().post("/_csrfclient/save").assertStatus(403);
			});

		});

		describe("TestClient $extractCsrfToken", () => {

			it("reads the csrf-token meta tag in either attribute order and quote style", () => {
				var tc = new wheels.wheelstest.TestClient(testContext = false);
				expect(tc.$extractCsrfToken('<meta name="csrf-token" content="abc123">')).toBe("abc123");
				expect(tc.$extractCsrfToken("<meta content='abc123' name='csrf-token' />")).toBe("abc123");
				expect(tc.$extractCsrfToken('<meta name="csrf-param" content="authenticityToken"><meta name="csrf-token" content="tok">')).toBe("tok");
			});

			it("reads the hidden field, and prefers the meta tag", () => {
				var tc = new wheels.wheelstest.TestClient(testContext = false);
				expect(tc.$extractCsrfToken('<input type="hidden" name="authenticityToken" value="fromfield">')).toBe("fromfield");
				expect(tc.$extractCsrfToken('<input name="authenticityToken" value="f"><meta name="csrf-token" content="m">')).toBe("m");
				expect(tc.$extractCsrfToken('<input name="authenticityToken" value="one"><input name="authenticityToken" value="two">')).toBe("one");
			});

			it("decodes HTML-encoded attribute values", () => {
				var tc = new wheels.wheelstest.TestClient(testContext = false);
				var amp = Chr(38);
				var encoded = "a" & amp & "##x2b;b" & amp & "##x2f;c" & amp & "##x3d;" & amp & "amp;";
				expect(tc.$extractCsrfToken('<meta name="csrf-token" content="' & encoded & '">')).toBe("a+b/c=" & amp);
			});

			it("finds nothing in a page without a token or in JSON", () => {
				var tc = new wheels.wheelstest.TestClient(testContext = false);
				expect(tc.$extractCsrfToken("<p>none</p>")).toBe("");
				expect(tc.$extractCsrfToken('{"csrf-token":"abc"}')).toBe("");
				expect(tc.$extractCsrfToken('<input name="other" value="x">')).toBe("");
			});

		});

	}

}
