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
				expect(_controller.$csrfCookieTransportValue("ab+cd/ef==")).toBe("ab-cd_ef");
				expect(_controller.$csrfCookieTransportValue("abcdefgh")).toBe("abcdefgh");
			});

			it("reads base64url, standard base64 and a value whose + became a space", () => {
				expect(_controller.$csrfCookieCipherText("ab-cd_ef")).toBe("ab+cd/ef==");
				expect(_controller.$csrfCookieCipherText("ab+cd/ef==")).toBe("ab+cd/ef==");
				expect(_controller.$csrfCookieCipherText("ab cd/ef==")).toBe("ab+cd/ef==");
			});

			it("issues a cookie that needs no encoding over HTTP", () => {
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
				expect(ReFind("^[A-Za-z0-9_-]+$", value)).toBe(1, "cookie value: " & value);
			});

		});

	}

}
