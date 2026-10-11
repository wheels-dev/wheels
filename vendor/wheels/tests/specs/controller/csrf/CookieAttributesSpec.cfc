/**
 * The cookie-store CSRF cookie's attributes. encodeValue and preserveCase
 * default to "" (the engine's own default) and are left out unless configured:
 * Adobe CF rejects "" for these boolean attributes, so setting them made the
 * first cookie-store token an HTTP 500 there. TestClientCsrfSpec's cookie-store
 * HTTP spec covers the round trip on every engine.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CSRF cookie attributes", () => {

			beforeEach(() => {
				_saved = {
					encodeValue = application.wheels.csrfCookieEncodeValue,
					preserveCase = application.wheels.csrfCookiePreserveCase
				};
				_controller = application.wo.controller("CsrfProtectedWithException", {});
			});

			afterEach(() => {
				application.wheels.csrfCookieEncodeValue = _saved.encodeValue;
				application.wheels.csrfCookiePreserveCase = _saved.preserveCase;
			});

			it("leaves out encodeValue and preserveCase when they aren't configured", () => {
				application.wheels.csrfCookieEncodeValue = "";
				application.wheels.csrfCookiePreserveCase = "";
				var attributes = _controller.$csrfCookieAttributeCollection("v");
				expect(StructKeyExists(attributes, "encodeValue")).toBeFalse();
				expect(StructKeyExists(attributes, "preserveCase")).toBeFalse();
				expect(attributes.value).toBe("v");
				expect(StructKeyExists(attributes, "httpOnly")).toBeTrue();
				expect(StructKeyExists(attributes, "secure")).toBeTrue();
			});

			it("can be written to the cookie scope with the defaults (Adobe rejected them)", () => {
				application.wheels.csrfCookieEncodeValue = "";
				application.wheels.csrfCookiePreserveCase = "";
				var state = {error = ""};
				try {
					cookie["_wheels_csrf_attribute_probe"] = _controller.$csrfCookieAttributeCollection("probe");
				} catch (any e) {
					state.error = e.message;
				}
				expect(state.error).toBe("");
			});

			it("passes them through when they are configured", () => {
				application.wheels.csrfCookieEncodeValue = false;
				application.wheels.csrfCookiePreserveCase = true;
				var attributes = _controller.$csrfCookieAttributeCollection("v");
				expect(attributes.encodeValue).toBeFalse();
				expect(attributes.preserveCase).toBeTrue();
			});

		});

	}

}
