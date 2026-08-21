/**
 * Tests that the CSRF cookie cipher defaults to an IV-based AES mode (bare "AES"
 * resolves to insecure ECB mode) — authenticated AES/GCM where the engine supports
 * it through Encrypt()/Decrypt(), random-IV CBC otherwise (e.g. Lucee) — and that
 * cookies written under the legacy bare "AES" default remain readable via the
 * decrypt fallback.
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

			it("defaults to an IV-based AES mode instead of bare AES (ECB)", function() {
				// AES/GCM/NoPadding where the engine supports it through Encrypt()/Decrypt(),
				// AES/CBC/PKCS5Padding otherwise (e.g. Lucee rejects GCM with
				// "AlgorithmParameterSpec not of GCMParameterSpec").
				expect(
					ListFind("AES/GCM/NoPadding,AES/CBC/PKCS5Padding", application.wheels.csrfCookieEncryptionAlgorithm)
				).toBeGT(0);
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

			// Issue #3361. The legacy fallback used to live only in the catch block, so it
			// ran only when the configured algorithm THREW. Decrypting an ECB ciphertext
			// under AES/CBC/PKCS5Padding throws only when the trailing bytes fail padding
			// validation — they pass by chance about 1 time in 256, and then Decrypt()
			// returns garbage, the fallback is skipped, and a good legacy cookie reads as
			// corrupted.
			//
			// The spec above exercises the same path but cannot reproduce this on demand:
			// its payload carries a CreateUUID(), so whether the coin lands is random per
			// run (measured: 1 failure in 326 compat-matrix legs). These two pin the
			// behaviour deterministically instead.
			it("prefers a legacy-readable result over garbage the configured algorithm returned (issue ##3361)", function() {
				var _controller = application.wo.controller("dummy");
				var key = application.wheels.csrfCookieEncryptionSecretKey;
				var payload = SerializeJSON({sessionId = "fixed-session", authenticityToken = "legacyToken"});
				var legacyValue = Encrypt(payload, key, "AES", application.wheels.csrfCookieEncryptionEncoding);

				// The real trigger is AES/CBC/PKCS5Padding decrypting an ECB ciphertext whose
				// trailing bytes happen to form valid padding — about 1 run in 256, so it
				// cannot be reproduced on demand. AES/CBC/NoPadding reaches the SAME state
				// every time: no padding to validate, so Decrypt() never throws and simply
				// returns garbage. Probed on this engine to confirm the three behaviours:
				//   AES/CBC/PKCS5Padding -> THREW ("Given final block not properly padded")
				//   AES/CBC/NoPadding    -> RETURNED, not JSON      <- what we force here
				//   AES/ECB/NoPadding    -> RETURNED, valid JSON    (same mode, decrypts fine)
				application.wheels.csrfCookieEncryptionAlgorithm = "AES/CBC/NoPadding";

				var decrypted = _controller.$decryptCsrfCookieValue(legacyValue, key);

				// The property is "the legacy value wins", not "the first attempt threw".
				expect(IsJSON(decrypted)).toBeTrue();
				expect(DeserializeJSON(decrypted).authenticityToken).toBe("legacyToken");
			});

			it("treats a non-JSON decrypt as not-the-payload (issue ##3361)", function() {
				var _controller = application.wo.controller("dummy");

				// the predicate the fix turns on: garbage that did not throw is still garbage
				expect(_controller.$isCsrfCookiePayload("")).toBeFalse();
				expect(_controller.$isCsrfCookiePayload("Ë}Ö¬not json")).toBeFalse();
				expect(_controller.$isCsrfCookiePayload('{"authenticityToken":"x"}')).toBeTrue();
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
