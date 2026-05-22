/**
 * Regression for #2779: BrowserTest's default base URL is hardcoded to
 * http://localhost:8080 and the only escape hatch (the JVM-cached
 * WHEELS_BROWSER_TEST_BASE_URL env var) cannot be changed after server
 * start. Specs running against non-8080 servers must apply a manual
 * fallback comparing getBaseUrl() to a sentinel string.
 *
 * After the fix, BrowserTest resolves the base URL through a layered
 * lookup at instance time:
 *   1. this.baseUrl              (per-spec override)
 *   2. get("browserTestBaseUrl") (Wheels setting)
 *   3. JVM system property       (wheels.browserTest.baseUrl)
 *   4. Env var                   (WHEELS_BROWSER_TEST_BASE_URL)
 *   5. CGI auto-detect           (cgi.server_name + cgi.server_port)
 *   6. Default                   (http://localhost:8080)
 */
component extends="wheels.WheelsTest" {

    function run() {
        describe("BrowserTest base URL layered resolution (issue ##2779)", () => {

            it("honors this.baseUrl as the highest-precedence override", () => {
                var bt = new wheels.wheelstest.BrowserTest();
                bt.baseUrl = "http://override.example:9999";
                expect(bt.$resolveBaseUrl()).toBe("http://override.example:9999");
            });

            it("falls back through layers when this.baseUrl is empty", () => {
                // Intentionally weak assertion: JVM env vars are read-only
                // from CFML and the Wheels get() setting requires a live
                // framework context, so we can't fully isolate which layer
                // (2–6) fires here. The JVM-property test below and the
                // direct $detectBaseUrlFromCgi tests cover layers 3 and 5
                // in isolation. This case only verifies the chain
                // terminates with a valid http(s):// URL — the original bug
                // was returning the wrong port, not an invalid value.
                var bt = new wheels.wheelstest.BrowserTest();
                bt.baseUrl = "";
                expect(bt.$resolveBaseUrl()).toMatch("^https?://");
            });

            it("$detectBaseUrlFromCgi returns blank when port is the stale 8080 default", () => {
                var bt = new wheels.wheelstest.BrowserTest();
                var fakeCgi = {server_port: "8080", server_name: "localhost", https: "off"};
                expect(bt.$detectBaseUrlFromCgi(fakeCgi)).toBe("");
            });

            it("$detectBaseUrlFromCgi builds the URL from a non-default port", () => {
                var bt = new wheels.wheelstest.BrowserTest();
                var fakeCgi = {server_port: "60050", server_name: "localhost", https: "off"};
                expect(bt.$detectBaseUrlFromCgi(fakeCgi)).toBe("http://localhost:60050");
            });

            it("$detectBaseUrlFromCgi honors the https scheme when cgi.https is on", () => {
                var bt = new wheels.wheelstest.BrowserTest();
                var fakeCgi = {server_port: "443", server_name: "staging.example.com", https: "on"};
                expect(bt.$detectBaseUrlFromCgi(fakeCgi)).toBe("https://staging.example.com");
            });

            it("$detectBaseUrlFromCgi omits canonical http port 80", () => {
                var bt = new wheels.wheelstest.BrowserTest();
                var fakeCgi = {server_port: "80", server_name: "example.com", https: "off"};
                expect(bt.$detectBaseUrlFromCgi(fakeCgi)).toBe("http://example.com");
            });

            it("$detectBaseUrlFromCgi returns blank when server_port is missing or zero", () => {
                var bt = new wheels.wheelstest.BrowserTest();
                expect(bt.$detectBaseUrlFromCgi({server_port: "0"})).toBe("");
                expect(bt.$detectBaseUrlFromCgi({})).toBe("");
            });

            it("JVM system property is honored when this.baseUrl is empty", () => {
                var bt = new wheels.wheelstest.BrowserTest();
                bt.baseUrl = "";
                var sys = createObject("java", "java.lang.System");
                var key = "wheels.browserTest.baseUrl";
                var prior = sys.getProperty(key);
                try {
                    sys.setProperty(key, "http://jvm-prop.example:1234");
                    expect(bt.$resolveBaseUrl()).toBe("http://jvm-prop.example:1234");
                } finally {
                    if (isNull(prior)) {
                        sys.clearProperty(key);
                    } else {
                        sys.setProperty(key, prior);
                    }
                }
            });

        });
    }
}
