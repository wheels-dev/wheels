component extends="wheels.WheelsTest" {

	function run() {

		describe("PasswordHasher", function() {

			beforeEach(function() {
				// Low iteration count keeps the suite fast; the algorithm is the
				// same regardless of count. Default-count behavior is asserted
				// in its own spec below.
				hasher = new wheels.auth.PasswordHasher(iterations = 1000);
			});

			describe("init() validation", function() {

				it("throws InvalidConfiguration for zero iterations", function() {
					expect(function() {
						var svc = new wheels.auth.PasswordHasher(iterations = 0);
					}).toThrow("Wheels.PasswordHasher.InvalidConfiguration");
				});

				it("throws InvalidConfiguration for negative iterations", function() {
					expect(function() {
						var svc = new wheels.auth.PasswordHasher(iterations = -1);
					}).toThrow("Wheels.PasswordHasher.InvalidConfiguration");
				});

				it("throws InvalidConfiguration for non-integer iterations", function() {
					expect(function() {
						var svc = new wheels.auth.PasswordHasher(iterations = 1000.5);
					}).toThrow("Wheels.PasswordHasher.InvalidConfiguration");
				});

				it("defaults to 600000 iterations (OWASP 2023+)", function() {
					var svc = new wheels.auth.PasswordHasher();
					var h = svc.hash("secret");
					expect(ListGetAt(h, 2, "$")).toBe("i=600000");
				});

			});

			describe("hash()", function() {

				it("produces the self-describing modular-crypt format", function() {
					var h = hasher.hash("correct horse battery staple");
					// $pbkdf2-sha256$i=<iterations>$<base64(salt)>$<base64(derivedKey)>
					expect(Left(h, 1)).toBe("$");
					var parts = ListToArray(h, "$");
					expect(ArrayLen(parts)).toBe(4);
					expect(parts[1]).toBe("pbkdf2-sha256");
					expect(parts[2]).toBe("i=1000");
					// Salt decodes to 16 random bytes, derived key to 32 bytes (256 bits)
					expect(Len(BinaryDecode(parts[3], "base64"))).toBe(16);
					expect(Len(BinaryDecode(parts[4], "base64"))).toBe(32);
				});

				it("produces different hashes for the same password (random salt)", function() {
					var first = hasher.hash("same-password");
					var second = hasher.hash("same-password");
					expect(Compare(first, second)).notToBe(0);
					// And both still verify
					expect(hasher.verify("same-password", first)).toBeTrue();
					expect(hasher.verify("same-password", second)).toBeTrue();
				});

				it("hashes an empty password (minimum-length policy lives in app validations)", function() {
					var h = hasher.hash("");
					expect(hasher.verify("", h)).toBeTrue();
					expect(hasher.verify("not-empty", h)).toBeFalse();
				});

			});

			describe("verify()", function() {

				it("returns true for the correct password", function() {
					var h = hasher.hash("s3cret!");
					expect(hasher.verify("s3cret!", h)).toBeTrue();
				});

				it("returns false for the wrong password", function() {
					var h = hasher.hash("s3cret!");
					expect(hasher.verify("wrong-password", h)).toBeFalse();
				});

				it("is case-sensitive on the password", function() {
					var h = hasher.hash("Secret");
					expect(hasher.verify("secret", h)).toBeFalse();
				});

				it("round-trips unicode passwords via UTF-8 bytes", function() {
					var unicodePassword = "pässwörd-契約-κωδικός";
					var h = hasher.hash(unicodePassword);
					expect(hasher.verify(unicodePassword, h)).toBeTrue();
					expect(hasher.verify("passwoerd", h)).toBeFalse();
				});

				it("verifies hashes produced under a different iteration count (stored count wins)", function() {
					var older = new wheels.auth.PasswordHasher(iterations = 500);
					var h = older.hash("migrate-me");
					// A hasher configured with more iterations still verifies the stored hash
					expect(hasher.verify("migrate-me", h)).toBeTrue();
				});

				it("returns false (never throws) for an empty hash", function() {
					expect(hasher.verify("anything", "")).toBeFalse();
				});

				it("returns false (never throws) for a non-hash string", function() {
					expect(hasher.verify("anything", "not-a-hash-at-all")).toBeFalse();
				});

				it("returns false (never throws) for a truncated hash", function() {
					var h = hasher.hash("s3cret!");
					// Drop the derived-key segment entirely
					var truncated = "$" & ListGetAt(h, 1, "$") & "$" & ListGetAt(h, 2, "$") & "$" & ListGetAt(h, 3, "$");
					expect(hasher.verify("s3cret!", truncated)).toBeFalse();
				});

				it("returns false (never throws) for an unknown algorithm tag", function() {
					var h = hasher.hash("s3cret!");
					var foreign = Replace(h, "pbkdf2-sha256", "argon2id");
					expect(hasher.verify("s3cret!", foreign)).toBeFalse();
				});

				it("returns false (never throws) for invalid base64 in the hash", function() {
					expect(hasher.verify("anything", "$pbkdf2-sha256$i=1000$!!!not-base64!!!$%%%also-bad%%%")).toBeFalse();
				});

				it("returns false (never throws) for a zero-iterations hash", function() {
					var h = hasher.hash("s3cret!");
					var doctored = Replace(h, "i=1000", "i=0");
					expect(hasher.verify("s3cret!", doctored)).toBeFalse();
				});

				it("returns false when the format lacks the leading dollar sign", function() {
					var h = hasher.hash("s3cret!");
					var noPrefix = Right(h, Len(h) - 1);
					expect(hasher.verify("s3cret!", noPrefix)).toBeFalse();
				});

			});

			describe("needsRehash()", function() {

				it("returns false for a hash produced at the configured iteration count", function() {
					var h = hasher.hash("s3cret!");
					expect(hasher.needsRehash(h)).toBeFalse();
				});

				it("returns true when the stored iteration count is below the configured one", function() {
					var older = new wheels.auth.PasswordHasher(iterations = 500);
					var h = older.hash("migrate-me");
					expect(hasher.needsRehash(h)).toBeTrue();
				});

				it("returns false when the stored iteration count exceeds the configured one", function() {
					var stronger = new wheels.auth.PasswordHasher(iterations = 2000);
					var h = stronger.hash("already-strong");
					expect(hasher.needsRehash(h)).toBeFalse();
				});

				it("returns true for an unknown algorithm tag", function() {
					var h = hasher.hash("s3cret!");
					var foreign = Replace(h, "pbkdf2-sha256", "argon2id");
					expect(hasher.needsRehash(foreign)).toBeTrue();
				});

				it("returns true for a malformed hash", function() {
					expect(hasher.needsRehash("")).toBeTrue();
					expect(hasher.needsRehash("not-a-hash")).toBeTrue();
					expect(hasher.needsRehash("$pbkdf2-sha256$i=1000$only-three-parts")).toBeTrue();
				});

			});

		});

	}

}
