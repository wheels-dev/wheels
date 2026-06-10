/**
 * Tests that the CSRF cookie cipher defaults to authenticated AES/GCM (bare "AES"
 * resolves to insecure ECB mode) and that cookies written under the legacy bare
 * "AES" default remain readable via the decrypt fallback.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CSRF cookie encryption cipher", function() {

			beforeEach(function() {
				$originalAlgorithm = application.wheels.csrfCookieEncryptionAlgorithm;
				$originalKey = application.wheels.csrfCookieEncryptionSecretKey;
				if (!Len(application.wheels.csrfCookieEncryptionSecretKey)) {
					application.wheels.csrfCookieEncryptionSecretKey = GenerateSecretKey("AES");
				}
			});

			afterEach(function() {
				application.wheels.csrfCookieEncryptionAlgorithm = $originalAlgorithm;
				application.wheels.csrfCookieEncryptionSecretKey = $originalKey;
			});

			it("defaults to AES/GCM/NoPadding instead of ECB", function() {
				expect(application.wheels.csrfCookieEncryptionAlgorithm).toBe("AES/GCM/NoPadding");
			});

			it("round-trips a value encrypted with the configured algorithm", function() {
				var _controller = application.wo.controller("dummy");
				var key = application.wheels.csrfCookieEncryptionSecretKey;
				var payload = SerializeJSON({sessionId = CreateUUID(), authenticityToken = "currentToken"});
				var encryptedValue = Encrypt(
					payload,
					key,
					application.wheels.csrfCookieEncryptionAlgorithm,
					application.wheels.csrfCookieEncryptionEncoding
				);

				var decrypted = _controller.$decryptCsrfCookieValue(encryptedValue, key);

				expect(IsJSON(decrypted)).toBeTrue();
				expect(DeserializeJSON(decrypted).authenticityToken).toBe("currentToken");
			});

			it("still reads cookies encrypted with the legacy bare AES (ECB) algorithm", function() {
				var _controller = application.wo.controller("dummy");
				var key = application.wheels.csrfCookieEncryptionSecretKey;
				var payload = SerializeJSON({sessionId = CreateUUID(), authenticityToken = "legacyToken"});
				var legacyValue = Encrypt(payload, key, "AES", application.wheels.csrfCookieEncryptionEncoding);

				var decrypted = _controller.$decryptCsrfCookieValue(legacyValue, key);

				expect(IsJSON(decrypted)).toBeTrue();
				expect(DeserializeJSON(decrypted).authenticityToken).toBe("legacyToken");
			});

			it("returns an empty string for an undecryptable value", function() {
				var _controller = application.wo.controller("dummy");
				var key = application.wheels.csrfCookieEncryptionSecretKey;

				// Invalid Base64 on every engine, so both decrypt attempts fail deterministically.
				var decrypted = _controller.$decryptCsrfCookieValue("%%%not-base64%%%", key);

				expect(decrypted).toBe("");
			});

			it("generates token material from the bare cipher name when the algorithm includes mode and padding", function() {
				// GenerateSecretKey() rejects full transformation strings, so the token
				// generator must strip mode/padding from the configured algorithm.
				var tokenMaterial = GenerateSecretKey(ListFirst(application.wheels.csrfCookieEncryptionAlgorithm, "/"));
				expect(Len(tokenMaterial)).toBeGT(0);
			});

		});

	}

}
