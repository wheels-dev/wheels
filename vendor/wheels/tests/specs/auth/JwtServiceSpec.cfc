component extends="wheels.WheelsTest" {

	function run() {

		describe("JwtService", function() {

			beforeEach(function() {
				jwt = new wheels.auth.JwtService(
					secretKey = "test-secret-key-for-jwt-specs",
					defaultExpiry = 3600
				);
			});

			describe("encode()", function() {

				it("produces a token with three dot-separated parts", function() {
					var token = jwt.encode(claims = {sub = 42});
					var parts = ListToArray(token, ".");
					expect(ArrayLen(parts)).toBe(3);
				});

				it("sets iat automatically", function() {
					var token = jwt.encode(claims = {sub = 1});
					var claims = jwt.decode(token);
					expect(StructKeyExists(claims, "iat")).toBeTrue();
					expect(claims.iat).toBeNumeric();
				});

				it("sets exp automatically using defaultExpiry", function() {
					var token = jwt.encode(claims = {sub = 1});
					var claims = jwt.decode(token);
					expect(StructKeyExists(claims, "exp")).toBeTrue();
					expect(claims.exp - claims.iat).toBe(3600);
				});

				it("uses custom expiry when provided", function() {
					var token = jwt.encode(claims = {sub = 1}, expiry = 7200);
					var claims = jwt.decode(token);
					expect(claims.exp - claims.iat).toBe(7200);
				});

				it("preserves explicit iat and exp in claims", function() {
					var token = jwt.encode(claims = {sub = 1, iat = 1000000, exp = 1003600});
					// Use ignoreExpiry: we're testing encode() preservation, not decode() validation.
					// The explicit timestamps are in the past so decode() would reject them.
					var claims = jwt.decode(token = token, ignoreExpiry = true);
					expect(claims.iat).toBe(1000000);
					expect(claims.exp).toBe(1003600);
				});

				it("adds issuer when configured", function() {
					var jwtWithIssuer = new wheels.auth.JwtService(
						secretKey = "test-secret-key-for-jwt-specs",
						issuer = "wheels-app"
					);
					var token = jwtWithIssuer.encode(claims = {sub = 1});
					var claims = jwtWithIssuer.decode(token);
					expect(claims.iss).toBe("wheels-app");
				});

				it("does not overwrite explicit issuer in claims", function() {
					var jwtWithIssuer = new wheels.auth.JwtService(
						secretKey = "test-secret-key-for-jwt-specs",
						issuer = "default-issuer"
					);
					var token = jwtWithIssuer.encode(claims = {sub = 1, iss = "custom-issuer"});
					var claims = jwtWithIssuer.decode(token);
					expect(claims.iss).toBe("custom-issuer");
				});

				it("preserves custom claims through encode/decode", function() {
					var token = jwt.encode(claims = {
						sub = 42,
						role = "admin",
						name = "Test User",
						permissions = ["read", "write"]
					});
					var claims = jwt.decode(token);
					expect(claims.sub).toBe(42);
					expect(claims.role).toBe("admin");
					expect(claims.name).toBe("Test User");
					expect(claims.permissions).toBeArray();
					expect(ArrayLen(claims.permissions)).toBe(2);
				});

			});

			describe("decode()", function() {

				it("returns claims from a valid token", function() {
					var token = jwt.encode(claims = {sub = 99, role = "user"});
					var claims = jwt.decode(token);
					expect(claims.sub).toBe(99);
					expect(claims.role).toBe("user");
				});

				it("throws InvalidToken for malformed tokens", function() {
					expect(function() {
						jwt.decode("not-a-jwt");
					}).toThrow("Wheels.Auth.JWT.InvalidToken");
				});

				it("throws InvalidToken for tokens with wrong number of parts", function() {
					expect(function() {
						jwt.decode("one.two");
					}).toThrow("Wheels.Auth.JWT.InvalidToken");
				});

				it("throws InvalidSignature for tampered tokens", function() {
					var token = jwt.encode(claims = {sub = 1});
					// Tamper with the payload by appending a character
					var parts = ListToArray(token, ".");
					var tampered = parts[1] & "." & parts[2] & "x" & "." & parts[3];
					expect(function() {
						jwt.decode(tampered);
					}).toThrow("Wheels.Auth.JWT.InvalidSignature");
				});

				it("throws InvalidSignature for tokens signed with wrong key", function() {
					var otherJwt = new wheels.auth.JwtService(secretKey = "different-secret");
					var token = otherJwt.encode(claims = {sub = 1});
					expect(function() {
						jwt.decode(token);
					}).toThrow("Wheels.Auth.JWT.InvalidSignature");
				});

				it("throws TokenExpired for expired tokens", function() {
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var token = jwt.encode(claims = {sub = 1, iat = now - 7200, exp = now - 3600});
					expect(function() {
						jwt.decode(token);
					}).toThrow("Wheels.Auth.JWT.TokenExpired");
				});

				it("throws TokenNotYetValid for future nbf", function() {
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var token = jwt.encode(claims = {sub = 1, nbf = now + 3600});
					expect(function() {
						jwt.decode(token);
					}).toThrow("Wheels.Auth.JWT.TokenNotYetValid");
				});

				it("ignores expiry when ignoreExpiry is true", function() {
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var token = jwt.encode(claims = {sub = 1, iat = now - 7200, exp = now - 3600});
					var claims = jwt.decode(token = token, ignoreExpiry = true);
					expect(claims.sub).toBe(1);
				});

				it("still validates signature when ignoreExpiry is true", function() {
					var otherJwt = new wheels.auth.JwtService(secretKey = "wrong-key");
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var token = otherJwt.encode(claims = {sub = 1, exp = now - 3600});
					expect(function() {
						jwt.decode(token = token, ignoreExpiry = true);
					}).toThrow("Wheels.Auth.JWT.InvalidSignature");
				});

			});

			describe("allowedClockSkew", function() {

				it("permits tokens within clock skew window", function() {
					var jwtWithSkew = new wheels.auth.JwtService(
						secretKey = "test-secret-key-for-jwt-specs",
						allowedClockSkew = 60
					);
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					// Token expired 30 seconds ago, but 60 second skew allows it
					var token = jwtWithSkew.encode(claims = {sub = 1, iat = now - 3630, exp = now - 30});
					var claims = jwtWithSkew.decode(token);
					expect(claims.sub).toBe(1);
				});

				it("rejects tokens beyond clock skew window", function() {
					var jwtWithSkew = new wheels.auth.JwtService(
						secretKey = "test-secret-key-for-jwt-specs",
						allowedClockSkew = 60
					);
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					// Token expired 120 seconds ago, 60 second skew not enough
					var token = jwtWithSkew.encode(claims = {sub = 1, iat = now - 3720, exp = now - 120});
					expect(function() {
						jwtWithSkew.decode(token);
					}).toThrow("Wheels.Auth.JWT.TokenExpired");
				});

				it("permits nbf tokens within clock skew window", function() {
					var jwtWithSkew = new wheels.auth.JwtService(
						secretKey = "test-secret-key-for-jwt-specs",
						allowedClockSkew = 60
					);
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					// Token nbf is 30 seconds from now, but 60 second skew allows it
					var token = jwtWithSkew.encode(claims = {sub = 1, nbf = now + 30});
					var claims = jwtWithSkew.decode(token);
					expect(claims.sub).toBe(1);
				});

			});

			describe("verify()", function() {

				it("returns true for a valid token", function() {
					var token = jwt.encode(claims = {sub = 1});
					expect(jwt.verify(token)).toBeTrue();
				});

				it("returns false for an expired token", function() {
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var token = jwt.encode(claims = {sub = 1, iat = now - 7200, exp = now - 3600});
					expect(jwt.verify(token)).toBeFalse();
				});

				it("returns false for a tampered token", function() {
					var token = jwt.encode(claims = {sub = 1});
					expect(jwt.verify(token & "x")).toBeFalse();
				});

				it("returns false for malformed input", function() {
					expect(jwt.verify("not.a.jwt")).toBeFalse();
					expect(jwt.verify("")).toBeFalse();
					expect(jwt.verify("one-part-only")).toBeFalse();
				});

			});

			describe("refresh()", function() {

				it("produces a new valid token", function() {
					var original = jwt.encode(claims = {sub = 42, role = "admin"});
					var refreshed = jwt.refresh(original);
					expect(jwt.verify(refreshed)).toBeTrue();
				});

				it("preserves custom claims", function() {
					var original = jwt.encode(claims = {sub = 42, role = "admin", name = "Tester"});
					var refreshed = jwt.refresh(original);
					var claims = jwt.decode(refreshed);
					expect(claims.sub).toBe(42);
					expect(claims.role).toBe("admin");
					expect(claims.name).toBe("Tester");
				});

				it("generates fresh iat and exp", function() {
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var original = jwt.encode(claims = {sub = 1, iat = now - 7200, exp = now - 3600});
					var refreshed = jwt.refresh(original);
					var claims = jwt.decode(refreshed);
					// New iat should be approximately now
					expect(claims.iat).toBeGTE(now - 5);
					expect(claims.exp).toBeGTE(now + 3595);
				});

				it("accepts custom expiry for refreshed token", function() {
					var original = jwt.encode(claims = {sub = 1});
					var refreshed = jwt.refresh(token = original, expiry = 600);
					var claims = jwt.decode(refreshed);
					expect(claims.exp - claims.iat).toBe(600);
				});

				it("refreshes expired tokens", function() {
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var expired = jwt.encode(claims = {sub = 1, iat = now - 7200, exp = now - 3600});
					// Should not throw even though the token is expired
					var refreshed = jwt.refresh(expired);
					expect(jwt.verify(refreshed)).toBeTrue();
				});

				it("removes jti claim from refreshed token", function() {
					var original = jwt.encode(claims = {sub = 1, jti = "original-id"});
					var refreshed = jwt.refresh(original);
					var claims = jwt.decode(refreshed);
					expect(StructKeyExists(claims, "jti")).toBeFalse();
				});

				it("rejects tokens with invalid signature during refresh", function() {
					var otherJwt = new wheels.auth.JwtService(secretKey = "wrong-key");
					var token = otherJwt.encode(claims = {sub = 1});
					expect(function() {
						jwt.refresh(token);
					}).toThrow("Wheels.Auth.JWT.InvalidSignature");
				});

			});

			describe("extractClaims()", function() {

				it("extracts claims without validation", function() {
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var token = jwt.encode(claims = {sub = 99, iat = now - 7200, exp = now - 3600});
					// Would throw on decode() due to expiry, but extractClaims skips validation
					var claims = jwt.extractClaims(token);
					expect(claims.sub).toBe(99);
				});

				it("throws on completely malformed input", function() {
					expect(function() {
						jwt.extractClaims("no-dots-here");
					}).toThrow("Wheels.Auth.JWT.InvalidToken");
				});

			});

			describe("interoperability", function() {

				it("produces tokens with lowercase JSON claim keys", function() {
					var token = jwt.encode(claims = {SUB = 1, ROLE = "admin"});
					// Decode the payload part directly to verify JSON format
					var parts = ListToArray(token, ".");
					var b64 = Replace(parts[2], "-", "+", "all");
					b64 = Replace(b64, "_", "/", "all");
					var padLen = 4 - (Len(b64) % 4);
					if (padLen < 4) {
						b64 = b64 & RepeatString("=", padLen);
					}
					var json = ToString(ToBinary(b64));
					// Keys should be lowercase in the JSON.
					// Use case-sensitive Find() because TestBox's toInclude uses FindNoCase.
					expect(json).toInclude('"sub"');
					expect(json).toInclude('"role"');
					expect(Find('"SUB"', json)).toBe(0, "Expected no uppercase SUB key in JWT JSON");
					expect(Find('"ROLE"', json)).toBe(0, "Expected no uppercase ROLE key in JWT JSON");
				});

			});

		});

	}

}
