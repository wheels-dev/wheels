component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.$$oldCGI = Duplicate(request.cgi);
		variables.$$hadBaseUrl = StructKeyExists(application.wheels, "baseUrl");
		if (variables.$$hadBaseUrl) {
			variables.$$origBaseUrl = application.wheels.baseUrl;
		}
		variables.$$origEnvironment = application.wheels.environment;
		variables.$$hadUnsetWarned = StructKeyExists(application.wheels, "$baseUrlUnsetWarned");
		variables.$$hadProtoWarned = StructKeyExists(application.wheels, "$forwardedProtoTrustWarned");
	}

	function afterAll() {
		request.cgi = variables.$$oldCGI;
		if (variables.$$hadBaseUrl) {
			application.wheels.baseUrl = variables.$$origBaseUrl;
		} else {
			StructDelete(application.wheels, "baseUrl");
		}
		application.wheels.environment = variables.$$origEnvironment;
		if (!variables.$$hadUnsetWarned) {
			StructDelete(application.wheels, "$baseUrlUnsetWarned");
		}
		if (!variables.$$hadProtoWarned) {
			StructDelete(application.wheels, "$forwardedProtoTrustWarned");
		}
	}

	function run() {
		describe("Canonical baseUrl for absolute URLs", () => {

			beforeEach(() => {
				// A dev-style request on a non-standard port with no TLS.
				request.cgi.server_port = 8080;
				request.cgi.server_port_secure = "false";
				request.cgi.server_name = "localhost";
				request.cgi.http_x_forwarded_proto = "";
				application.wheels.baseUrl = "";
				application.wheels.environment = "development";
				StructDelete(application.wheels, "$baseUrlUnsetWarned");
				StructDelete(application.wheels, "$forwardedProtoTrustWarned");
			});

			it("uses the configured scheme and host and drops the request port", () => {
				application.wheels.baseUrl = "https://example.com";
				expect(application.wo.$prependUrl(path = "/posts/1")).toBe("https://example.com/posts/1");
			});

			it("keeps an explicit port from the baseUrl", () => {
				application.wheels.baseUrl = "https://example.com:8443";
				expect(application.wo.$prependUrl(path = "/x")).toBe("https://example.com:8443/x");
			});

			it("honours an http baseUrl even though the request looks upgradeable", () => {
				request.cgi.http_x_forwarded_proto = "https";
				application.wheels.baseUrl = "http://example.com";
				expect(application.wo.$prependUrl(path = "/x")).toBe("http://example.com/x");
			});

			it("tolerates a trailing slash on the baseUrl", () => {
				application.wheels.baseUrl = "https://example.com/";
				expect(application.wo.$prependUrl(path = "/x")).toBe("https://example.com/x");
			});

			it("falls back to the request scheme/host/port when baseUrl is unset", () => {
				application.wheels.baseUrl = "";
				expect(application.wo.$prependUrl(path = "/x")).toBe("http://localhost:8080/x");
			});

			it("lets an explicit host argument override the baseUrl host", () => {
				application.wheels.baseUrl = "https://example.com";
				expect(application.wo.$prependUrl(path = "/x", host = "other.example.org")).toBe("https://other.example.org/x");
			});

			it("lets an explicit protocol argument override the baseUrl scheme", () => {
				application.wheels.baseUrl = "https://example.com";
				expect(application.wo.$prependUrl(path = "/x", protocol = "http")).toBe("http://example.com/x");
			});

			it("does not consult X-Forwarded-Proto (no warning) when baseUrl supplies the scheme", () => {
				request.cgi.http_x_forwarded_proto = "https";
				application.wheels.trustProxyHeaders = false;
				application.wheels.baseUrl = "https://example.com";
				application.wo.$prependUrl(path = "/x");
				expect(StructKeyExists(application.wheels, "$forwardedProtoTrustWarned")).toBeFalse();
			});

			it("throws Wheels.IncorrectConfiguration on a baseUrl with no scheme", () => {
				application.wheels.baseUrl = "example.com";
				expect(() => application.wo.$prependUrl(path = "/x")).toThrow("Wheels.IncorrectConfiguration");
			});

			it("throws Wheels.IncorrectConfiguration on a baseUrl that includes a path", () => {
				application.wheels.baseUrl = "https://example.com/app";
				expect(() => application.wo.$prependUrl(path = "/x")).toThrow("Wheels.IncorrectConfiguration");
			});

			it("warns once in production when baseUrl is unset", () => {
				application.wheels.environment = "production";
				application.wheels.baseUrl = "";
				application.wo.$prependUrl(path = "/x");
				expect(StructKeyExists(application.wheels, "$baseUrlUnsetWarned")).toBeTrue();
			});

			it("does not warn outside production when baseUrl is unset", () => {
				application.wheels.environment = "development";
				application.wheels.baseUrl = "";
				application.wo.$prependUrl(path = "/x");
				expect(StructKeyExists(application.wheels, "$baseUrlUnsetWarned")).toBeFalse();
			});

			it("does not warn in production when baseUrl is set", () => {
				application.wheels.environment = "production";
				application.wheels.baseUrl = "https://example.com";
				application.wo.$prependUrl(path = "/x");
				expect(StructKeyExists(application.wheels, "$baseUrlUnsetWarned")).toBeFalse();
			});

		});
	}
}
