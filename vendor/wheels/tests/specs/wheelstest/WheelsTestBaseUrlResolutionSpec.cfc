/**
 * Review finding test-infra:11 — WheelsTest.$getTestBaseUrl hardcoded
 * "http://localhost:" + CGI.SERVER_PORT, discarding SERVER_NAME and the
 * HTTPS flag, so HTTP integration specs targeted the wrong origin under
 * HTTPS, non-localhost, or vhosted setups (surfacing as confusing
 * "received 0" failures).
 *
 * After the fix, $getTestBaseUrl resolves through a layered lookup
 * mirroring BrowserTest.$resolveBaseUrl:
 *   1. this.testClientBaseUrl      (per-spec override)
 *   2. get("testClientBaseUrl")    (Wheels setting)
 *   3. JVM system property         (wheels.testClient.baseUrl)
 *   4. Env var                     (WHEELS_TEST_CLIENT_BASE_URL)
 *   5. CGI auto-detect             (scheme + server_name + server_port)
 *   6. Default                     (http://localhost:8080)
 */
component extends="wheels.WheelsTest" {

    function run() {
        describe("WheelsTest test-client base URL resolution", () => {

            it("derives scheme and host from the request instead of assuming http://localhost", () => {
                var fakeCgi = {server_port: "443", server_name: "staging.example.com", https: "on"};
                expect($detectTestBaseUrlFromCgi(fakeCgi)).toBe("https://staging.example.com");
            });

            it("builds host:port URLs for plain http on a custom port", () => {
                var fakeCgi = {server_port: "60050", server_name: "myapp.test", https: "off"};
                expect($detectTestBaseUrlFromCgi(fakeCgi)).toBe("http://myapp.test:60050");
            });

            it("omits canonical port 80 for http", () => {
                var fakeCgi = {server_port: "80", server_name: "example.com", https: "off"};
                expect($detectTestBaseUrlFromCgi(fakeCgi)).toBe("http://example.com");
            });

            it("returns blank when server_port is missing or zero", () => {
                expect($detectTestBaseUrlFromCgi({server_port: "0"})).toBe("");
                expect($detectTestBaseUrlFromCgi({})).toBe("");
            });

            it("honors this.testClientBaseUrl as the highest-precedence override", () => {
                try {
                    this.testClientBaseUrl = "http://override.example:9999";
                    expect($getTestBaseUrl()).toBe("http://override.example:9999");
                } finally {
                    structDelete(this, "testClientBaseUrl");
                }
            });

            it("honors the wheels.testClient.baseUrl JVM system property", () => {
                var sys = createObject("java", "java.lang.System");
                var key = "wheels.testClient.baseUrl";
                var prior = sys.getProperty(key);
                try {
                    sys.setProperty(key, "http://jvm-prop.example:1234");
                    expect($getTestBaseUrl()).toBe("http://jvm-prop.example:1234");
                } finally {
                    if (isNull(prior)) {
                        sys.clearProperty(key);
                    } else {
                        sys.setProperty(key, prior);
                    }
                }
            });

            it("always terminates with a valid http(s) URL", () => {
                expect($getTestBaseUrl()).toMatch("^https?://");
            });

        });
    }
}
