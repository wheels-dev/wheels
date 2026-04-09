/**
 * Tests that CSRF cookie encryption key is auto-generated when empty.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CSRF cookie encryption key auto-generation", function() {

			beforeEach(function() {
				$originalKey = application.wheels.csrfCookieEncryptionSecretKey;
				$originalStore = application.wheels.csrfStore;
			});

			afterEach(function() {
				application.wheels.csrfCookieEncryptionSecretKey = $originalKey;
				application.wheels.csrfStore = $originalStore;
			});

			it("auto-generates a key when csrfStore is cookie and key is empty", function() {
				application.wheels.csrfCookieEncryptionSecretKey = "";
				application.wheels.csrfStore = "cookie";

				var _controller = application.wo.controller("dummy");
				var result = _controller.$ensureCsrfCookieEncryptionKey();

				expect(Len(result)).toBeGT(0);
				expect(Len(application.wheels.csrfCookieEncryptionSecretKey)).toBeGT(0);
			});

			it("generates a valid AES key that works for encryption", function() {
				application.wheels.csrfCookieEncryptionSecretKey = "";
				application.wheels.csrfStore = "cookie";

				var _controller = application.wo.controller("dummy");
				var result = _controller.$ensureCsrfCookieEncryptionKey();

				// Key must be non-empty (length varies by engine: 128-bit=24 chars, 256-bit=44 chars).
				expect(Len(result)).toBeGT(0);

				// Verify the key actually works for encryption/decryption.
				var plaintext = "test-csrf-token";
				var encrypted = Encrypt(plaintext, result, "AES", "Base64");
				var decrypted = Decrypt(encrypted, result, "AES", "Base64");
				expect(decrypted).toBe(plaintext);
			});

			it("preserves an explicitly set key", function() {
				var explicitKey = GenerateSecretKey("AES");
				application.wheels.csrfCookieEncryptionSecretKey = explicitKey;
				application.wheels.csrfStore = "cookie";

				var _controller = application.wo.controller("dummy");
				var result = _controller.$ensureCsrfCookieEncryptionKey();

				expect(result).toBe(explicitKey);
				expect(application.wheels.csrfCookieEncryptionSecretKey).toBe(explicitKey);
			});

			it("only generates the key once across multiple calls", function() {
				application.wheels.csrfCookieEncryptionSecretKey = "";
				application.wheels.csrfStore = "cookie";

				var _controller = application.wo.controller("dummy");
				var firstResult = _controller.$ensureCsrfCookieEncryptionKey();
				var secondResult = _controller.$ensureCsrfCookieEncryptionKey();

				expect(firstResult).toBe(secondResult);
			});

		});

	}

}
