/**
 * Tests for SecurityHeaders middleware including CSP, HSTS, and Permissions-Policy.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("SecurityHeaders middleware", function() {

			beforeEach(function() {
				variables.nextHandler = function(required struct request) {
					return "ok";
				};
				variables.reqCtx = {cgi = {}};
			});

			describe("default headers", function() {

				it("sets four default security headers", function() {
					local.mw = new wheels.middleware.SecurityHeaders();
					expect(local.mw.$headers()).toHaveKey("X-Frame-Options");
					expect(local.mw.$headers()).toHaveKey("X-Content-Type-Options");
					expect(local.mw.$headers()).toHaveKey("X-XSS-Protection");
					expect(local.mw.$headers()).toHaveKey("Referrer-Policy");
				});

				it("does not set CSP by default", function() {
					local.mw = new wheels.middleware.SecurityHeaders();
					expect(local.mw.$headers()).notToHaveKey("Content-Security-Policy");
				});

				it("does not set HSTS by default when environment is not production", function() {
					local.mw = new wheels.middleware.SecurityHeaders();
					expect(local.mw.$headers()).notToHaveKey("Strict-Transport-Security");
				});

				it("does not set Permissions-Policy by default", function() {
					local.mw = new wheels.middleware.SecurityHeaders();
					expect(local.mw.$headers()).notToHaveKey("Permissions-Policy");
				});

			});

			describe("Content-Security-Policy", function() {

				it("sets CSP header when provided", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						contentSecurityPolicy = "default-src 'self'"
					);
					expect(local.mw.$headers()).toHaveKey("Content-Security-Policy");
					expect(local.mw.$headers()["Content-Security-Policy"]).toBe("default-src 'self'");
				});

				it("supports complex CSP directives", function() {
					local.policy = "default-src 'self'; script-src 'self' https://cdn.example.com; style-src 'self' 'unsafe-inline'";
					local.mw = new wheels.middleware.SecurityHeaders(
						contentSecurityPolicy = local.policy
					);
					expect(local.mw.$headers()["Content-Security-Policy"]).toBe(local.policy);
				});

				it("does not set CSP header when empty string", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						contentSecurityPolicy = ""
					);
					expect(local.mw.$headers()).notToHaveKey("Content-Security-Policy");
				});

			});

			describe("Strict-Transport-Security", function() {

				it("sets HSTS header when provided", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						strictTransportSecurity = "max-age=31536000; includeSubDomains"
					);
					expect(local.mw.$headers()).toHaveKey("Strict-Transport-Security");
					expect(local.mw.$headers()["Strict-Transport-Security"]).toBe("max-age=31536000; includeSubDomains");
				});

				it("supports HSTS with preload", function() {
					local.value = "max-age=63072000; includeSubDomains; preload";
					local.mw = new wheels.middleware.SecurityHeaders(
						strictTransportSecurity = local.value
					);
					expect(local.mw.$headers()["Strict-Transport-Security"]).toBe(local.value);
				});

				it("does not set HSTS header when empty string and not production", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						strictTransportSecurity = ""
					);
					expect(local.mw.$headers()).notToHaveKey("Strict-Transport-Security");
				});

				it("auto-defaults HSTS in production environment", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						environment = "production"
					);
					expect(local.mw.$headers()).toHaveKey("Strict-Transport-Security");
					expect(local.mw.$headers()["Strict-Transport-Security"]).toBe("max-age=31536000; includeSubDomains");
				});

				it("does not auto-default HSTS in development environment", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						environment = "development"
					);
					expect(local.mw.$headers()).notToHaveKey("Strict-Transport-Security");
				});

				it("does not auto-default HSTS in testing environment", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						environment = "testing"
					);
					expect(local.mw.$headers()).notToHaveKey("Strict-Transport-Security");
				});

				it("uses explicit HSTS value even in production", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						strictTransportSecurity = "max-age=86400",
						environment = "production"
					);
					expect(local.mw.$headers()["Strict-Transport-Security"]).toBe("max-age=86400");
				});

				it("does not set HSTS when environment is empty and no explicit value", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						environment = ""
					);
					expect(local.mw.$headers()).notToHaveKey("Strict-Transport-Security");
				});

				it("omits HSTS header when hsts=false even in production", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						environment = "production",
						hsts = false
					);
					expect(local.mw.$headers()).notToHaveKey("Strict-Transport-Security");
				});

				it("omits HSTS header when hsts=false and explicit strictTransportSecurity provided", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						strictTransportSecurity = "max-age=86400",
						hsts = false
					);
					expect(local.mw.$headers()).notToHaveKey("Strict-Transport-Security");
				});

				it("defaults hsts=true to preserve legacy production behavior", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						environment = "production"
					);
					expect(local.mw.$headers()).toHaveKey("Strict-Transport-Security");
					expect(local.mw.$headers()["Strict-Transport-Security"]).toBe("max-age=31536000; includeSubDomains");
				});

			});

			describe("Permissions-Policy", function() {

				it("sets Permissions-Policy header when provided", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						permissionsPolicy = "camera=(), microphone=(), geolocation=()"
					);
					expect(local.mw.$headers()).toHaveKey("Permissions-Policy");
					expect(local.mw.$headers()["Permissions-Policy"]).toBe("camera=(), microphone=(), geolocation=()");
				});

				it("does not set Permissions-Policy header when empty string", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						permissionsPolicy = ""
					);
					expect(local.mw.$headers()).notToHaveKey("Permissions-Policy");
				});

			});

			describe("disabling headers", function() {

				it("omits X-Frame-Options when set to empty string", function() {
					local.mw = new wheels.middleware.SecurityHeaders(frameOptions = "");
					expect(local.mw.$headers()).notToHaveKey("X-Frame-Options");
				});

				it("allows overriding default header values", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						frameOptions = "DENY",
						referrerPolicy = "no-referrer"
					);
					expect(local.mw.$headers()["X-Frame-Options"]).toBe("DENY");
					expect(local.mw.$headers()["Referrer-Policy"]).toBe("no-referrer");
				});

			});

			describe("handle()", function() {

				it("calls next handler and returns its result", function() {
					local.mw = new wheels.middleware.SecurityHeaders();
					local.result = local.mw.handle(
						req = variables.reqCtx,
						next = variables.nextHandler
					);
					expect(local.result).toBe("ok");
				});

				it("calls next handler even with all new headers configured", function() {
					local.mw = new wheels.middleware.SecurityHeaders(
						contentSecurityPolicy = "default-src 'self'",
						strictTransportSecurity = "max-age=31536000",
						permissionsPolicy = "camera=()"
					);
					local.result = local.mw.handle(
						req = variables.reqCtx,
						next = variables.nextHandler
					);
					expect(local.result).toBe("ok");
				});

			});

		});

	}

}
