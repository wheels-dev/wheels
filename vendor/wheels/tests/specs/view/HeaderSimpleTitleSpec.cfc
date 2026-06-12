component extends="wheels.WheelsTest" {

	function run() {

		// GH #3175 — _header_simple.cfm hardcoded `<title>Wheels - Error</title>`.
		// The partial is shared by the error page (EventMethods.$runOnError, where
		// the error title is correct) AND the fresh-install welcome page
		// (congratulations.cfm, where it is wrong). The title is now parameterized:
		// it defaults to "Wheels" and the error handler sets request.wheels.pageTitle
		// to override it.
		describe("_header_simple.cfm page title (#chr(35)#3175)", () => {

			it("defaults the <title> to 'Wheels' (not the error title) for the welcome page", () => {
				// No override present — simulates the welcome-page include path.
				if (StructKeyExists(request, "wheels") && IsStruct(request.wheels)) {
					StructDelete(request.wheels, "pageTitle")
				}

				var html = application.wo.$includeAndReturnOutput(
					$template = "/wheels/public/layout/_header_simple.cfm"
				)

				expect(html).toInclude("<title>Wheels</title>")
				expect(html).notToInclude("<title>Wheels - Error</title>")
			})

			it("honours request.wheels.pageTitle so the error page keeps its 'Wheels - Error' title", () => {
				if (!StructKeyExists(request, "wheels") || !IsStruct(request.wheels)) {
					request.wheels = {}
				}
				request.wheels.pageTitle = "Wheels - Error"

				var html = ""
				try {
					html = application.wo.$includeAndReturnOutput(
						$template = "/wheels/public/layout/_header_simple.cfm"
					)
					expect(html).toInclude("<title>Wheels - Error</title>")
				} finally {
					StructDelete(request.wheels, "pageTitle")
				}
			})
		})
	}
}
