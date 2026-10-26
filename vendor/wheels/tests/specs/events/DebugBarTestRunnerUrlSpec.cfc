/**
 * Regression for #4642: the DebugBar Test Suite panel must not silently swap the
 * datasource. When the application allows tests against the primary datasource, both
 * the "Open full runner" link and the in-page JSON runner URL must carry
 * useTestDB=false; when the setting is off the URLs stay as they were.
 *
 * debug.cfm is rendered through $includeAndReturnOutput() with the same request mock
 * other DebugBar specs use (see DebugBarEnvQuickSwitchSpec).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("DebugBar test runner URLs (##4642)", () => {

			it("carries useTestDB=false on both runner URLs when the app allows tests against the primary datasource", () => {
				var output = $renderDebugBar(allowPrimary = true);
				var href = $match(output, 'href="[^"]*"[^>]*>Open full runner');
				var runUrl = $match(output, 'runUrl:[^}]*')

				expect(FindNoCase("useTestDB=false", href)).toBeGT(0, "full-runner link should pass useTestDB=false, got [#href#]")
				expect(FindNoCase("format=json", runUrl)).toBeGT(0, "JSON runner URL should keep its format, got [#runUrl#]")
				expect(FindNoCase("useTestDB=false", runUrl)).toBeGT(0, "JSON runner URL should pass useTestDB=false, got [#runUrl#]")
			})

			it("leaves both runner URLs unchanged when the setting is off", () => {
				var output = $renderDebugBar(allowPrimary = false);
				var href = $match(output, 'href="[^"]*"[^>]*>Open full runner');
				var runUrl = $match(output, 'runUrl:[^}]*')

				expect(FindNoCase("useTestDB", href)).toBe(0, "full-runner link should not add useTestDB, got [#href#]")
				expect(FindNoCase("useTestDB", runUrl)).toBe(0, "JSON runner URL should not add useTestDB, got [#runUrl#]")
				expect(FindNoCase("format=json", runUrl)).toBeGT(0)
			})

		})

	}

	/** Returns the first regex match, or "" when the pattern is absent. */
	private string function $match(required string output, required string pattern) {
		var match = REFindNoCase(arguments.pattern, arguments.output, 1, true)
		return match.pos[1] ? Mid(arguments.output, match.pos[1], match.len[1]) : ""
	}

	/**
	 * Renders the debug bar with allowTestsAgainstPrimaryDatasource applied, restoring
	 * all touched state. Modeled on DebugBarEnvQuickSwitchSpec.
	 */
	private string function $renderDebugBar(required boolean allowPrimary) {
		var hadSetting = StructKeyExists(application.wheels, "allowTestsAgainstPrimaryDatasource");
		var saved = hadSetting ? application.wheels.allowTestsAgainstPrimaryDatasource : false;
		var priorReqWheels = StructKeyExists(request, "wheels") ? Duplicate(request.wheels) : {};
		// debug.cfm bails out (cfexit) when url.format is json/xml/csv/pdf.
		var hadUrlFormat = StructKeyExists(url, "format");
		var priorUrlFormat = hadUrlFormat ? url.format : "";
		var output = ""
		try {
			application.wheels.allowTestsAgainstPrimaryDatasource = arguments.allowPrimary;
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
			if (hadSetting) {
				application.wheels.allowTestsAgainstPrimaryDatasource = saved;
			} else {
				StructDelete(application.wheels, "allowTestsAgainstPrimaryDatasource");
			}
			request.wheels = priorReqWheels;
			if (hadUrlFormat) {
				url.format = priorUrlFormat;
			}
		}
		return output;
	}

}
