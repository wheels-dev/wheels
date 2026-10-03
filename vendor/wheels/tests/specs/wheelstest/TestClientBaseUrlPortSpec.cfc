/**
 * #4195: the auto-detected TestClient/BrowserTest base URL should target the server's local listen
 * port. $detectBaseUrlFromServletPort(cgiScope, localPort, localScheme) is the seam:
 *   - mapping detected (localPort != cgi.server_port) -> <localScheme>://127.0.0.1:<localPort>
 *   - no mapping / no servlet port -> "" (so the existing cgi step runs, byte-identical)
 * The scheme comes from the servlet request's getScheme() (http behind a TLS-terminating proxy,
 * https if the container serves TLS). The real getLocalPort()/getScheme() can't differ from the
 * request's Host values in one process, so both are injected here.
 */
component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("TestClient base URL honours the server local listen port (4195)", () => {

			it("mapping detected, http listener -> http loopback + localPort", () => {
				expect($detectBaseUrlFromServletPort({server_port = 8080}, 60007, "http")).toBe("http://127.0.0.1:60007");
			});

			it("mapping detected, https listener -> https loopback + localPort", () => {
				expect($detectBaseUrlFromServletPort({server_port = 8443}, 60007, "https")).toBe("https://127.0.0.1:60007");
			});

			it("unmapped (localPort == server_port) -> defers to the cgi step", () => {
				expect($detectBaseUrlFromServletPort({server_port = 60007}, 60007, "http")).toBe("");
			});

			it("no servlet port available (0) -> defers", () => {
				expect($detectBaseUrlFromServletPort({server_port = 8080}, 0, "http")).toBe("");
			});

			it("missing server_port -> defers", () => {
				expect($detectBaseUrlFromServletPort({}, 60007, "http")).toBe("");
			});

			it("BrowserTest has the same mapping-gated behaviour (both schemes)", () => {
				var bt = new wheels.wheelstest.BrowserTest();
				expect(bt.$detectBaseUrlFromServletPort({server_port = 8080}, 60007, "http")).toBe("http://127.0.0.1:60007");
				expect(bt.$detectBaseUrlFromServletPort({server_port = 8443}, 60007, "https")).toBe("https://127.0.0.1:60007");
				expect(bt.$detectBaseUrlFromServletPort({server_port = 60007}, 60007, "http")).toBe("");
			});
		});
	}
}
