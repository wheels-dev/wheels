/**
 * Hardener SHOULDs S1–S8 (auth).
 *
 * Directory-scoped so `wheels test --core --ci --filter=hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 *
 * Escalations (no silent public default/API flips):
 *   S6 JwtService.refresh() default stays ignoreExpiry-forever (maxRefreshAge=0).
 *   S7 JwtService.decode() default stays fail-open for missing exp (requireExpiry=false).
 *
 * CoS lock: allowedClockSkew=0, issuer="", queryParam="", iterations=600000.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CoS lock: auth public defaults stay conservative", function() {

			it("keeps JwtService clock skew 0 and issuer empty", function() {
				var jwt = new wheels.auth.JwtService(
					secretKey = "test-secret-key-for-jwt-specs-padded-to-32-bytes"
				);
				var token = jwt.encode(claims = {sub = 1});
				var claims = jwt.decode(token);
				expect(StructKeyExists(claims, "iss")).toBeFalse();

				var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
				var expired = jwt.encode(claims = {sub = 1, iat = now - 10, exp = now - 1});
				expect(function() {
					jwt.decode(expired);
				}).toThrow("Wheels.Auth.JWT.TokenExpired");
			});

			it("keeps TokenStrategy and JwtStrategy queryParam disabled", function() {
				var jwt = new wheels.auth.JwtService(
					secretKey = "test-secret-key-for-jwt-specs-padded-to-32-bytes"
				);
				var tokenStrategy = new wheels.auth.TokenStrategy();
				expect(tokenStrategy.supports(request = {params = {api_key = "x"}})).toBeFalse();

				var jwtStrategy = new wheels.auth.JwtStrategy(jwtService = jwt);
				var token = jwt.encode(claims = {sub = 1});
				expect(
					jwtStrategy.supports(request = {headers = {}, params = {token = token}})
				).toBeFalse();
			});

			it("keeps PasswordHasher iterations at 600000", function() {
				var hasher = new wheels.auth.PasswordHasher();
				var digest = hasher.hash("hardener-cos-lock");
				expect(digest).toInclude("$i=600000$");
			});

		});

		describe("S1 SessionStrategy login does not swallow rotate failures", function() {

			it("surfaces a $rotateSession failure instead of logging in on the old SID", function() {
				var strategy = new wheels.tests._assets.auth.ThrowingRotateSessionStrategy();
				var state = {threw = false, type = ""};
				try {
					strategy.login(principal = {id = 1});
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Auth.SessionRotateFailed");
				expect(strategy.isLoggedIn()).toBeFalse();
			});

			it("login invokes $rotateSession", function() {
				var strategy = new wheels.tests._assets.auth.CountingRotateSessionStrategy();
				strategy.login(principal = {id = 7});
				expect(strategy.$rotateCount()).toBe(1);
				expect(strategy.isLoggedIn()).toBeTrue();
			});

			it("SessionStrategy.cfc has no catch-any around session rotation", function() {
				var src = FileRead(ExpandPath("/wheels/auth/SessionStrategy.cfc"));
				expect(FindNoCase("catch (any", src)).toBe(
					0,
					"sessionRotate/sessionInvalidate must not be wrapped in catch-any"
				);
			});

		});

		describe("S2 logout rotates or invalidates the SID", function() {

			beforeEach(function() {
				StructDelete(session, "wheels");
			});

			afterEach(function() {
				StructDelete(session, "wheels");
			});

			it("logout invokes $rotateSession after clearing the principal", function() {
				var strategy = new wheels.tests._assets.auth.CountingRotateSessionStrategy();
				strategy.login(principal = {id = 7});
				expect(strategy.$rotateCount()).toBe(1);
				strategy.logout();
				expect(strategy.isLoggedIn()).toBeFalse();
				expect(strategy.$rotateCount()).toBe(2);
			});

			it("logout changes the session identity", function() {
				var strategy = new wheels.auth.SessionStrategy();
				strategy.login(principal = {id = 7});
				var before = $sessionIdentity();
				expect($sessionIdentityPresent(before)).toBeTrue();
				strategy.logout();
				var after = $sessionIdentity();
				expect($sessionIdentityChanged(before, after)).toBeTrue();
				expect(strategy.isLoggedIn()).toBeFalse();
			});

			it("surfaces a $rotateSession failure on logout", function() {
				var strategy = new wheels.tests._assets.auth.ThrowingRotateSessionStrategy();
				session.wheels = {auth = {id = 9}};
				var state = {threw = false, type = ""};
				try {
					strategy.logout();
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Auth.SessionRotateFailed");
			});

		});

		describe("S3 authenticateWith does not skip unknown names", function() {

			it("fails closed when the restriction list mixes a typo with a known name", function() {
				var auth = new wheels.auth.Authenticator();
				auth.registerStrategy(
					name = "pass",
					strategy = new wheels.tests._assets.auth.AlwaysPassStrategy()
				);
				var result = auth.authenticateWith(request = {}, strategies = "ghost,pass");
				expect(result.success).toBeFalse();
				expect(result.statusCode).toBe(401);
				expect(result.error).toInclude("ghost");
				expect(result.error).toInclude("unregistered strategy");
			});

			it("fails closed for an array filter that includes an unknown name", function() {
				var auth = new wheels.auth.Authenticator();
				auth.registerStrategy(
					name = "pass",
					strategy = new wheels.tests._assets.auth.AlwaysPassStrategy()
				);
				var result = auth.authenticateWith(request = {}, strategies = ["ghost", "pass"]);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("ghost");
			});

			it("still authenticates when every listed name is registered", function() {
				var auth = new wheels.auth.Authenticator();
				auth.registerStrategy(
					name = "pass",
					strategy = new wheels.tests._assets.auth.AlwaysPassStrategy()
				);
				var result = auth.authenticateWith(request = {}, strategies = "pass");
				expect(result.success).toBeTrue();
			});

		});

		describe("S4 TokenStrategy docs do not interpolate tokens into SQL", function() {

			it("TokenStrategy.cfc usage sample has no interpolated where= token", function() {
				var src = FileRead(ExpandPath("/wheels/auth/TokenStrategy.cfc"));
				// Build the forbidden interpolation without putting a raw ## pair
				// that CFML would treat as an empty expression in this spec.
				var interpolatedWhere = "token=" & Chr(39) & "##token##" & Chr(39);
				expect(FindNoCase(interpolatedWhere, src)).toBe(
					0,
					"TokenStrategy docs must not show where=""token='##token##'"""
				);
			});

		});

		describe("S5 login changes the session identity", function() {

			beforeEach(function() {
				StructDelete(session, "wheels");
			});

			afterEach(function() {
				StructDelete(session, "wheels");
			});

			it("login rotates the SID, not just stores the principal", function() {
				var strategy = new wheels.auth.SessionStrategy();
				var before = $sessionIdentity();
				expect($sessionIdentityPresent(before)).toBeTrue();
				strategy.login(principal = {id = 42, role = "admin"});
				var after = $sessionIdentity();
				expect(strategy.isLoggedIn()).toBeTrue();
				expect(strategy.currentUser().id).toBe(42);
				expect($sessionIdentityChanged(before, after)).toBeTrue();
			});

		});

		describe("S6 JwtService.refresh max-age contract (escalated default)", function() {

			it("default maxRefreshAge=0 still refreshes a token expired years ago", function() {
				var jwt = new wheels.auth.JwtService(
					secretKey = "test-secret-key-for-jwt-specs-padded-to-32-bytes"
				);
				var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
				var ancient = jwt.encode(
					claims = {sub = 1, iat = now - (10 * 365 * 86400), exp = now - (10 * 365 * 86400) + 3600}
				);
				var refreshed = jwt.refresh(ancient);
				expect(jwt.verify(refreshed)).toBeTrue();
			});

			it("rejects refresh when maxRefreshAge is set and the token is older than that window", function() {
				var jwt = new wheels.auth.JwtService(
					secretKey = "test-secret-key-for-jwt-specs-padded-to-32-bytes",
					maxRefreshAge = 86400
				);
				var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
				var ancient = jwt.encode(
					claims = {sub = 1, iat = now - (10 * 365 * 86400), exp = now - (10 * 365 * 86400) + 3600}
				);
				expect(function() {
					jwt.refresh(ancient);
				}).toThrow("Wheels.Auth.JWT.RefreshWindowExceeded");
			});

			it("still refreshes a recently expired token when maxRefreshAge is set", function() {
				var jwt = new wheels.auth.JwtService(
					secretKey = "test-secret-key-for-jwt-specs-padded-to-32-bytes",
					maxRefreshAge = 86400
				);
				var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
				var recent = jwt.encode(claims = {sub = 9, iat = now - 7200, exp = now - 30});
				var refreshed = jwt.refresh(recent);
				var claims = jwt.decode(refreshed);
				expect(claims.sub).toBe(9);
			});

		});

		describe("S7 JwtService.decode missing exp (escalated default)", function() {

			it("default requireExpiry=false still accepts a signed token with no exp", function() {
				var secret = "test-secret-key-for-jwt-specs-padded-to-32-bytes";
				var jwt = new wheels.auth.JwtService(secretKey = secret);
				var token = $signHs256(
					secret,
					"{""alg"":""HS256"",""typ"":""JWT""}",
					"{""sub"":1,""iat"":1000}"
				);
				var claims = jwt.decode(token);
				expect(claims.sub).toBe(1);
				expect(StructKeyExists(claims, "exp")).toBeFalse();
			});

			it("rejects a signed token with no exp when requireExpiry is true", function() {
				var secret = "test-secret-key-for-jwt-specs-padded-to-32-bytes";
				var jwt = new wheels.auth.JwtService(secretKey = secret, requireExpiry = true);
				var token = $signHs256(
					secret,
					"{""alg"":""HS256"",""typ"":""JWT""}",
					"{""sub"":1,""iat"":1000}"
				);
				expect(function() {
					jwt.decode(token);
				}).toThrow("Wheels.Auth.JWT.MissingExpiry");
			});

		});

		describe("S8 JwtStrategy catch-all does not leak exception messages", function() {

			beforeEach(function() {
				jwtService = new wheels.auth.JwtService(
					secretKey = "test-secret-for-strategy-specs-padded-to-32"
				);
				strategy = new wheels.auth.JwtStrategy(jwtService = jwtService);
			});

			it("returns a generic 401 for an unexpected JWT error", function() {
				var headerB64 = $base64UrlEncode("{""alg"":""none"",""typ"":""JWT""}");
				var payloadB64 = $base64UrlEncode("{""sub"":1,""iat"":999999999,""exp"":999999999}");
				var fakeToken = headerB64 & "." & payloadB64 & ".fakesig";
				var req = {headers = {authorization = "Bearer " & fakeToken}};
				var result = strategy.authenticate(req);
				expect(result.success).toBeFalse();
				expect(result.statusCode).toBe(401);
				expect(result.error).notToInclude("JWT authentication error:");
				expect(FindNoCase("substitution", result.error)).toBe(0);
				expect(FindNoCase("none", result.error)).toBe(0);
				expect(result.error).notToInclude("fakesig");
			});

			it("does not leak InvalidIssuer details through the catch-all", function() {
				var issuerService = new wheels.auth.JwtService(
					secretKey = "test-secret-for-strategy-specs-padded-to-32",
					issuer = "expected-issuer"
				);
				var issuerStrategy = new wheels.auth.JwtStrategy(jwtService = issuerService);
				var otherService = new wheels.auth.JwtService(
					secretKey = "test-secret-for-strategy-specs-padded-to-32",
					issuer = "other-issuer"
				);
				var token = otherService.encode(claims = {sub = 1});
				var req = {headers = {authorization = "Bearer " & token}};
				var result = issuerStrategy.authenticate(req);
				expect(result.success).toBeFalse();
				expect(result.statusCode).toBe(401);
				expect(result.error).notToInclude("JWT authentication error:");
				expect(result.error).notToInclude(token);
			});

		});

	}

	/**
	 * Snapshot identifying session fields so SID rotation can be asserted
	 * without depending on a single engine-specific key.
	 */
	private struct function $sessionIdentity() {
		var id = {};
		if (StructKeyExists(session, "sessionid") && Len(ToString(session.sessionid))) {
			id.sessionid = ToString(session.sessionid);
		}
		if (StructKeyExists(session, "cfid") && Len(ToString(session.cfid))) {
			id.cfid = ToString(session.cfid);
		}
		if (StructKeyExists(session, "cftoken") && Len(ToString(session.cftoken))) {
			id.cftoken = ToString(session.cftoken);
		}
		if (StructKeyExists(session, "urltoken") && Len(ToString(session.urltoken))) {
			id.urltoken = ToString(session.urltoken);
		}
		var javaId = "";
		try {
			var ctx = GetPageContext();
			var sess = ctx.getSession();
			if (!IsNull(sess)) {
				javaId = ToString(sess.getId());
			}
		} catch (any e) {
			javaId = "";
		}
		if (Len(javaId)) {
			id.javaId = javaId;
		}
		return id;
	}

	private boolean function $sessionIdentityPresent(required struct identity) {
		return !StructIsEmpty(arguments.identity);
	}

	private boolean function $sessionIdentityChanged(required struct before, required struct after) {
		for (var key in arguments.before) {
			if (StructKeyExists(arguments.after, key) && arguments.after[key] != arguments.before[key]) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Craft a valid HS256 JWT from JSON strings (used to omit exp).
	 */
	private string function $signHs256(required string secret, required string headerJson, required string payloadJson) {
		var headerB64 = $base64UrlEncode(arguments.headerJson);
		var payloadB64 = $base64UrlEncode(arguments.payloadJson);
		var input = headerB64 & "." & payloadB64;
		var hmacHex = HMac(input, arguments.secret, "HMACSHA256", "UTF-8");
		var hmacBinary = BinaryDecode(hmacHex, "hex");
		var b64 = BinaryEncode(hmacBinary, "base64");
		b64 = Replace(b64, "+", "-", "all");
		b64 = Replace(b64, "/", "_", "all");
		b64 = REReplace(b64, "=+$", "");
		return input & "." & b64;
	}

	private string function $base64UrlEncode(required string value) {
		var b64 = ToBase64(arguments.value);
		b64 = Replace(b64, "+", "-", "all");
		b64 = Replace(b64, "/", "_", "all");
		b64 = REReplace(b64, "=+$", "");
		return b64;
	}

}
