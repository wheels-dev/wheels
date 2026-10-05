/**
 * IP-based debug access (set(allowIPBasedDebugAccess=true)) grants the debug
 * GUI and error details to an allowed client for ONE request. The grant lives
 * in request.wheels.debugAccess and application.wheels is never written, so a
 * concurrent request from another client can't render with that permission.
 *
 * Each "request" below runs against its own request.wheels (swapped in and
 * restored), which makes the interleaving deterministic: B is refused, A is
 * granted while B is still in flight, then B's exception is rendered.
 * The exception carries a harmless marker instead of real data.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("IP-based debug access is per request", () => {

			beforeEach(() => {
				variables.saved = {};
				for (var key in ["allowIPBasedDebugAccess", "debugAccessIPs", "debugAccessTrustProxy", "environment", "showErrorInformation", "showDebugInformation", "enablePublicComponent", "sendEmailOnError"]) {
					if (StructKeyExists(application.wheels, key)) {
						variables.saved[key] = application.wheels[key];
					}
				}
				variables.hadPublic = StructKeyExists(application.wheels, "public");
				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.debugAccessIPs = ["198.51.100.7"];
				application.wheels.debugAccessTrustProxy = false;
				application.wheels.environment = "production";
				application.wheels.showErrorInformation = false;
				application.wheels.showDebugInformation = false;
				application.wheels.enablePublicComponent = false;
				application.wheels.sendEmailOnError = false;
			});

			afterEach(() => {
				$restoreSettings();
			});

			it("a refused request renders its error without detail even while an allowed request holds its grant", () => {
				var marker = "ipdebug-isolation-marker";
				// B: another client, refused (runs in this request's scope).
				$applyIPDebugAccess(clientIP = "203.0.113.9");
				// A: the allowed client, granted in ITS OWN request while B is in flight.
				var aScope = $inOtherRequest(() => {
					$applyIPDebugAccess(clientIP = "198.51.100.7");
				});
				expect(aScope.debugAccess.showErrorInformation).toBeTrue("the allowed request was not granted");
				// B throws now; its error must use the production template.
				var rendered = $errorDouble().$runOnError(exception = $markerException(marker), eventName = "onRequest");
				expect(rendered).notToInclude(marker);
				expect(rendered).toBe("on-error-double-body");
				expect($get("showErrorInformation")).toBeFalse();
				expect($get("showDebugInformation")).toBeFalse();
				expect($get("enablePublicComponent")).toBeFalse();
			});

			it("the allowed request itself still gets the detail, and the application settings never change", () => {
				var marker = "ipdebug-allowed-marker";
				var state = {rendered = ""};
				$inOtherRequest(() => {
					$applyIPDebugAccess(clientIP = "198.51.100.7");
					state.rendered = $errorDouble().$runOnError(exception = $markerException(marker), eventName = "onRequest");
					state.debug = $get("showDebugInformation");
					state.gui = $get("enablePublicComponent");
				});
				expect(state.rendered).toInclude(marker);
				expect(state.debug).toBeTrue();
				expect(state.gui).toBeTrue();
				expect(application.wheels.showErrorInformation).toBeFalse("the grant was written to the shared application scope");
				expect(application.wheels.showDebugInformation).toBeFalse();
				expect(application.wheels.enablePublicComponent).toBeFalse();
			});

			it("grants nothing when the setting is off (the default), or in development", () => {
				var marker = "ipdebug-off-marker";
				application.wheels.allowIPBasedDebugAccess = false;
				var offScope = $inOtherRequest(() => {
					$applyIPDebugAccess(clientIP = "198.51.100.7");
				});
				expect(StructKeyExists(offScope, "debugAccess")).toBeFalse();
				expect($errorDouble().$runOnError(exception = $markerException(marker), eventName = "onRequest")).notToInclude(marker);

				application.wheels.allowIPBasedDebugAccess = true;
				application.wheels.environment = "development";
				var devScope = $inOtherRequest(() => {
					$applyIPDebugAccess(clientIP = "198.51.100.7");
				});
				expect(StructKeyExists(devScope, "debugAccess")).toBeFalse();

				// With nothing granted, the application setting still decides.
				application.wheels.showErrorInformation = true;
				expect($errorDouble().$runOnError(exception = $markerException(marker), eventName = "onRequest")).toInclude(marker);
			});

			it("ignores X-Forwarded-For unless debugAccessTrustProxy is on", () => {
				var clientIP = $ipDebugAccessClientIP();
				expect(clientIP).toBe(Trim(CGI.REMOTE_ADDR));
			});

		});

		describe("no sink reads the shared flags directly", () => {

			it("framework code reads showErrorInformation, showDebugInformation and enablePublicComponent through $get()", () => {
				var offenders = [];
				var root = ExpandPath("/wheels");
				var names = "(showErrorInformation|showDebugInformation|enablePublicComponent)";
				// Both a dot read (application.wheels.showErrorInformation) and a
				// bracket read (application.wheels["showErrorInformation"] / ['...'])
				// bypass the per-request grant, so the guard catches both forms.
				var flags = "application\.wheels\." & names;
				var flagsBracket = "application\.wheels\[\s*[""']" & names & "[""']\s*\]";
				for (var pattern in ["*.cfc", "*.cfm"]) {
					for (var path in DirectoryList(root, true, "path", pattern)) {
						var normalized = Replace(path, "\", "/", "all");
						if (FindNoCase("/wheels/tests/", normalized) || FindNoCase("/rocketunit_tests/", normalized)) {
							continue;
						}
						var lineNo = 0;
						for (var line in ListToArray(FileRead(path), Chr(10), true)) {
							lineNo++;
							if (ReFindNoCase("^\s*(//|\*|/\*)", line)) {
								continue;
							}
							// Drop assignments (a default being set), then look for a read.
							var reads = ReReplaceNoCase(line, flags & "\s*=([^=])", "\2", "all");
							reads = ReReplaceNoCase(reads, flagsBracket & "\s*=([^=])", "\2", "all");
							if (
								ReFindNoCase(flags & "([^A-Za-z0-9_]|$)", reads)
								|| ReFindNoCase(flagsBracket, reads)
							) {
								ArrayAppend(offenders, Replace(normalized, Replace(root, "\", "/", "all"), "") & ":" & lineNo);
							}
						}
					}
				}
				expect(offenders).toBe([], "direct reads bypass the per-request grant: " & ArrayToList(offenders, ", "));
			});

			it("the demo app and the wheels new template grant through the framework, not application.wheels", () => {
				$requireRepoPath("cli/lucli/templates/app/public/Application.cfc");
				for (var relative in ["/public/Application.cfc", "/cli/lucli/templates/app/public/Application.cfc"]) {
					var source = FileRead(ExpandPath("/wheels/../..") & relative);
					expect(source).toInclude("application.wo.$applyIPDebugAccess()");
					expect(ReFindNoCase("application\.wheels\.(showErrorInformation|showDebugInformation|enablePublicComponent)\s*=[^=]", source)).toBe(0, relative & " still writes a shared flag");
				}
			});

		});

		describe("the GHSA-8r22 fail-closed backstop for the legacy debug-IP block", () => {

			beforeEach(() => {
				variables.bk = {};
				variables.bkHad = {};
				for (var k in ["debugIPAccess", "$debugSettingsSnapshot", "showErrorInformation", "showDebugInformation", "enablePublicComponent", "$legacyDebugIpBlockWarned"]) {
					variables.bkHad[k] = StructKeyExists(application.wheels, k);
					if (variables.bkHad[k]) {
						variables.bk[k] = application.wheels[k];
					}
				}
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "debugAccess");
				}
				// Simulate an app that still carries the pre-4.1.2 debug-IP block:
				// its bookkeeping struct exists and the boot snapshot recorded the
				// configured (off) values.
				application.wheels.debugIPAccess = {originalShowErrorInformation = false};
				application.wheels.$debugSettingsSnapshot = {showErrorInformation = false, showDebugInformation = false, enablePublicComponent = false};
				StructDelete(application.wheels, "$legacyDebugIpBlockWarned");
			});

			afterEach(() => {
				for (var k in variables.bkHad) {
					if (variables.bkHad[k]) {
						application.wheels[k] = variables.bk[k];
					} else {
						StructDelete(application.wheels, k);
					}
				}
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "debugAccess");
				}
			});

			it("serves the boot snapshot, not the legacy block's shared write, for a concurrent request", () => {
				// Another request's legacy block just switched the shared flags on.
				application.wheels.showErrorInformation = true;
				application.wheels.showDebugInformation = true;
				application.wheels.enablePublicComponent = true;
				// This request holds no grant, so it must see the boot snapshot (off).
				expect($get("showErrorInformation")).toBeFalse("a concurrent request leaked error detail");
				expect($get("showDebugInformation")).toBeFalse();
				expect($get("enablePublicComponent")).toBeFalse();
			});

			it("warns once that Application.cfc must be updated", () => {
				application.wheels.showErrorInformation = true;
				$get("showErrorInformation");
				expect(StructKeyExists(application.wheels, "$legacyDebugIpBlockWarned")).toBeTrue();
			});

			it("still honours the per-request grant over the snapshot", () => {
				application.wheels.showErrorInformation = true;
				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				request.wheels.debugAccess = {showErrorInformation = true, showDebugInformation = true, enablePublicComponent = true};
				expect($get("showErrorInformation")).toBeTrue("the allowed request lost its grant");
			});

			it("honours a runtime set() of a flag through the snapshot", () => {
				set(showErrorInformation = true);
				expect($get("showErrorInformation")).toBeTrue("a runtime set() was ignored under the backstop");
			});

		});

	}

	/** Runs fn against a fresh request.wheels (another request) and returns that scope. */
	private struct function $inOtherRequest(required any fn) {
		var own = request.wheels;
		var other = {};
		request.wheels = other;
		try {
			arguments.fn();
			other = request.wheels;
		} finally {
			request.wheels = own;
		}
		return other;
	}

	private any function $errorDouble() {
		var em = CreateObject("component", "wheels.tests._assets.events.OnErrorEventDouble").init();
		em.formatOverride = "json";
		return em;
	}

	private struct function $markerException(required string marker) {
		return {type = "java.lang.RuntimeException", message = arguments.marker, detail = arguments.marker};
	}

	private void function $restoreSettings() {
		for (var key in ["allowIPBasedDebugAccess", "debugAccessIPs", "debugAccessTrustProxy", "environment", "showErrorInformation", "showDebugInformation", "enablePublicComponent", "sendEmailOnError"]) {
			if (StructKeyExists(variables.saved, key)) {
				application.wheels[key] = variables.saved[key];
			} else {
				StructDelete(application.wheels, key);
			}
		}
		if (!variables.hadPublic) {
			StructDelete(application.wheels, "public");
		}
		if (StructKeyExists(request, "wheels")) {
			StructDelete(request.wheels, "debugAccess");
		}
	}

}
