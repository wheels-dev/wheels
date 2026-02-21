component extends="wheels.Testbox" {

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
		})
	}
}