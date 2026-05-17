component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that $header()", () => {

			// Regression: Adobe CF 2023 throws "Failed to add HTML header" when
			// `cfheader(attributeCollection = "#arguments#")` receives the raw
			// arguments scope. The helper must hand cfheader a plain struct.
			// See issue #2741.

			// Cleanup uses cfheader directly, not g.$header() — the function under test.
			// If $header() regresses, every spec should fail in its own `it`, not via
			// an opaque `afterEach` lifecycle error. Semicolons required: Lucee 7's
			// parser cannot disambiguate back-to-back `cfheader(...)` script calls.
			afterEach(() => {
				cfheader(statuscode = 200);
				cfheader(name = "content-type", value = "text/html");
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

		describe("Tests that \$responseCommitted()", () => {

			// The probe walks GetPageContext().getResponse().isCommitted(), which
			// has a known-good shape on every supported engine — but the helper
			// catches and returns false on engines where the call path is
			// unavailable. This spec confirms the declared `boolean` return
			// contract holds in-process on every engine in the matrix, so a
			// future engine API shift surfaces here instead of in a compat run.
			it("returns a boolean without throwing", () => {
				$assert.notThrows(function() {
					g.$responseCommitted()
				})
				expect(IsBoolean(g.$responseCommitted())).toBeTrue()
			})

		})

	}
}
