/**
 * Issue ##3311 — dev-mode inline notice when ?reload=true is refused.
 *
 * Since the fail-closed reload gate (##3062, 4.0.4), a refused ?reload=true is
 * a silent no-op in the browser: the only signals are wheels_security.log and
 * the boot warning, which keeps producing "reload is broken" support reports.
 *
 * The app template's reload gate now records WHY a requested reload did not
 * fire in request.wheels.reloadRefusedReason ("emptyPassword",
 * "missingPasswordParam", or the deliberately generic "refused" for
 * wrong-password/rate-limited), and the debug bar renders a banner for it —
 * in the development environment only. The "refused" reason must stay a
 * single generic message so the notice adds no oracle distinguishing a wrong
 * password from a rate-limited source.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("debug.cfm reload-refused notice (issue 3311)", () => {

			it("renders the empty-password notice in development", () => {
				var output = $renderDebugBar(environment = "development", reason = "emptyPassword");
				expect(output contains 'data-wdb-reload-refused="emptyPassword"').toBeTrue(
					"the banner must render and carry the emptyPassword reason"
				);
				expect(output contains "<code>reloadPassword</code> is empty").toBeTrue(
					"the banner must name the setting that disables URL reload"
				);
				expect(output contains "config/settings.cfm").toBeTrue(
					"the banner must say where to set the reload password"
				);
			});

			it("renders the missing-password-parameter notice in development", () => {
				var output = $renderDebugBar(environment = "development", reason = "missingPasswordParam");
				expect(output contains 'data-wdb-reload-refused="missingPasswordParam"').toBeTrue(
					"the banner must render and carry the missingPasswordParam reason"
				);
				expect(output contains "password parameter").toBeTrue(
					"the banner must say the password URL parameter is required"
				);
			});

			it("renders one generic notice for wrong-password/rate-limited refusals", () => {
				var output = $renderDebugBar(environment = "development", reason = "refused");
				expect(output contains 'data-wdb-reload-refused="refused"').toBeTrue(
					"the banner must render and carry the generic refused reason"
				);
				expect(output contains "wheels_security.log").toBeTrue(
					"the generic notice must point at wheels_security.log"
				);
				// No oracle: the rendered notice must not say whether the password was
				// wrong or the source was rate-limited.
				expect(REFindNoCase("wrong|incorrect|rate.?limit", output) == 0).toBeTrue(
					"the generic notice must not distinguish wrong-password from rate-limited"
				);
			});

			it("renders no notice outside development even when a reason was recorded", () => {
				var output = $renderDebugBar(environment = "testing", reason = "emptyPassword");
				expect(output contains "data-wdb-reload-refused").toBeFalse(
					"the notice is a development-only surface (issue 3311 acceptance criteria)"
				);
			});

			it("renders no notice when no refusal reason was recorded", () => {
				var output = $renderDebugBar(environment = "development", reason = "");
				expect(output contains "data-wdb-reload-refused").toBeFalse(
					"no banner without a recorded refusal"
				);
			});

		});
	}

	/**
	 * Renders the debug bar template with the given environment and (optional)
	 * request.wheels.reloadRefusedReason applied, restoring all touched state.
	 * Modeled on DebugBarEnvQuickSwitchSpec.cfc.
	 */
	private string function $renderDebugBar(required string environment, required string reason) {
		var priorEnvironment = application.wheels.environment;
		var priorReqWheels = StructKeyExists(request, "wheels") ? Duplicate(request.wheels) : {};
		// debug.cfm bails out (cfexit) when url.format is one of json/xml/csv/pdf
		// so it never breaks an API response. The test runner is hit with
		// format=json — clear it for the duration of the include.
		var hadUrlFormat = StructKeyExists(url, "format");
		var priorUrlFormat = hadUrlFormat ? url.format : "";
		var output = "";
		try {
			application.wheels.environment = arguments.environment;
			if (!StructKeyExists(request, "wheels")) {
				request.wheels = {};
			}
			request.wheels.execution = {total = 0};
			request.wheels.params = {controller = "wheels", action = "tests", route = ""};
			if (Len(arguments.reason)) {
				request.wheels.reloadRefusedReason = arguments.reason;
			} else {
				StructDelete(request.wheels, "reloadRefusedReason");
			}
			if (hadUrlFormat) {
				StructDelete(url, "format");
			}
			output = application.wo.$includeAndReturnOutput($template = "/wheels/events/onrequestend/debug.cfm");
		} finally {
			application.wheels.environment = priorEnvironment;
			request.wheels = priorReqWheels;
			if (hadUrlFormat) {
				url.format = priorUrlFormat;
			}
		}
		return output;
	}

}
