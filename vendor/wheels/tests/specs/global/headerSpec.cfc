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
			// Each cfheader is wrapped in its own try/catch because Adobe CF 2023/2025
			// commits the response when a prior spec writes output, after which the
			// bare cfheader throws InvalidHeaderException ("Failed to add HTML header").
			// The cleanup is best-effort — a committed response keeps whatever headers
			// the engine wrote — and a thrown afterEach would surface as an opaque
			// lifecycle error masking the actual unit-under-test results, the exact
			// problem the bare-cfheader contract above was meant to avoid.
			afterEach(() => {
				try { cfheader(statuscode = 200); } catch (any e) {}
				try { cfheader(name = "content-type", value = "text/html"); } catch (any e) {}
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
