/**
 * Tests that CSRF cookie encryption key is enforced in production
 * and auto-generated with a warning in non-production environments.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CSRF cookie encryption key", function() {

			beforeEach(function() {
				$originalKey = application.wheels.csrfCookieEncryptionSecretKey;
				$originalStore = application.wheels.csrfStore;
				$originalEnv = application.wheels.environment;
			});

			afterEach(function() {
				application.wheels.csrfCookieEncryptionSecretKey = $originalKey;
				application.wheels.csrfStore = $originalStore;
				application.wheels.environment = $originalEnv;
			});

			it("throws in production when key is empty", function() {
				application.wheels.csrfCookieEncryptionSecretKey = "";
				application.wheels.csrfStore = "cookie";
				application.wheels.environment = "production";

				var _controller = application.wo.controller("dummy");
				expect(function() {
					_controller.$ensureCsrfCookieEncryptionKey();
				}).toThrow("Wheels.Security.MissingCsrfKey");
			});

			it("auto-generates a key in development when key is empty", function() {
				application.wheels.csrfCookieEncryptionSecretKey = "";
				application.wheels.csrfStore = "cookie";
				application.wheels.environment = "development";

				var _controller = application.wo.controller("dummy");
				var result = _controller.$ensureCsrfCookieEncryptionKey();

				expect(Len(result)).toBeGT(0);
				expect(Len(application.wheels.csrfCookieEncryptionSecretKey)).toBeGT(0);
			});

			it("auto-generates a key in testing when key is empty", function() {
				application.wheels.csrfCookieEncryptionSecretKey = "";
				application.wheels.csrfStore = "cookie";
				application.wheels.environment = "testing";

				var _controller = application.wo.controller("dummy");
				var result = _controller.$ensureCsrfCookieEncryptionKey();

				expect(Len(result)).toBeGT(0);
			});

			it("generates a valid AES key that works for encryption", function() {
				application.wheels.csrfCookieEncryptionSecretKey = "";
				application.wheels.csrfStore = "cookie";
				application.wheels.environment = "development";

				var _controller = application.wo.controller("dummy");
				var result = _controller.$ensureCsrfCookieEncryptionKey();

				expect(Len(result)).toBeGT(0);

				// Verify the key actually works for encryption/decryption.
				var plaintext = "test-csrf-token";
				var encrypted = Encrypt(plaintext, result, "AES", "Base64");
				var decrypted = Decrypt(encrypted, result, "AES", "Base64");
				expect(decrypted).toBe(plaintext);
			});

			it("preserves an explicitly set key regardless of environment", function() {
				var explicitKey = GenerateSecretKey("AES");
				application.wheels.csrfCookieEncryptionSecretKey = explicitKey;
				application.wheels.csrfStore = "cookie";
				application.wheels.environment = "production";

				var _controller = application.wo.controller("dummy");
				var result = _controller.$ensureCsrfCookieEncryptionKey();

				expect(result).toBe(explicitKey);
				expect(application.wheels.csrfCookieEncryptionSecretKey).toBe(explicitKey);
			});

			it("only generates the key once across multiple calls", function() {
				application.wheels.csrfCookieEncryptionSecretKey = "";
				application.wheels.csrfStore = "cookie";
				application.wheels.environment = "development";

				var _controller = application.wo.controller("dummy");
				var firstResult = _controller.$ensureCsrfCookieEncryptionKey();
				var secondResult = _controller.$ensureCsrfCookieEncryptionKey();

				expect(firstResult).toBe(secondResult);
			});

		});

	}

}
