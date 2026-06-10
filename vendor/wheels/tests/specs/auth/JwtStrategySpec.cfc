component extends="wheels.WheelsTest" {

	function run() {

		describe("JwtStrategy", function() {

			beforeEach(function() {
				jwtService = new wheels.auth.JwtService(
					secretKey = "test-secret-for-strategy-specs-padded-to-32",
					defaultExpiry = 3600
				);
				strategy = new wheels.auth.JwtStrategy(jwtService = jwtService);
			});

			describe("getName()", function() {

				it("returns jwt", function() {
					expect(strategy.getName()).toBe("jwt");
				});

			});

			describe("supports()", function() {

				it("returns true when Authorization Bearer header is present", function() {
					var token = jwtService.encode(claims = {sub = 1});
					var req = {headers = {authorization = "Bearer " & token}};
					expect(strategy.supports(req)).toBeTrue();
				});

				it("returns false without Authorization header", function() {
					var req = {headers = {}};
					expect(strategy.supports(req)).toBeFalse();
				});

				it("returns false without headers struct", function() {
					var req = {};
					expect(strategy.supports(req)).toBeFalse();
				});

				it("returns false for non-Bearer Authorization header", function() {
					var req = {headers = {authorization = "Basic dXNlcjpwYXNz"}};
					expect(strategy.supports(req)).toBeFalse();
				});

				it("returns true when query param is configured and present", function() {
					var strategyWithParam = new wheels.auth.JwtStrategy(
						jwtService = jwtService,
						queryParam = "token"
					);
					var token = jwtService.encode(claims = {sub = 1});
					var req = {headers = {}, params = {token = token}};
					expect(strategyWithParam.supports(req)).toBeTrue();
				});

				it("returns false when query param is configured but absent", function() {
					var strategyWithParam = new wheels.auth.JwtStrategy(
						jwtService = jwtService,
						queryParam = "token"
					);
					var req = {headers = {}, params = {}};
					expect(strategyWithParam.supports(req)).toBeFalse();
				});

			});

			describe("authenticate()", function() {

				it("succeeds with a valid Bearer token", function() {
					var token = jwtService.encode(claims = {sub = 42, role = "admin"});
					var req = {headers = {authorization = "Bearer " & token}};
					var result = strategy.authenticate(req);
					expect(result.success).toBeTrue();
					expect(result.statusCode).toBe(200);
					expect(result.strategy).toBe("jwt");
					expect(result.principal.sub).toBe(42);
					expect(result.principal.role).toBe("admin");
				});

				it("succeeds with token from query param", function() {
					var strategyWithParam = new wheels.auth.JwtStrategy(
						jwtService = jwtService,
						queryParam = "token"
					);
					var token = jwtService.encode(claims = {sub = 7});
					var req = {headers = {}, params = {token = token}};
					var result = strategyWithParam.authenticate(req);
					expect(result.success).toBeTrue();
					expect(result.principal.sub).toBe(7);
				});

				it("fails when no token is found", function() {
					var req = {headers = {}};
					var result = strategy.authenticate(req);
					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
					expect(result.error).toInclude("No JWT token");
				});

				it("fails with an expired token", function() {
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var token = jwtService.encode(claims = {sub = 1, iat = now - 7200, exp = now - 3600});
					var req = {headers = {authorization = "Bearer " & token}};
					var result = strategy.authenticate(req);
					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
					expect(result.error).toInclude("expired");
					expect(result.strategy).toBe("jwt");
				});

				it("fails with an invalid signature", function() {
					var otherService = new wheels.auth.JwtService(secretKey = "wrong-key-padded-to-at-least-32-bytes");
					var token = otherService.encode(claims = {sub = 1});
					var req = {headers = {authorization = "Bearer " & token}};
					var result = strategy.authenticate(req);
					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
					expect(result.error).toInclude("signature");
				});

				it("fails with a malformed token", function() {
					var req = {headers = {authorization = "Bearer not-a-valid-jwt"}};
					var result = strategy.authenticate(req);
					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
				});

				it("fails with not-yet-valid token", function() {
					var now = Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000);
					var token = jwtService.encode(claims = {sub = 1, nbf = now + 3600});
					var req = {headers = {authorization = "Bearer " & token}};
					var result = strategy.authenticate(req);
					expect(result.success).toBeFalse();
					expect(result.error).toInclude("not yet valid");
				});

				it("prefers Authorization header over query param", function() {
					var strategyWithParam = new wheels.auth.JwtStrategy(
						jwtService = jwtService,
						queryParam = "token"
					);
					var headerToken = jwtService.encode(claims = {sub = 1, source = "header"});
					var paramToken = jwtService.encode(claims = {sub = 2, source = "param"});
					var req = {
						headers = {authorization = "Bearer " & headerToken},
						params = {token = paramToken}
					};
					var result = strategyWithParam.authenticate(req);
					expect(result.success).toBeTrue();
					expect(result.principal.source).toBe("header");
				});

			});

			describe("Authenticator integration", function() {

				it("works when registered with the Authenticator", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "jwt", strategy = strategy);

					var token = jwtService.encode(claims = {sub = 42});
					var req = {headers = {authorization = "Bearer " & token}};
					var result = auth.authenticate(request = req);

					expect(result.success).toBeTrue();
					expect(result.principal.sub).toBe(42);
					expect(result.strategy).toBe("jwt");
				});

				it("is skipped by Authenticator when no token present", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "jwt", strategy = strategy);
					auth.registerStrategy(
						name = "fallback",
						strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "fallback")
					);

					var req = {headers = {}};
					var result = auth.authenticate(request = req);

					// JWT strategy doesn't support (no token), falls through to fallback
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("fallback");
				});

				it("Authenticator tries next strategy when JWT fails", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "jwt", strategy = strategy);
					auth.registerStrategy(
						name = "fallback",
						strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "fallback")
					);

					// Send an invalid JWT so the JWT strategy fails
					var otherService = new wheels.auth.JwtService(secretKey = "wrong-key-padded-to-at-least-32-bytes");
					var badToken = otherService.encode(claims = {sub = 1});
					var req = {headers = {authorization = "Bearer " & badToken}};
					var result = auth.authenticate(request = req);

					// JWT strategy supported but failed; Authenticator tries fallback
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("fallback");
				});

			});

		});

	}

}
