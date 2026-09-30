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
		describe("$prependUrl scheme from X-Forwarded-Proto", () => {

			beforeEach(() => {
				request.cgi.server_port = 80;
				request.cgi.server_port_secure = "false";
				request.cgi.server_name = "example.com";
				request.cgi.http_x_forwarded_proto = "https";
			});

			it("ignores X-Forwarded-Proto when trustProxyHeaders is off", () => {
				application.wheels.trustProxyHeaders = false;
				expect(Left(application.wo.$prependUrl(path = "/x"), 7)).toBe("http://");
			});

			it("honours X-Forwarded-Proto when trustProxyHeaders is on", () => {
				application.wheels.trustProxyHeaders = true;
				expect(Left(application.wo.$prependUrl(path = "/x"), 8)).toBe("https://");
			});

			it("uses https from the real socket TLS regardless of the setting", () => {
				application.wheels.trustProxyHeaders = false;
				request.cgi.http_x_forwarded_proto = "";
				request.cgi.server_port_secure = "true";
				expect(Left(application.wo.$prependUrl(path = "/x"), 8)).toBe("https://");
			});

		});
	}
}
