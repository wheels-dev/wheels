/**
 * Tests that the flash cookie is written through an attribute collection carrying
 * httpOnly / secure / sameSite flags (mirroring the CSRF cookie) instead of a bare
 * value-only assignment.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Flash cookie attribute collection", function() {

			beforeEach(function() {
				$originalHttpOnly = application.wheels.flashCookieHttpOnly;
				$originalSecure = application.wheels.flashCookieSecure;
				$originalSameSite = application.wheels.flashCookieSameSite;
			});

			afterEach(function() {
				application.wheels.flashCookieHttpOnly = $originalHttpOnly;
				application.wheels.flashCookieSecure = $originalSecure;
				application.wheels.flashCookieSameSite = $originalSameSite;
			});

			it("defaults to httpOnly, secure and SameSite=Lax", function() {
				expect(application.wheels.flashCookieHttpOnly).toBeTrue();
				expect(application.wheels.flashCookieSecure).toBeTrue();
				expect(application.wheels.flashCookieSameSite).toBe("Lax");
			});

			it("builds the cookie attribute collection from the settings", function() {
				var attrs = application.wo.controller("dummy").$flashCookieAttributeCollection("flashValue");
				expect(attrs.value).toBe("flashValue");
				expect(attrs.httpOnly).toBeTrue();
				expect(attrs.secure).toBeTrue();
				expect(attrs.sameSite).toBe("Lax");
			});

			it("omits sameSite when the setting is empty", function() {
				application.wheels.flashCookieSameSite = "";
				var attrs = application.wo.controller("dummy").$flashCookieAttributeCollection("flashValue");
				expect(StructKeyExists(attrs, "sameSite")).toBeFalse();
			});

			it("respects overridden settings (plain-HTTP development opt-out)", function() {
				application.wheels.flashCookieHttpOnly = false;
				application.wheels.flashCookieSecure = false;
				application.wheels.flashCookieSameSite = "Strict";
				var attrs = application.wo.controller("dummy").$flashCookieAttributeCollection("flashValue");
				expect(attrs.httpOnly).toBeFalse();
				expect(attrs.secure).toBeFalse();
				expect(attrs.sameSite).toBe("Strict");
			});

		});

	}

}
