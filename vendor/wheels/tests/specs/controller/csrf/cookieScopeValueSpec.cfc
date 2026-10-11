/**
 * The CSRF cookie as read from the cookie scope. When the request itself set the
 * cookie (cookie[name] = {value, httpOnly, ...}), Lucee, Adobe and BoxLang read it
 * back as its value, but RustCFML returns the struct that was assigned, so the reader
 * takes .value. Anything else that isn't a string reads as no cookie.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$csrfCookieScopeValue", () => {

			beforeEach(() => {
				_controller = application.wo.controller("CsrfProtectedWithException", {});
			});

			it("returns a cookie read as a string unchanged", () => {
				expect(_controller.$csrfCookieScopeValue("abc123==")).toBe("abc123==");
			});

			it("returns the value of a cookie read back as its attribute struct", () => {
				var assigned = {value = "abc123==", httpOnly = true, secure = false, sameSite = "Lax", path = "/"};
				expect(_controller.$csrfCookieScopeValue(assigned)).toBe("abc123==");
			});

			it("reads a struct without a value, or a value that isn't a string, as no cookie", () => {
				expect(_controller.$csrfCookieScopeValue({httpOnly = true})).toBe("");
				expect(_controller.$csrfCookieScopeValue({value = {nested = true}})).toBe("");
				expect(_controller.$csrfCookieScopeValue(["abc"])).toBe("");
			});

		});

	}

}
