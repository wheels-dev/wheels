/**
 * Helper extracted from app-runner.cfm so the output-format rule is
 * unit-testable without spinning up an HTTP request. app-runner.cfm reads
 * url.format, hands it to this resolver, and uses the returned reporter /
 * contentType / rendersHtml / recognized fields to drive the response.
 *
 * Issue #3251 (item 1): the html / no-format branch historically emitted
 * application/json for the app runner — a user opening
 * `/wheels/app/tests?format=html` (or hitting the no-format default) in a
 * browser got raw JSON instead of the TestBox-style HTML report the core
 * runner (`/wheels/core/tests`) renders. resolveFormat() marks that branch
 * rendersHtml=true so the app runner falls through to html.cfm with
 * type="App" — a branch html.cfm already supports — exactly like the core
 * runner falls through with type="Core".
 *
 * Recognized formats (case-insensitive, trimmed): html | json | txt | junit,
 * plus the no-format default (no `format` key) which is treated as html. Any
 * other value — an empty string or an arbitrary token like "xml" — resolves
 * to recognized=false. The app runner emits nothing for an unrecognized
 * format, preserving the historical behavior: html.cfm must NOT be rendered
 * for an arbitrary url.format. Its dev-tools navigation
 * (vendor/wheels/tests/_navigation.cfm) builds format-toggle links from
 * url.format and the framework's response content-negotiation throws a 500
 * on Adobe when the format is unknown.
 */
component {

	variables.REPORTER_PACKAGE = "wheels.wheelstest.system.reports";

	public struct function resolveFormat(required struct url) {
		var htmlChoice = {
			format: "html",
			reporter: variables.REPORTER_PACKAGE & ".JSONReporter",
			contentType: "text/html",
			rendersHtml: true,
			recognized: true
		};

		// No format key at all is the no-format default → HTML report.
		if (!StructKeyExists(arguments.url, "format")) {
			return htmlChoice;
		}

		var format = LCase(Trim(arguments.url.format));

		switch (format) {
			case "html":
				return htmlChoice;
			case "json":
				return {
					format: "json",
					reporter: variables.REPORTER_PACKAGE & ".JSONReporter",
					contentType: "application/json",
					rendersHtml: false,
					recognized: true
				};
			case "txt":
				return {
					format: "txt",
					reporter: variables.REPORTER_PACKAGE & ".TextReporter",
					contentType: "text/plain",
					rendersHtml: false,
					recognized: true
				};
			case "junit":
				return {
					format: "junit",
					reporter: variables.REPORTER_PACKAGE & ".ANTJUnitReporter",
					contentType: "text/xml",
					rendersHtml: false,
					recognized: true
				};
			default:
				// Empty value or unrecognized token: not a known format. The app
				// runner emits nothing, matching the historical behavior and
				// avoiding an html.cfm render for an arbitrary url.format.
				return {
					format: format,
					reporter: "",
					contentType: "",
					rendersHtml: false,
					recognized: false
				};
		}
	}

}
