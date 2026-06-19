component extends="wheels.WheelsTest" {

	function run() {

		describe("Tests that onerror", () => {

			it("cfmlerror shows wheels templates", () => {
				try {
					Throw(type = "UnitTestError")
				} catch (any e) {
					exception = e
				}

				actual = application.wo.$includeAndReturnOutput($template = "/wheels/events/onerror/cfmlerror.cfm", exception = exception)

				// Check filename without path separators (EncodeForHTML encodes "/" on Adobe/BoxLang)
				// and without :line suffix (template and line number are in separate HTML elements)
				expect(actual).toInclude("onerrorSpec.cfc")
			})

			// Regression coverage for GH ##2319: Wheels-typed errors rendered
			// in HTML format used to leave the status code at Lucee's default
			// (200), misleading anything monitoring/alerting/retrying on
			// status. The mapping (RouteNotFound/RecordNotFound → 404,
			// everything else → 500) is mirrored from EventMethods.$runOnError;
			// this spec freezes the contract so a rename there breaks the
			// build immediately. Tested via a helper rather than a full
			// onError invocation because $runOnError needs an active request
			// scope and a real exception path that isn't easy to fake from
			// inside a spec.
			it("maps Wheels.RouteNotFound to HTTP 404 (##2319)", () => {
				expect($expectedStatusFor("Wheels.RouteNotFound")).toBe(404)
			})

			it("maps Wheels.RecordNotFound to HTTP 404 (##2319)", () => {
				expect($expectedStatusFor("Wheels.RecordNotFound")).toBe(404)
			})

			it("maps Wheels.ViewNotFound to HTTP 404 (##2319)", () => {
				expect($expectedStatusFor("Wheels.ViewNotFound")).toBe(404)
			})

			it("maps Wheels.PackageNotFound to HTTP 404 (##2319)", () => {
				// Any type ending in NotFound counts — futureproof against
				// new not-found types without requiring an enum update.
				expect($expectedStatusFor("Wheels.PackageNotFound")).toBe(404)
			})

			it("maps Wheels.DataSourceNotFound to HTTP 404 (##2319)", () => {
				// DataSourceNotFound also matches the *NotFound rule. A
				// missing datasource at the framework layer is closer to
				// "configured resource missing" than a blanket server
				// error, so 404 is the more honest status.
				expect($expectedStatusFor("Wheels.DataSourceNotFound")).toBe(404)
			})

			// GH ##3075: the action-dispatch gate ($callAction) blocks framework
			// helpers and $-prefixed internals by throwing Wheels.ActionNotAllowed.
			// #2845 and CLAUDE.md Anti-Pattern 8 promise that resolves to a 404,
			// but the *NotFound-only regex sent it to 500. ActionNotAllowed is now
			// an explicit member of the 404 set alongside the *NotFound family.
			it("maps Wheels.ActionNotAllowed to HTTP 404 (##3075)", () => {
				expect($expectedStatusFor("Wheels.ActionNotAllowed")).toBe(404)
			})

			it("maps a generic Wheels error type to HTTP 500 (##2319)", () => {
				expect($expectedStatusFor("Wheels.UnknownThingHappened")).toBe(500)
			})

			it("maps Wheels.ActionParameterMissing to HTTP 500 (Missing != NotFound, ##2319)", () => {
				expect($expectedStatusFor("Wheels.ActionParameterMissing")).toBe(500)
			})
		})

		// Security regression: $getRequestFormat must reject non-alphanumeric url.format (LFI via $runOnError's error-template include path).
		describe("$getRequestFormat rejects unsafe format tokens (T4 LFI)", () => {

			it("coerces ../ traversal tokens to html", () => {
				expect($requestFormatFor("../../../wheels/public/layout/_header_simple")).toBe("html")
			})

			it("coerces tokens containing a slash or dot to html", () => {
				expect($requestFormatFor("onerror.cfm/../x")).toBe("html")
			})

			it("preserves a valid alphanumeric format", () => {
				expect($requestFormatFor("json")).toBe("json")
			})

			it("preserves another valid format", () => {
				expect($requestFormatFor("xml")).toBe("xml")
			})

			it("falls back to html for an empty format", () => {
				expect($requestFormatFor("")).toBe("html")
			})
		})
	}

	private string function $requestFormatFor(required string formatValue) {
		var em = CreateObject("component", "wheels.events.EventMethods")
		var hadFormat = StructKeyExists(url, "format")
		var prior = hadFormat ? url.format : ""
		var result = ""
		try {
			url.format = arguments.formatValue
			result = em.$getRequestFormat()
		} finally {
			if (hadFormat) {
				url.format = prior
			} else {
				StructDelete(url, "format")
			}
		}
		return result
	}

	private numeric function $expectedStatusFor(required string wheelsType) {
		// Mirrors the status map in EventMethods.$runOnError. Keep the regex in
		// sync with that source — a rename or narrowing there must break here.
		if (ReFindNoCase("^Wheels\.([A-Za-z]*NotFound|ActionNotAllowed)$", arguments.wheelsType)) {
			return 404
		}
		return 500
	}
}