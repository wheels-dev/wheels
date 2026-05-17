component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that $header()", () => {

			// Regression: Adobe CF 2023 throws "Failed to add HTML header" when
			// `cfheader(attributeCollection = "#arguments#")` receives the raw
			// arguments scope. The helper must hand cfheader a plain struct.
			// See issue #2741.

			afterEach(() => {
				cfheader(statuscode = 200)
				g.$header(name = "content-type", value = "text/html", charset = "utf-8")
			})

			it("accepts a name/value pair without throwing", () => {
				$assert.notThrows(function() {
					g.$header(name = "X-Test-Header", value = "ok")
				})
			})

			it("accepts statusCode without throwing", () => {
				$assert.notThrows(function() {
					g.$header(statusCode = 201)
				})
			})

			it("silently strips statusText (removed in Adobe CF 2025)", () => {
				$assert.notThrows(function() {
					g.$header(statusCode = 500, statusText = "Internal Server Error")
				})
			})

			it("accepts charset/value combo without throwing", () => {
				$assert.notThrows(function() {
					g.$header(name = "Content-Type", value = "application/json", charset = "utf-8")
				})
			})

		})

	}
}
