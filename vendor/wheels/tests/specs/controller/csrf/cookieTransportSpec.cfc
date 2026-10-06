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

		describe("CSRF cookies issued before base64url", () => {

			beforeEach(() => {
				_controller = application.wo.controller("CsrfProtectedWithException", {});
				_key = _controller.$ensureCsrfCookieEncryptionKey();
				_alg = application.wheels.csrfCookieEncryptionAlgorithm;
				// A standard-base64 cookie as written before: one whose ciphertext has both
				// "+" and "/", the characters base64url replaces.
				_token = "";
				_old = "";
				for (var i = 1; i <= 500; i++) {
					var candidateToken = GenerateSecretKey(ListFirst(_alg, "/"));
					var candidate = Encrypt(SerializeJSON({sessionId = CreateUUID(), authenticityToken = candidateToken}), _key, _alg, "Base64");
					if (Find("+", candidate) && Find("/", candidate)) {
						_token = candidateToken;
						_old = candidate;
						break;
					}
				}
			});

			it("still validates a form post against an old standard-base64 cookie", () => {
				expect(Len(_old)).toBeGT(0, "no ciphertext with both + and / in 500 tries");
				var saved = application.wheels.csrfStore;
				application.wheels.csrfStore = "cookie";
				try {
					// The server sets the old cookie, so each engine encodes it as it did then.
					var tc = $testClient();
					tc.get("/_csrfclient/setoldcookie?v=" & EncodeForURL(_old)).assertOk();
					tc.post("/_csrfclient/save", {authenticityToken = _token}).assertOk().assertSee("saved:POST");
					var wrong = $testClient();
					wrong.get("/_csrfclient/setoldcookie?v=" & EncodeForURL(_old)).assertOk();
					wrong.post("/_csrfclient/save", {authenticityToken = "not-" & _token}).assertStatus(403);
				} finally {
					application.wheels.csrfStore = saved;
				}
			});

			it("decrypts an old cookie whose + an engine turned into a space", () => {
				var payload = DeserializeJSON(_controller.$decryptCsrfCookieValue(Replace(_old, "+", " ", "all"), _key));
				expect(payload.authenticityToken).toBe(_token);
			});

			it("leaves a non-Base64 cookie encoding alone", () => {
				var savedEncoding = application.wheels.csrfCookieEncryptionEncoding;
				application.wheels.csrfCookieEncryptionEncoding = "Hex";
				try {
					var hex = Encrypt(SerializeJSON({sessionId = CreateUUID(), authenticityToken = _token}), _key, _alg, "Hex");
					expect(_controller.$csrfCookieTransportValue(hex)).toBe(hex);
					expect(_controller.$csrfCookieCipherText(hex)).toBe(hex);
					var payload = DeserializeJSON(_controller.$decryptCsrfCookieValue(hex, _key));
					expect(payload.authenticityToken).toBe(_token);
				} finally {
					application.wheels.csrfCookieEncryptionEncoding = savedEncoding;
				}
			});

		});

	}

}
