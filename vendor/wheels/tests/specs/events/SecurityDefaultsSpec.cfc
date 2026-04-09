/**
 * Tests for security-related default settings.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CSRF cookie security defaults", function() {

			it("defaults csrfCookieHttpOnly to true", function() {
				expect(application.wheels.csrfCookieHttpOnly).toBe(true);
			});

			it("defaults csrfCookieSecure to true", function() {
				expect(application.wheels.csrfCookieSecure).toBe(true);
			});

			it("defaults csrfCookieSameSite to Lax", function() {
				expect(application.wheels.csrfCookieSameSite).toBe("Lax");
			});

		});

		describe("CSRF cookie attribute collection", function() {

			it("includes sameSite attribute when csrfCookieSameSite is set", function() {
				var _controller = application.wo.controller("dummy");
				var attrs = _controller.$csrfCookieAttributeCollection("testvalue");
				expect(StructKeyExists(attrs, "sameSite")).toBeTrue();
				expect(attrs.sameSite).toBe("Lax");
			});

			it("omits sameSite attribute when csrfCookieSameSite is empty", function() {
				var originalValue = application.wheels.csrfCookieSameSite;
				application.wheels.csrfCookieSameSite = "";
				try {
					var _controller = application.wo.controller("dummy");
					var attrs = _controller.$csrfCookieAttributeCollection("testvalue");
					expect(StructKeyExists(attrs, "sameSite")).toBeFalse();
				} finally {
					application.wheels.csrfCookieSameSite = originalValue;
				}
			});

		});

	}

}
