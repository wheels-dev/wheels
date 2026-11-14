/**
 * Regression for #4694 Part 2: a direct request for a missing physical .cfm
 * template used to throw inside Application.onRequest's include, land in
 * onError (HTTP 500 + the configured error email) and bypass onMissingTemplate.
 * These are HTTP-level assertions because the bug lives at the onRequest
 * boundary; a unit test of the predicate would not reproduce it.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("missing .cfm templates (##4694)", () => {

			it("answers 404 through onMissingTemplate with no onError fallback", () => {
				// These prefixes bypass the pretty-URL rewrite in both the LuCLI
				// test server and the container's Tuckey config, so the request
				// reaches Application.onRequest with the missing template (the #4694
				// path) instead of being rewritten to index.cfm.
				for (var path in ["/files/wheels-4694-missing.cfm", "/images/wheels-4694-missing.cfm"]) {
					var response = $testClient().get(path)
					expect(response.statusCode()).toBe(404, path & " should be 404")
					expect(response.content()).toInclude("File Not Found!", path & " should render onmissingtemplate.cfm")
					expect(response.content()).notToInclude("Wheels - Error", path & " must not render the onError page")
					expect(response.content()).notToInclude("Application Error", path & " must not render the onError fallback")
				}
			})

			it("does not turn direct missing .cfm paths into 500", () => {
				// Some deployments rewrite .cfm into index.cfm before CFML (the
				// container's Tuckey config does); those already answer 404 through
				// Dispatch. The bug this fixes is the direct-include path, which
				// must never become the onError fallback either.
				for (var path in ["/login.cfm", "/press/index.cfm", "/does-not-exist.cfm"]) {
					var response = $testClient().get(path)
					expect(response.statusCode()).toBe(404, path & " should be 404")
					expect(response.content()).notToInclude("Application Error", path & " must not render the onError fallback")
				}
			})

			it("still serves real .cfm entry points", () => {
				var response = $testClient().get("/index.cfm")
				expect(response.statusCode()).toBe(200)
				expect(response.content()).notToInclude("File Not Found!")
			})

		});

	}

}
