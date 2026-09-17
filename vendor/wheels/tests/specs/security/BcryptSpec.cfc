/**
 * Tests the bcrypt password helpers — bcryptHash, bcryptVerify,
 * and bcryptNeedsRehash — for OpenBSD / htpasswd / jBCrypt compatibility.
 *
 * On JVM engines (Lucee/Adobe/BoxLang) bcryptHash/bcryptVerify prefer the
 * bundled jBCrypt jar (org.mindrot.jbcrypt.BCrypt, MIT) via
 * $getJBCrypt() — native Java, ~100ms at cost 10. When the jar is not on the
 * classpath they fall back to the pure-CFML Blowfish implementation in
 * global/security.cfm (slow at cost 10, which is exactly what the fast path
 * avoids). RustCFML ships bcryptHash/bcryptVerify as NATIVE builtins
 * (Global.cfc skips security.cfm there to avoid the name collision), so specs
 * that pin CFML specifics — the $2b$ prefix and the Wheels.InvalidArgument
 * cost validation — are skipped on that engine. bcryptNeedsRehash has no
 * engine builtin and ships everywhere via security-extra.cfm.
 *
 * jBCrypt 0.4 emits the $2a$ prefix while the pure-CFML fallback emits $2b$;
 * both are valid bcrypt and verify identically for ASCII input, so prefix
 * assertions accept either. The reference vectors are cost 4: cost only sets
 * the EksBlowfish iteration count (2^cost), so a cost-4 Apache htpasswd vector
 * proves OpenBSD/jBCrypt compatibility as strongly as a cost-10 one while
 * running ~64x faster (#3478).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("bcrypt password helpers", function() {

			beforeEach(function() {
				g = application.wo;
				// True when the pure-CFML security.cfm include was skipped
				// (native bcryptHash/bcryptVerify builtins are in use).
				_nativeBuiltin = !StructKeyExists(g, "$bcryptHashCore");
				_needsRehashAvailable = StructKeyExists(g, "bcryptNeedsRehash");
			});

			it("verifies a known external $2b$ vector at cost 4", function() {
				// Checksum produced by Apache htpasswd (-B -C 4) for "password";
				// $2b$ and $2y$ share one checksum for ASCII input.
				var vector = "$2b$04$CHLQLI9srqpRn1u2xmb0y.AxWynQnwFQuBZ1PRGMsiTbMm/yojzLq";
				expect(bcryptVerify("password", vector)).toBeTrue();
			});

			it("rejects a wrong password for the known vector", function() {
				var vector = "$2b$04$CHLQLI9srqpRn1u2xmb0y.AxWynQnwFQuBZ1PRGMsiTbMm/yojzLq";
				expect(bcryptVerify("wrong-password", vector)).toBeFalse();
			});

			it("rejects a tampered checksum for the known vector", function() {
				var vector = "$2b$04$CHLQLI9srqpRn1u2xmb0y.AxWynQnwFQuBZ1PRGMsiTbMm/yojzLq";
				var tampered = Replace(vector, "yojzLq", "yojzLp", "all");
				expect(bcryptVerify("password", tampered)).toBeFalse();
			});

			it("verifies a $2a$ reference vector at cost 4", function() {
				// Apache htpasswd (-B -C 4) checksum for "abc"; $2a$ shares the
				// checksum with $2b$/$2y$ for ASCII input.
				var vector = "$2a$04$Ug8H2OLfZyHBFJgGLjAby.CQYnorLi9T8QxhGDv8GAGT5DpIcmSje";
				expect(bcryptVerify("abc", vector)).toBeTrue();
			});

			it("round-trips a cost-4 hash", function() {
				var hash = bcryptHash("abc", 4);
				expect(Len(hash)).toBe(60);
				if (!_nativeBuiltin) {
					// RustCFML's native bcrypt crate and the bundled jBCrypt both
					// emit the $2a$ prefix; the pure-CFML fallback emits $2b$.
					expect(ListFindNoCase("$2a$,$2b$", Left(hash, 4)) > 0).toBeTrue();
					expect(Mid(hash, 5, 2)).toBe("04");
				}
				expect(bcryptVerify("abc", hash)).toBeTrue();
				expect(bcryptVerify("not-abc", hash)).toBeFalse();
			});

			it("formats the hash as <version>$ + 2-digit cost + 22-char salt + 31-char checksum", function() {
				var hash = bcryptHash("abc", 4);
				expect(Len(hash)).toBe(60);
				if (!_nativeBuiltin) {
					expect(ListFindNoCase("$2a$,$2b$", Left(hash, 4)) > 0).toBeTrue();
				}
				expect(Mid(hash, 5, 2)).toBe("04");
				expect(Mid(hash, 7, 1)).toBe("$");
				expect(Len(Mid(hash, 8, 22))).toBe(22);
				expect(Len(Mid(hash, 30, 31))).toBe(31);
			});

			it("completes a default-cost (10) hash quickly on the native/jBCrypt path", function() {
				// The pure-CFML Blowfish at cost 10 takes minutes — that is the
				// hang this fast path exists to eliminate. Only assert timing when
				// a native implementation (RustCFML builtin, or the bundled jBCrypt
				// on a JVM engine) is actually in use; otherwise skip so the suite
				// never grinds through pure-CFML cost 10.
				var fastPath = _nativeBuiltin || IsObject(g.$getJBCrypt());
				if (!fastPath) {
					return;
				}
				var started = GetTickCount();
				var hash = bcryptHash("performance-probe", 10);
				var elapsed = GetTickCount() - started;
				expect(bcryptVerify("performance-probe", hash)).toBeTrue();
				// Native bcrypt at cost 10 is on the order of 100ms; anything over
				// 5s means the slow pure-CFML path was (wrongly) taken.
				expect(elapsed).toBeLTE(5000);
			});

			it("throws for an out-of-range cost", function() {
				if (_nativeBuiltin) return;
				expect(function() {
					bcryptHash("abc", 3);
				}).toThrow("Wheels.InvalidArgument");
				expect(function() {
					bcryptHash("abc", 32);
				}).toThrow("Wheels.InvalidArgument");
			});

			it("accepts boundary costs without throwing", function() {
				expect(Len(bcryptHash("abc", 4))).toBe(60);
				if (!_nativeBuiltin) {
					expect(function() {
						$bcryptValidateCost(4);
					}).notToThrow();
					expect(function() {
						$bcryptValidateCost(31);
					}).notToThrow();
				}
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
				if (!_needsRehashAvailable) return;
				var hash = bcryptHash("abc", 4);
				expect(g.bcryptNeedsRehash(hash, 4)).toBeFalse();
				expect(g.bcryptNeedsRehash(hash, 10)).toBeTrue();
				expect(g.bcryptNeedsRehash("malformed", 10)).toBeTrue();
			});

			it("uses a fresh salt per call", function() {
				var first = bcryptHash("abc", 4);
				var second = bcryptHash("abc", 4);
				expect(first).notToBe(second);
			});

		});

	}

}
