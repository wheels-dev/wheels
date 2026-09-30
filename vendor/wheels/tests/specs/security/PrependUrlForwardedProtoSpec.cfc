component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.$$oldCGI = Duplicate(request.cgi);
		variables.$$hadTPH = StructKeyExists(application.wheels, "trustProxyHeaders");
		if (variables.$$hadTPH) {
			variables.$$origTPH = application.wheels.trustProxyHeaders;
		}
		variables.$$hadWarned = StructKeyExists(application.wheels, "$forwardedProtoTrustWarned");
	}

	function afterAll() {
		request.cgi = variables.$$oldCGI;
		if (variables.$$hadTPH) {
			application.wheels.trustProxyHeaders = variables.$$origTPH;
		} else {
			StructDelete(application.wheels, "trustProxyHeaders");
		}
		if (!variables.$$hadWarned) {
			StructDelete(application.wheels, "$forwardedProtoTrustWarned");
		}
	}

	function run() {
		describe("$prependUrl scheme from X-Forwarded-Proto", () => {

			beforeEach(() => {
				request.cgi.server_port = 80;
				request.cgi.server_port_secure = "false";
				request.cgi.server_name = "example.com";
				request.cgi.http_x_forwarded_proto = "https";
			});

			it("still honours X-Forwarded-Proto for the scheme when trustProxyHeaders is off (4.1 behaviour)", () => {
				application.wheels.trustProxyHeaders = false;
				expect(Left(application.wo.$prependUrl(path = "/x"), 8)).toBe("https://");
			});

			it("warns once when the scheme comes from an untrusted X-Forwarded-Proto", () => {
				application.wheels.trustProxyHeaders = false;
				StructDelete(application.wheels, "$forwardedProtoTrustWarned");
				application.wo.$prependUrl(path = "/x");
				expect(StructKeyExists(application.wheels, "$forwardedProtoTrustWarned")).toBeTrue();
			});

			it("does not warn when trustProxyHeaders is on", () => {
				application.wheels.trustProxyHeaders = true;
				StructDelete(application.wheels, "$forwardedProtoTrustWarned");
				expect(Left(application.wo.$prependUrl(path = "/x"), 8)).toBe("https://");
				expect(StructKeyExists(application.wheels, "$forwardedProtoTrustWarned")).toBeFalse();
			});

			it("does not warn when the request is really on TLS", () => {
				application.wheels.trustProxyHeaders = false;
				request.cgi.http_x_forwarded_proto = "";
				request.cgi.server_port_secure = "true";
				StructDelete(application.wheels, "$forwardedProtoTrustWarned");
				expect(Left(application.wo.$prependUrl(path = "/x"), 8)).toBe("https://");
				expect(StructKeyExists(application.wheels, "$forwardedProtoTrustWarned")).toBeFalse();
			});

		});
	}
}
