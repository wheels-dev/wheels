/**
 * Tests for security-related default settings.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CSRF cookie security defaults", function() {

			it("defaults csrfCookieHttpOnly to true", function() {
				expect(application.wheels.csrfCookieHttpOnly).toBeTrue();
			});

			it("defaults csrfCookieSecure to true", function() {
				expect(application.wheels.csrfCookieSecure).toBeTrue();
			});

		});

	}

}
