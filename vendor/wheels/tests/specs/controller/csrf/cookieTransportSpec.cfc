/**
 * The cookie-store CSRF cookie carries its ciphertext in the base64url alphabet. On some
 * engines a cookie value whose only encoded character is %2B reads back with the "+"
 * turned into a space (seen on Lucee 7.0.1 behind Tomcat), which made a standard-base64
 * ciphertext without "/" or "=" undecryptable and the next POST a 403 (about 3% of new
 * cookies). base64url has no "+" or "/", so nothing in the value needs encoding.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CSRF cookie transport encoding", () => {

			beforeEach(() => {
				_controller = application.wo.controller("CsrfProtectedWithException", {});
			});

			it("writes base64 ciphertext with - and _ and no padding", () => {
				expect(_controller.$csrfCookieTransportValue("ab+cd/e=")).toBe("ab-cd_e");
				expect(_controller.$csrfCookieTransportValue("abcdefgh")).toBe("abcdefgh");
			});

			it("reads base64url, standard base64 and a value whose + became a space", () => {
				expect(_controller.$csrfCookieCipherText("ab-cd_e")).toBe("ab+cd/e=");
				expect(_controller.$csrfCookieCipherText("ab+cd/e=")).toBe("ab+cd/e=");
				expect(_controller.$csrfCookieCipherText("ab cd/e=")).toBe("ab+cd/e=");
			});

			it("issues a cookie whose value has no + or / for an engine to mangle", () => {
				var saved = application.wheels.csrfStore;
				application.wheels.csrfStore = "cookie";
				try {
					var tc = $testClient();
					tc.get("/_csrfclient/meta").assertOk();
					var value = tc.$cookieJar()[application.wheels.csrfCookieName];
					tc.post("/_csrfclient/save").assertOk();
				} finally {
					application.wheels.csrfStore = saved;
				}
				// Decoded first: Adobe percent-encodes "-" and "_" too, and decodes them back.
				expect(ReFind("^[A-Za-z0-9_-]+$", URLDecode(value))).toBe(1, "cookie value: " & value);
			});

		});

	}

}
