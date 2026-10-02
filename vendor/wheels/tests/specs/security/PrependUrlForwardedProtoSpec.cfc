component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.$$oldCGI = Duplicate(request.cgi);
		variables.$$hadTPH = StructKeyExists(application.wheels, "trustProxyHeaders");
		if (variables.$$hadTPH) {
			variables.$$origTPH = application.wheels.trustProxyHeaders;
		}
	}

	function afterAll() {
		request.cgi = variables.$$oldCGI;
		if (variables.$$hadTPH) {
			application.wheels.trustProxyHeaders = variables.$$origTPH;
		} else {
			StructDelete(application.wheels, "trustProxyHeaders");
		}
	}

	function run() {
		describe("$prependUrl scheme from X-Forwarded-Proto (##3836)", () => {

			beforeEach(() => {
				request.cgi.server_port = 80;
				request.cgi.server_port_secure = "false";
				request.cgi.server_name = "example.com";
				request.cgi.http_x_forwarded_proto = "https";
			});

			it("ignores X-Forwarded-Proto for the scheme when trustProxyHeaders is off", () => {
				// 4.2: the client-controlled header no longer selects https:// without the
				// opt-in, so a spoofed header can't induce https:// absolute URLs (#3836).
				application.wheels.trustProxyHeaders = false;
				expect(Left(application.wo.$prependUrl(path = "/x"), 7)).toBe("http://");
			});

			it("honours X-Forwarded-Proto for the scheme when trustProxyHeaders is on", () => {
				application.wheels.trustProxyHeaders = true;
				expect(Left(application.wo.$prependUrl(path = "/x"), 8)).toBe("https://");
			});

			it("always honours the real socket TLS state regardless of trustProxyHeaders", () => {
				application.wheels.trustProxyHeaders = false;
				request.cgi.http_x_forwarded_proto = "";
				request.cgi.server_port_secure = "true";
				expect(Left(application.wo.$prependUrl(path = "/x"), 8)).toBe("https://");
			});

			it("falls back to http:// when neither the socket nor a trusted header is https", () => {
				application.wheels.trustProxyHeaders = false;
				request.cgi.http_x_forwarded_proto = "";
				request.cgi.server_port_secure = "false";
				expect(Left(application.wo.$prependUrl(path = "/x"), 7)).toBe("http://");
			});
		});
	}
}
