component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Store original settings to restore later
		variables.originalEnvironment = application.wheels.environment;
		if (StructKeyExists(application.wheels, "allowIPBasedDebugAccess")) {
			variables.originalAllowIPBasedDebugAccess = application.wheels.allowIPBasedDebugAccess;
		}
		if (StructKeyExists(application.wheels, "debugAccessIPs")) {
			variables.originalDebugAccessIPs = application.wheels.debugAccessIPs;
		}
		if (StructKeyExists(application.wheels, "enablePublicComponent")) {
			variables.originalEnablePublicComponent = application.wheels.enablePublicComponent;
		}
		if (StructKeyExists(application.wheels, "debugAccessTrustProxy")) {
			variables.originalDebugAccessTrustProxy = application.wheels.debugAccessTrustProxy;
		}
	}

	function afterAll() {
		// Restore original settings
		application.wheels.environment = variables.originalEnvironment;
		if (StructKeyExists(variables, "originalAllowIPBasedDebugAccess")) {
			application.wheels.allowIPBasedDebugAccess = variables.originalAllowIPBasedDebugAccess;
		}
		if (StructKeyExists(variables, "originalDebugAccessIPs")) {
			application.wheels.debugAccessIPs = variables.originalDebugAccessIPs;
		}
		if (StructKeyExists(variables, "originalEnablePublicComponent")) {
			application.wheels.enablePublicComponent = variables.originalEnablePublicComponent;
		}
		if (StructKeyExists(variables, "originalDebugAccessTrustProxy")) {
			application.wheels.debugAccessTrustProxy = variables.originalDebugAccessTrustProxy;
		}
	}

	function run() {
		
		describe("IP-Based Debug Access Tests", () => {
			
			it("development environment always enables public component regardless of IP", () => {
				// Set up development environment
				application.wheels.environment = "development";
				application.wheels.allowIPBasedDebugAccess = false;
				application.wheels.debugAccessIPs = [];
				
				// Simulate application restart event
				application.wheels.enablePublicComponent = false;
				if (application.wheels.environment == "development") {
					application.wheels.enablePublicComponent = true;
				}
				
				expect(application.wheels.enablePublicComponent).toBeTrue();
			});
			
			it("testing environment with IP-based access enabled and matching IP should enable public component", () => {
				// Set up testing environment with IP-based access
				application.wheels.environment = "testing";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["127.0.0.1"];
				application.wheels.enablePublicComponent = false;
				
				// Simulate request start with matching IP
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
						application.wheels.showDebugInformation = true;
						application.wheels.showErrorInformation = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeTrue();
				expect(application.wheels.showDebugInformation).toBeTrue();
				expect(application.wheels.showErrorInformation).toBeTrue();
			});
			
			it("testing environment with IP-based access enabled and non-matching IP should not enable public component", () => {
				// Set up testing environment with IP-based access
				application.wheels.environment = "testing";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["192.168.1.1"];
				application.wheels.enablePublicComponent = false;
				application.wheels.showDebugInformation = false;
				application.wheels.showErrorInformation = false;
				
				// Simulate request start with non-matching IP
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
						application.wheels.showDebugInformation = true;
						application.wheels.showErrorInformation = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeFalse();
				expect(application.wheels.showDebugInformation).toBeFalse();
				expect(application.wheels.showErrorInformation).toBeFalse();
			});
			
			it("testing environment with IP-based access disabled should not enable public component even with matching IP", () => {
				// Set up testing environment with IP-based access disabled
				application.wheels.environment = "testing";
				application.wheels.allowIPBasedDebugAccess = false;
				application.wheels.debugAccessIPs = ["127.0.0.1"];
				application.wheels.enablePublicComponent = false;
				application.wheels.showDebugInformation = false;
				application.wheels.showErrorInformation = false;
				
				// Simulate request start with matching IP
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
						application.wheels.showDebugInformation = true;
						application.wheels.showErrorInformation = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeFalse();
				expect(application.wheels.showDebugInformation).toBeFalse();
				expect(application.wheels.showErrorInformation).toBeFalse();
			});
			
			it("production environment with IP-based access enabled and matching IP should enable public component", () => {
				// Set up production environment with IP-based access
				application.wheels.environment = "production";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["127.0.0.1"];
				application.wheels.enablePublicComponent = false;
				application.wheels.showDebugInformation = false;
				application.wheels.showErrorInformation = false;
				
				// Simulate request start with matching IP
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
						application.wheels.showDebugInformation = true;
						application.wheels.showErrorInformation = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeTrue();
				expect(application.wheels.showDebugInformation).toBeTrue();
				expect(application.wheels.showErrorInformation).toBeTrue();
			});
			
			it("should handle multiple IPs in the debugAccessIPs array", () => {
				// Set up production environment with multiple IPs
				application.wheels.environment = "production";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["192.168.1.1", "10.0.0.1", "127.0.0.1"];
				application.wheels.enablePublicComponent = false;
				
				// Simulate request start with matching IP (the last one in the array)
				local.clientIP = "127.0.0.1";
				
				// Simulate application.cfc onRequestStart logic
				if (application.wheels.environment != 'development' && application.wheels.allowIPBasedDebugAccess) {
					if (arrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
						application.wheels.enablePublicComponent = true;
					}
				}
				
				expect(application.wheels.enablePublicComponent).toBeTrue();
			});
		});

		describe("Debug Access Trust Proxy Default", () => {

			it("debugAccessTrustProxy defaults to false", () => {
				expect(StructKeyExists(application.wheels, "debugAccessTrustProxy")).toBeTrue(
					"events/init/security.cfm should set a debugAccessTrustProxy default so apps can opt in to X-Forwarded-For resolution behind a trusted proxy."
				);
				expect(application.wheels.debugAccessTrustProxy).toBeFalse(
					"debugAccessTrustProxy must default to false: X-Forwarded-For is client-controlled and must never be trusted without explicit opt-in."
				);
			});

			it("resolves the client IP from REMOTE_ADDR when trust proxy is disabled, ignoring X-Forwarded-For", () => {
				// Mirrors the gated resolution logic in public/Application.cfc onRequestStart.
				var remoteAddr = "10.0.0.5";
				var forwardedFor = "203.0.113.99"; // attacker-controlled header value
				var trustProxy = false;
				var clientIP = Trim(remoteAddr);
				if (trustProxy && Len(Trim(forwardedFor))) {
					clientIP = Trim(ListLast(forwardedFor));
				}
				expect(clientIP).toBe("10.0.0.5");
			});

			it("resolves the client IP from the rightmost X-Forwarded-For entry when trust proxy is enabled", () => {
				// Rightmost entry is the one appended by the trusted proxy nearest the app;
				// earlier entries are client-supplied and spoofable.
				var remoteAddr = "10.0.0.5";
				var forwardedFor = "203.0.113.99, 198.51.100.7";
				var trustProxy = true;
				var clientIP = Trim(remoteAddr);
				if (trustProxy && Len(Trim(forwardedFor))) {
					clientIP = Trim(ListLast(forwardedFor));
				}
				expect(clientIP).toBe("198.51.100.7");
			});
		});

		describe("Debug Access Client IP Source Regression", () => {

			// Source-scan regression: the debug-access allowlist must not match
			// attacker-controlled X-Forwarded-For input. CGI keys always exist
			// (empty string), so `CGI.HTTP_X_FORWARDED_FOR ?: CGI.REMOTE_ADDR`
			// handed header input straight to the allowlist. Plain find()/
			// findNoCase() only (no regex) per the Lucee 7 global-regex gotcha.
			// Repo-root resolution prior art: specs/cli/UpgradeCheckCoverageSpec.cfc.

			it("public/Application.cfc does not trust X-Forwarded-For unconditionally for debug access", () => {
				var filePath = expandPath("/wheels/../..") & "/public/Application.cfc";
				expect(fileExists(filePath)).toBeTrue("Missing: " & filePath);
				var src = fileRead(filePath);
				expect(find("CGI.HTTP_X_FORWARDED_FOR ?: CGI.REMOTE_ADDR", src)).toBe(
					0,
					"Vulnerable elvis pattern present: debug-access client IP must default to CGI.REMOTE_ADDR."
				);
				expect(findNoCase("debugAccessTrustProxy", src) > 0).toBeTrue(
					"X-Forwarded-For use must be gated behind the debugAccessTrustProxy setting."
				);
			});

			it("CLI app template Application.cfc does not trust X-Forwarded-For unconditionally for debug access", () => {
				var filePath = expandPath("/wheels/../..") & "/cli/lucli/templates/app/public/Application.cfc";
				expect(fileExists(filePath)).toBeTrue("Missing: " & filePath);
				var src = fileRead(filePath);
				expect(find("CGI.HTTP_X_FORWARDED_FOR ?: CGI.REMOTE_ADDR", src)).toBe(
					0,
					"Vulnerable elvis pattern present: debug-access client IP must default to CGI.REMOTE_ADDR."
				);
				expect(findNoCase("debugAccessTrustProxy", src) > 0).toBeTrue(
					"X-Forwarded-For use must be gated behind the debugAccessTrustProxy setting."
				);
			});

			it("starter-app example Application.cfc does not trust X-Forwarded-For unconditionally for debug access", () => {
				var filePath = expandPath("/wheels/../..") & "/examples/starter-app/public/Application.cfc";
				// Example trees may be pruned from some distributions; only assert when present.
				if (fileExists(filePath)) {
					var src = fileRead(filePath);
					expect(find("CGI.HTTP_X_FORWARDED_FOR ?: CGI.REMOTE_ADDR", src)).toBe(
						0,
						"Vulnerable elvis pattern present: debug-access client IP must default to CGI.REMOTE_ADDR."
					);
					expect(findNoCase("debugAccessTrustProxy", src) > 0).toBeTrue(
						"X-Forwarded-For use must be gated behind the debugAccessTrustProxy setting."
					);
				} else {
					expect(true).toBeTrue();
				}
			});

			it("tweet example Application.cfc does not trust X-Forwarded-For unconditionally for debug access", () => {
				var filePath = expandPath("/wheels/../..") & "/examples/tweet/public/Application.cfc";
				// Example trees may be pruned from some distributions; only assert when present.
				if (fileExists(filePath)) {
					var src = fileRead(filePath);
					expect(find("CGI.HTTP_X_FORWARDED_FOR ?: CGI.REMOTE_ADDR", src)).toBe(
						0,
						"Vulnerable elvis pattern present: debug-access client IP must default to CGI.REMOTE_ADDR."
					);
					expect(findNoCase("debugAccessTrustProxy", src) > 0).toBeTrue(
						"X-Forwarded-For use must be gated behind the debugAccessTrustProxy setting."
					);
				} else {
					expect(true).toBeTrue();
				}
			});
		});
	}
}
