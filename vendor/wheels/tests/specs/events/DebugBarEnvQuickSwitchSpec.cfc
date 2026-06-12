component extends="wheels.WheelsTest" {

	function run() {
		describe("debug.cfm environment quick-switch links (issue 3060)", () => {
			// Since ##2082, switching environments via ?reload=<env> requires a
			// non-empty reloadPassword plus a matching password parameter, and is
			// additionally gated by allowEnvironmentSwitchViaUrl. The debug bar's
			// Environment panel used to render the quick-switch anchors only when
			// NO reloadPassword was set — the exact configuration where switching
			// is impossible — and the anchors embedded no password, so clicking
			// one silently restarted the app in the same environment. The fixed
			// behavior renders the links only when switching CAN work, as
			// prompt-based links that never embed the password in the page.

			it("renders no quick-switch links when reloadPassword is empty", () => {
				var output = $renderDebugBar(reloadPassword = "", allowSwitch = true);
				expect(output contains 'data-wdb-reload="').toBeFalse(
					"quick-switch links must not render without a reloadPassword (switching cannot work)"
				);
				expect(output contains "margin-left:4px").toBeFalse(
					"the legacy dead quick-switch anchors must not render when reloadPassword is empty"
				);
				// The plain one-click reload anchor keeps its pre-existing no-password gate.
				expect(output contains 'title="Reload Application"').toBeTrue(
					"the plain ?reload=true anchor must keep rendering when no reloadPassword is set"
				);
			});

			it("renders prompt-based quick-switch links when a reloadPassword is set and switching is allowed", () => {
				var output = $renderDebugBar(reloadPassword = "spec-secret-pw-3060", allowSwitch = true);
				expect(output contains 'data-wdb-reload="').toBeTrue(
					"quick-switch links must render when a reloadPassword is configured and allowEnvironmentSwitchViaUrl is true"
				);
				expect(output contains "wdbEnvSwitch").toBeTrue(
					"quick-switch links must go through the password prompt handler"
				);
				expect(output contains "spec-secret-pw-3060").toBeFalse(
					"the reload password must never be embedded in the rendered page"
				);
				// The plain one-click reload anchor keeps its pre-existing password gate.
				expect(output contains 'title="Reload Application"').toBeFalse(
					"the plain ?reload=true anchor must stay hidden when a reloadPassword is set"
				);
			});

			it("renders no quick-switch links when allowEnvironmentSwitchViaUrl is false even with a password set", () => {
				var output = $renderDebugBar(reloadPassword = "spec-secret-pw-3060", allowSwitch = false);
				expect(output contains 'data-wdb-reload="').toBeFalse(
					"quick-switch links must not render when environment switching via URL is disallowed"
				);
			});
		});
	}

	/**
	 * Renders the debug bar template with the given reloadPassword and
	 * allowEnvironmentSwitchViaUrl applied, restoring all touched state.
	 * Modeled on debugBarEncodingSpec.cfc.
	 */
	private string function $renderDebugBar(required string reloadPassword, required boolean allowSwitch) {
		var priorReloadPassword = application.wheels.reloadPassword;
		var hadAllowSwitch = StructKeyExists(application.wheels, "allowEnvironmentSwitchViaUrl");
		var priorAllowSwitch = hadAllowSwitch ? application.wheels.allowEnvironmentSwitchViaUrl : true;
		var priorReqWheels = StructKeyExists(request, "wheels") ? Duplicate(request.wheels) : {};
		// debug.cfm bails out (cfexit) when url.format is one of json/xml/csv/pdf
		// so it never breaks an API response. The test runner is hit with
		// format=json — clear it for the duration of the include.
		var hadUrlFormat = StructKeyExists(url, "format");
		var priorUrlFormat = hadUrlFormat ? url.format : "";
		var output = "";
		try {
			application.wheels.reloadPassword = arguments.reloadPassword;
			application.wheels.allowEnvironmentSwitchViaUrl = arguments.allowSwitch;
			if (!StructKeyExists(request, "wheels")) {
				request.wheels = {};
			}
			request.wheels.execution = {total = 0};
			request.wheels.params = {controller = "wheels", action = "tests", route = ""};
			if (hadUrlFormat) {
				StructDelete(url, "format");
			}
			output = application.wo.$includeAndReturnOutput($template = "/wheels/events/onrequestend/debug.cfm");
		} finally {
			application.wheels.reloadPassword = priorReloadPassword;
			if (hadAllowSwitch) {
				application.wheels.allowEnvironmentSwitchViaUrl = priorAllowSwitch;
			} else {
				StructDelete(application.wheels, "allowEnvironmentSwitchViaUrl");
			}
			request.wheels = priorReqWheels;
			if (hadUrlFormat) {
				url.format = priorUrlFormat;
			}
		}
		return output;
	}

}
