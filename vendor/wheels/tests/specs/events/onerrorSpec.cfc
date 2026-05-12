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

			it("maps a generic Wheels error type to HTTP 500 (##2319)", () => {
				expect($expectedStatusFor("Wheels.UnknownThingHappened")).toBe(500)
			})

			it("maps Wheels.ActionParameterMissing to HTTP 500 (Missing != NotFound, ##2319)", () => {
				expect($expectedStatusFor("Wheels.ActionParameterMissing")).toBe(500)
			})
		})
	}

	private numeric function $expectedStatusFor(required string wheelsType) {
		if (ReFindNoCase("^Wheels\.[A-Za-z]*NotFound$", arguments.wheelsType)) {
			return 404
		}
		return 500
	}
}