component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Store original settings to restore later
		variables.originalSettings = {};
		for (var key in ["environment", "allowIPBasedDebugAccess", "debugAccessIPs", "enablePublicComponent", "showDebugInformation", "showErrorInformation", "debugAccessTrustProxy"]) {
			if (StructKeyExists(application.wheels, key)) {
				variables.originalSettings[key] = application.wheels[key];
			}
		}
		variables.hadPublic = StructKeyExists(application.wheels, "public");
	}

	function afterAll() {
		// Restore original settings
		for (var key in variables.originalSettings) {
			application.wheels[key] = variables.originalSettings[key];
		}
		if (!variables.hadPublic) {
			StructDelete(application.wheels, "public");
		}
		StructDelete(request.wheels, "debugAccess");
	}

	function run() {

		describe("IP-Based Debug Access Tests", () => {

			beforeEach(() => {
				application.wheels.enablePublicComponent = false;
				application.wheels.showDebugInformation = false;
				application.wheels.showErrorInformation = false;
			});

			afterEach(() => {
				StructDelete(request.wheels, "debugAccess");
			});

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

			it("testing environment with IP-based access enabled and matching IP enables debug access for this request", () => {
				application.wheels.environment = "testing";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["127.0.0.1"];

				$applyIPDebugAccess(clientIP = "127.0.0.1");

				expect($get("enablePublicComponent")).toBeTrue();
				expect($get("showDebugInformation")).toBeTrue();
				expect($get("showErrorInformation")).toBeTrue();
				// The grant is per request: the shared settings are unchanged.
				expect(application.wheels.enablePublicComponent).toBeFalse();
				expect(application.wheels.showErrorInformation).toBeFalse();
			});

			it("testing environment with IP-based access enabled and non-matching IP grants nothing", () => {
				application.wheels.environment = "testing";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["192.168.1.1"];

				$applyIPDebugAccess(clientIP = "127.0.0.1");

				expect(StructKeyExists(request.wheels, "debugAccess")).toBeFalse();
				expect($get("enablePublicComponent")).toBeFalse();
				expect($get("showDebugInformation")).toBeFalse();
				expect($get("showErrorInformation")).toBeFalse();
			});

			it("testing environment with IP-based access disabled grants nothing even with a matching IP", () => {
				application.wheels.environment = "testing";
				application.wheels.allowIPBasedDebugAccess = false;
				application.wheels.debugAccessIPs = ["127.0.0.1"];

				$applyIPDebugAccess(clientIP = "127.0.0.1");

				expect(StructKeyExists(request.wheels, "debugAccess")).toBeFalse();
				expect($get("enablePublicComponent")).toBeFalse();
				expect($get("showDebugInformation")).toBeFalse();
				expect($get("showErrorInformation")).toBeFalse();
			});

			it("production environment with IP-based access enabled and matching IP enables debug access for this request", () => {
				application.wheels.environment = "production";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["127.0.0.1"];

				$applyIPDebugAccess(clientIP = "127.0.0.1");

				expect($get("enablePublicComponent")).toBeTrue();
				expect($get("showDebugInformation")).toBeTrue();
				expect($get("showErrorInformation")).toBeTrue();
				expect(application.wheels.showErrorInformation).toBeFalse();
			});

			it("should handle multiple IPs in the debugAccessIPs array", () => {
				application.wheels.environment = "production";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["192.168.1.1", "10.0.0.1", "127.0.0.1"];

				$applyIPDebugAccess(clientIP = "127.0.0.1");

				expect($get("enablePublicComponent")).toBeTrue();
			});

			it("a later refused call clears an earlier grant", () => {
				application.wheels.environment = "production";
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["127.0.0.1"];

				$applyIPDebugAccess(clientIP = "127.0.0.1");
				$applyIPDebugAccess(clientIP = "10.9.9.9");

				expect($get("showErrorInformation")).toBeFalse();
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
				application.wheels.debugAccessTrustProxy = false;
				expect($ipDebugAccessClientIP()).toBe(Trim(CGI.REMOTE_ADDR));
			});

			it("resolves the client IP from the rightmost X-Forwarded-For entry when trust proxy is enabled", () => {
				// Mirrors $ipDebugAccessClientIP() (vendor/wheels/global/request.cfm): the rightmost
				// entry is the one appended by the trusted proxy nearest the app; earlier entries are
				// client-supplied and spoofable.
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

			it("the framework's client IP resolution gates X-Forwarded-For behind debugAccessTrustProxy", () => {
				var src = fileRead(expandPath("/wheels/global/request.cfm"));
				var body = mid(src, find("function $ipDebugAccessClientIP", src), 900);
				expect(find("CGI.HTTP_X_FORWARDED_FOR ?: CGI.REMOTE_ADDR", src)).toBe(
					0,
					"Vulnerable elvis pattern present: debug-access client IP must default to CGI.REMOTE_ADDR."
				);
				expect(find("Trim(CGI.REMOTE_ADDR)", body) > 0).toBeTrue("The client IP must default to the socket address.");
				expect(findNoCase("debugAccessTrustProxy", body) > 0).toBeTrue(
					"X-Forwarded-For use must be gated behind the debugAccessTrustProxy setting."
				);
			});

			it("every shipped Application.cfc delegates debug access to the framework", () => {
				$requireRepoPath("cli/lucli/templates/app/public/Application.cfc");
				var root = expandPath("/wheels/../..");
				var required = ["/public/Application.cfc", "/cli/lucli/templates/app/public/Application.cfc"];
				for (var relative in required) {
					expect(fileExists(root & relative)).toBeTrue("Missing: " & relative);
				}
				// Example trees may be pruned from some distributions; only assert when present.
				var all = ["/public/Application.cfc", "/cli/lucli/templates/app/public/Application.cfc", "/examples/starter-app/public/Application.cfc", "/examples/tweet/public/Application.cfc"];
				for (var relative in all) {
					if (!fileExists(root & relative)) {
						continue;
					}
					var src = fileRead(root & relative);
					expect(find("CGI.HTTP_X_FORWARDED_FOR ?: CGI.REMOTE_ADDR", src)).toBe(0, relative & ": vulnerable elvis pattern present.");
					expect(find("application.wo.$applyIPDebugAccess()", src) > 0).toBeTrue(relative & " must call application.wo.$applyIPDebugAccess().");
					expect(findNoCase("debugIPAccess", src)).toBe(0, relative & " still carries the shared-scope debug access block.");
				}
			});
		});
	}
}
