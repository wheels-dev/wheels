/**
 * Tests the pure-CFML bcrypt password helpers — bcryptHash, bcryptVerify,
 * and bcryptNeedsRehash — for OpenBSD / htpasswd / jBCrypt compatibility.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("bcrypt password helpers", function() {

			it("verifies a known external $2b$ vector", function() {
				// Checksum independently produced by OpenBSD's htpasswd (Apache)
				// for "password"; $2b$ and $2y$ share one checksum for ASCII input.
				var vector = "$2b$10$cChtdYuXHh8.R4SfJfmfPO7cP7waTgEn6ygtxos.KTNU/rMVTVAKS";
				expect(bcryptVerify("password", vector)).toBeTrue();
			});

			it("rejects a wrong password for the known vector", function() {
				var vector = "$2b$10$cChtdYuXHh8.R4SfJfmfPO7cP7waTgEn6ygtxos.KTNU/rMVTVAKS";
				expect(bcryptVerify("wrong-password", vector)).toBeFalse();
			});

			it("rejects a tampered checksum for the known vector", function() {
				var vector = "$2b$10$cChtdYuXHh8.R4SfJfmfPO7cP7waTgEn6ygtxos.KTNU/rMVTVAKS";
				var tampered = Replace(vector, "7cP7", "6cP7", "all");
				expect(bcryptVerify("password", tampered)).toBeFalse();
			});

			it("verifies a $2a$ jBCrypt reference vector", function() {
				// Official jBCrypt test vector for "abc" at cost 8.
				var vector = "$2a$08$Ro0CUfOqk6cXEKf3dyaM7OhSCvnwM9s4wIX9JeLapehKK5YdLxKcm";
				expect(bcryptVerify("abc", vector)).toBeTrue();
			});

			it("round-trips a cost-4 hash", function() {
				var hash = bcryptHash("abc", 4);
				expect(Len(hash)).toBe(60);
				expect(Left(hash, 7)).toBe("$2b$04$");
				expect(bcryptVerify("abc", hash)).toBeTrue();
				expect(bcryptVerify("not-abc", hash)).toBeFalse();
			});

			it("formats the hash as $2b$ + 2-digit cost + 22-char salt + 31-char checksum", function() {
				var hash = bcryptHash("abc", 4);
				expect(Len(hash)).toBe(60);
				expect(Left(hash, 4)).toBe("$2b$");
				expect(Mid(hash, 5, 2)).toBe("04");
				expect(Mid(hash, 7, 1)).toBe("$");
				expect(Len(Mid(hash, 8, 22))).toBe(22);
				expect(Len(Mid(hash, 30, 31))).toBe(31);
			});

			it("throws for an out-of-range cost", function() {
				expect(function() {
					bcryptHash("abc", 3);
				}).toThrow("Wheels.InvalidArgument");
				expect(function() {
					bcryptHash("abc", 32);
				}).toThrow("Wheels.InvalidArgument");
			});

			it("accepts boundary costs without throwing", function() {
				expect(Len(bcryptHash("abc", 4))).toBe(60);
				expect(function() {
					$bcryptValidateCost(4);
				}).notToThrow();
				expect(function() {
					$bcryptValidateCost(31);
				}).notToThrow();
			});

			it("never throws on malformed or foreign-format hashes", function() {
				var malformed = [
					"",
					"x",
					"$2b$10$short",
					"$2b$10$cChtdYuXHh8.R4SfJfmfPO7cP7waTgEn6ygtxos.KTNU/rMVTVAK",
					"$2b$10$cChtdYuXHh8.R4SfJfmfPO7cP7waTgEn6ygtxos.KTNU/rMVTVAKSX",
					"$1$md5style",
					"$2a$10$short"
				];
				for (var bad in malformed) {
					expect(bcryptVerify("password", bad)).toBeFalse();
				}
			});

			it("round-trips a unicode password", function() {
				var hash = bcryptHash("pässwörd", 4);
				expect(bcryptVerify("pässwörd", hash)).toBeTrue();
				expect(bcryptVerify("pässwörd!", hash)).toBeFalse();
			});

			it("reports whether a hash needs rehashing", function() {
				var hash = bcryptHash("abc", 4);
				expect(bcryptNeedsRehash(hash, 4)).toBeFalse();
				expect(bcryptNeedsRehash(hash, 10)).toBeTrue();
				expect(bcryptNeedsRehash("malformed", 10)).toBeTrue();
			});

			it("uses a fresh salt per call", function() {
				var first = bcryptHash("abc", 4);
				var second = bcryptHash("abc", 4);
				expect(first).notToBe(second);
			});

		});

	}

}
