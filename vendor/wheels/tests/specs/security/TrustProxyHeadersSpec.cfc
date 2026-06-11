component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Duplicate so member mutations inside specs cannot leak into the saved copy.
		variables.$$oldCGIScope = Duplicate(request.cgi);
		variables.$$hasOriginalTrustProxyHeaders = StructKeyExists(application.wheels, "trustProxyHeaders");
		if (variables.$$hasOriginalTrustProxyHeaders) {
			variables.$$originalTrustProxyHeaders = application.wheels.trustProxyHeaders;
		}
		params = {controller = "dummy", action = "dummy"};
		_controller = application.wo.controller("dummy", params);
	}

	function afterAll() {
		request.cgi = variables.$$oldCGIScope;
		if (variables.$$hasOriginalTrustProxyHeaders) {
			application.wheels.trustProxyHeaders = variables.$$originalTrustProxyHeaders;
		} else {
			StructDelete(application.wheels, "trustProxyHeaders");
		}
	}

	function run() {

		describe("trustProxyHeaders setting default", () => {

			it("exists in application.wheels and defaults to false", () => {
				expect(StructKeyExists(application.wheels, "trustProxyHeaders")).toBeTrue(
					"events/init/security.cfm should set a trustProxyHeaders default so apps can opt in to X-Forwarded-* trust behind a trusted reverse proxy."
				);
				expect(application.wheels.trustProxyHeaders).toBeFalse(
					"trustProxyHeaders must default to false: X-Forwarded-* headers are client-controlled and must never be trusted without explicit opt-in."
				);
			});
		});

		describe("$trustedClientIp()", () => {

			afterEach(() => {
				application.wheels.trustProxyHeaders = false;
			});

			it("returns REMOTE_ADDR and ignores X-Forwarded-For when trust is off", () => {
				application.wheels.trustProxyHeaders = false;
				expect(
					application.wo.$trustedClientIp(remoteAddr = "10.0.0.5", forwardedFor = "203.0.113.99")
				).toBe("10.0.0.5");
			});

			it("returns the rightmost X-Forwarded-For hop when trust is on", () => {
				// Rightmost entry is the one appended by the trusted proxy nearest the app;
				// earlier entries are client-supplied and spoofable.
				application.wheels.trustProxyHeaders = true;
				expect(
					application.wo.$trustedClientIp(remoteAddr = "10.0.0.5", forwardedFor = "203.0.113.99, 198.51.100.7")
				).toBe("198.51.100.7");
			});

			it("falls back to REMOTE_ADDR when trust is on but X-Forwarded-For is empty", () => {
				application.wheels.trustProxyHeaders = true;
				expect(application.wo.$trustedClientIp(remoteAddr = "10.0.0.5", forwardedFor = "")).toBe("10.0.0.5");
				expect(application.wo.$trustedClientIp(remoteAddr = "10.0.0.5", forwardedFor = "   ")).toBe("10.0.0.5");
			});
		});

		describe("isSecure() proxy gating", () => {

			afterEach(() => {
				application.wheels.trustProxyHeaders = false;
				request.cgi.server_port_secure = variables.$$oldCGIScope.server_port_secure;
				request.cgi.http_x_forwarded_proto = variables.$$oldCGIScope.http_x_forwarded_proto;
			});

			it("ignores X-Forwarded-Proto https when trustProxyHeaders is off", () => {
				request.cgi.server_port_secure = "";
				request.cgi.http_x_forwarded_proto = "https";
				application.wheels.trustProxyHeaders = false;
				expect(_controller.isSecure()).toBeFalse(
					"A direct-HTTP client can send X-Forwarded-Proto: https, so it must be ignored unless the app opted into proxy trust."
				);
			});

			it("honors X-Forwarded-Proto https when trustProxyHeaders is on", () => {
				request.cgi.server_port_secure = "";
				request.cgi.http_x_forwarded_proto = "https";
				application.wheels.trustProxyHeaders = true;
				expect(_controller.isSecure()).toBeTrue();
			});

			it("returns true from server_port_secure regardless of the setting", () => {
				request.cgi.server_port_secure = "true";
				request.cgi.http_x_forwarded_proto = "";
				application.wheels.trustProxyHeaders = false;
				expect(_controller.isSecure()).toBeTrue();
			});
		});

		describe("$maintenanceModeExempt()", () => {

			it("returns false when the exception list is empty", () => {
				expect(
					application.wo.$maintenanceModeExempt(exceptions = "", userAgent = "x", clientIp = "1.2.3.4")
				).toBeFalse();
			});

			it("exempts a client IP present in a numeric exception list", () => {
				expect(
					application.wo.$maintenanceModeExempt(
						exceptions = "1.2.3.4,5.6.7.8",
						userAgent = "x",
						clientIp = "5.6.7.8"
					)
				).toBeTrue();
			});

			it("does not exempt a client IP missing from the list", () => {
				expect(
					application.wo.$maintenanceModeExempt(
						exceptions = "1.2.3.4,5.6.7.8",
						userAgent = "x",
						clientIp = "9.9.9.9"
					)
				).toBeFalse();
			});

			it("matches the user agent when the exception list contains letters", () => {
				// Preserves the legacy routing: a list containing letters is matched
				// against the user agent instead of the client IP.
				expect(
					application.wo.$maintenanceModeExempt(
						exceptions = "GoogleBot",
						userAgent = "GoogleBot",
						clientIp = ""
					)
				).toBeTrue();
			});
		});

		describe("source regression scans", () => {

			// Plain find()/findNoCase() only (no regex) per the Lucee 7 global-regex
			// gotcha. Path resolution prior art: specs/environment/ipbasedaccessSpec.cfc.

			it("EventMethods.cfc no longer writes url.except into application scope", () => {
				var src = fileRead(expandPath("/wheels/events/EventMethods.cfc"));
				expect(find("application.wheels.ipExceptions = url.except", src)).toBe(
					0,
					"The legacy ?except= URL parameter let any anonymous client rewrite the maintenance exception list for everyone; request data must never be written into the application scope."
				);
				expect(find('StructKeyExists(url, "except")', src)).toBe(
					0,
					"Maintenance exceptions must come from config only (set(ipExceptions=...)), not from the URL."
				);
			});

			it("EventMethods.cfc resolves the maintenance client IP through the trusted-proxy helper", () => {
				var src = fileRead(expandPath("/wheels/events/EventMethods.cfc"));
				expect(findNoCase("$trustedClientIp", src) > 0).toBeTrue(
					"Maintenance-mode IP matching must go through $trustedClientIp() so X-Forwarded-For is only honored behind a trusted proxy."
				);
			});

			it("onapplicationstart.cfc keys the reload rate limit through the trusted-proxy helper", () => {
				var src = fileRead(expandPath("/wheels/events/onapplicationstart.cfc"));
				expect(findNoCase("reloadRateLimitKey = cgi.remote_addr", src)).toBe(
					0,
					"The reload rate-limit key must be derived from the trusted client IP helper, not raw REMOTE_ADDR."
				);
				expect(findNoCase("$trustedClientIp", src) > 0).toBeTrue(
					"The reload rate-limit key must go through $trustedClientIp() so proxy deployments can opt into per-client buckets."
				);
			});

			it("miscellaneous.cfc gates X-Forwarded-Proto behind trustProxyHeaders", () => {
				var src = fileRead(expandPath("/wheels/controller/miscellaneous.cfc"));
				expect(findNoCase("$trustProxyHeaders", src) > 0).toBeTrue(
					"isSecure() must only honor X-Forwarded-Proto when the app opted in via set(trustProxyHeaders=true)."
				);
			});
		});
	}
}
