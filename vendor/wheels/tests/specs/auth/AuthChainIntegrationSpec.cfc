/**
 * Integration test: full authentication chain in a running app.
 *
 * Wires together the real Authenticator, SessionStrategy, TokenStrategy,
 * JwtStrategy, JwtService, AuthMiddleware, and Pipeline to verify the
 * entire auth stack works end-to-end — strategy registration, authenticate()
 * flow, middleware route protection, token generation/validation, and
 * session lifecycle.
 *
 * No mock strategies are used. Every component is the production implementation.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Auth Chain Integration", function() {

			var SECRET_KEY = "wheels-integration-test-secret-key-2026";
			var jwtService = "";
			var sessionStrategy = "";
			var tokenStrategy = "";
			var jwtStrategy = "";
			var authenticator = "";

			beforeEach(function() {
				// Clean session state
				StructDelete(session, "wheels");

				// Build real services
				jwtService = new wheels.auth.JwtService(
					secretKey = SECRET_KEY,
					defaultExpiry = 3600,
					issuer = "wheels-test"
				);

				sessionStrategy = new wheels.auth.SessionStrategy();

				// Token strategy with static token map
				tokenStrategy = new wheels.auth.TokenStrategy(
					tokens = {
						"valid-api-key-123": {id = 100, role = "api_user", name = "API Bot"},
						"admin-key-456": {id = 1, role = "admin", name = "Admin Bot"}
					}
				);

				jwtStrategy = new wheels.auth.JwtStrategy(jwtService = jwtService);

				// Build authenticator with all three real strategies
				authenticator = new wheels.auth.Authenticator();
				authenticator.registerStrategy(name = "session", strategy = sessionStrategy);
				authenticator.registerStrategy(name = "token", strategy = tokenStrategy);
				authenticator.registerStrategy(name = "jwt", strategy = jwtStrategy);
			});

			afterEach(function() {
				StructDelete(session, "wheels");
			});

			// =================================================================
			// Strategy registration
			// =================================================================

			describe("Strategy registration with real strategies", function() {

				it("registers all three real strategies", function() {
					var names = authenticator.getStrategyNames();
					expect(names).toHaveLength(3);
					expect(names[1]).toBe("session");
					expect(names[2]).toBe("token");
					expect(names[3]).toBe("jwt");
				});

				it("retrieves each strategy by name", function() {
					expect(authenticator.getStrategy("session").getName()).toBe("session");
					expect(authenticator.getStrategy("token").getName()).toBe("token");
					expect(authenticator.getStrategy("jwt").getName()).toBe("jwt");
				});

			});

			// =================================================================
			// Token-based authentication through the full chain
			// =================================================================

			describe("Token auth through Authenticator", function() {

				it("authenticates a valid Bearer token", function() {
					var req = {headers = {authorization = "Bearer valid-api-key-123"}};
					var result = authenticator.authenticate(request = req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(100);
					expect(result.principal.role).toBe("api_user");
					expect(result.strategy).toBe("token");
				});

				it("rejects an invalid token", function() {
					var req = {headers = {authorization = "Bearer bad-key"}};
					var result = authenticator.authenticate(request = req);

					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
				});

				it("authenticates admin token with correct principal", function() {
					var req = {headers = {authorization = "Bearer admin-key-456"}};
					var result = authenticator.authenticate(request = req);

					expect(result.success).toBeTrue();
					expect(result.principal.role).toBe("admin");
					expect(result.principal.name).toBe("Admin Bot");
				});

			});

			// =================================================================
			// JWT authentication through the full chain
			// =================================================================

			describe("JWT auth through Authenticator", function() {

				it("authenticates a valid JWT token", function() {
					var token = jwtService.encode(claims = {sub = 42, role = "editor"});
					var req = {headers = {authorization = "Bearer " & token}};

					var result = authenticator.authenticate(request = req);

					expect(result.success).toBeTrue();
					expect(result.principal.sub).toBe(42);
					expect(result.principal.role).toBe("editor");
				});

				it("JWT token includes issuer claim from service config", function() {
					var token = jwtService.encode(claims = {sub = 1});
					var claims = jwtService.decode(token);

					expect(claims.iss).toBe("wheels-test");
				});

				it("rejects a JWT signed with the wrong key", function() {
					var badService = new wheels.auth.JwtService(secretKey = "wrong-key");
					var badToken = badService.encode(claims = {sub = 1});
					var req = {headers = {authorization = "Bearer " & badToken}};

					var result = authenticator.authenticate(request = req);

					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
				});

				it("rejects an expired JWT", function() {
					var token = jwtService.encode(claims = {sub = 1, exp = 1000000});
					var req = {headers = {authorization = "Bearer " & token}};

					var result = authenticator.authenticate(request = req);

					expect(result.success).toBeFalse();
				});

				it("refreshes a JWT token with new expiry", function() {
					var originalToken = jwtService.encode(claims = {sub = 99, role = "user"});
					var refreshed = jwtService.refresh(token = originalToken);

					expect(refreshed).notToBe(originalToken);

					var claims = jwtService.decode(refreshed);
					expect(claims.sub).toBe(99);
					expect(claims.role).toBe("user");
					expect(claims.iss).toBe("wheels-test");
				});

			});

			// =================================================================
			// Session lifecycle through the full chain
			// =================================================================

			describe("Session lifecycle through Authenticator", function() {

				it("session strategy is skipped when no session exists", function() {
					var req = {};
					var result = authenticator.authenticate(request = req);

					// No session, no token header → all strategies fail
					expect(result.success).toBeFalse();
				});

				it("session login makes subsequent auth succeed", function() {
					sessionStrategy.login(principal = {id = 7, role = "admin", name = "Alice"});

					var result = authenticator.authenticate(request = {});

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(7);
					expect(result.principal.name).toBe("Alice");
					expect(result.strategy).toBe("session");
				});

				it("session logout makes auth fall through to other strategies", function() {
					sessionStrategy.login(principal = {id = 7});
					sessionStrategy.logout();

					// No token header either → all fail
					var result = authenticator.authenticate(request = {});
					expect(result.success).toBeFalse();
				});

				it("session auth is preferred over token when both present", function() {
					sessionStrategy.login(principal = {id = 7, role = "session_user"});
					var req = {headers = {authorization = "Bearer valid-api-key-123"}};

					var result = authenticator.authenticate(request = req);

					// Session is registered first, so it's tried first
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("session");
					expect(result.principal.role).toBe("session_user");
				});

			});

			// =================================================================
			// Multi-strategy fallback
			// =================================================================

			describe("Multi-strategy fallback ordering", function() {

				it("falls from session to token when session is empty", function() {
					var req = {headers = {authorization = "Bearer valid-api-key-123"}};
					var result = authenticator.authenticate(request = req);

					// Session has no data → token strategy picks it up
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("token");
				});

				it("falls from session and token to JWT", function() {
					var token = jwtService.encode(claims = {sub = 55});
					var req = {headers = {authorization = "Bearer " & token}};

					// Token strategy will try first (it supports Bearer headers too),
					// but the JWT string won't match any static token, so it falls to JWT
					var result = authenticator.authenticate(request = req);

					expect(result.success).toBeTrue();
					// JWT strategy should authenticate it
					expect(result.principal.sub).toBe(55);
				});

				it("default strategy is tried first when set", function() {
					authenticator.setDefaultStrategy("jwt");

					var token = jwtService.encode(claims = {sub = 77});
					var req = {headers = {authorization = "Bearer " & token}};

					var result = authenticator.authenticate(request = req);

					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("jwt");
					expect(result.principal.sub).toBe(77);
				});

			});

			// =================================================================
			// AuthMiddleware + Pipeline with real strategies
			// =================================================================

			describe("AuthMiddleware in Pipeline with real strategies", function() {

				it("blocks unauthenticated requests", function() {
					var mw = new wheels.middleware.AuthMiddleware(authenticator = authenticator);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var handlerCalled = {value = false};
					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						handlerCalled.value = true;
						return "should not reach";
					});

					expect(handlerCalled.value).toBeFalse();
					var parsed = DeserializeJSON(result);
					expect(parsed.status).toBe(401);
				});

				it("passes authenticated token requests to handler", function() {
					var mw = new wheels.middleware.AuthMiddleware(authenticator = authenticator);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {auth = {}};
					var result = pipeline.run(
						request = {headers = {authorization = "Bearer valid-api-key-123"}},
						coreHandler = function(required struct request) {
							captured.auth = arguments.request.auth;
							return "OK";
						}
					);

					expect(result).toBe("OK");
					expect(captured.auth.success).toBeTrue();
					expect(captured.auth.principal.id).toBe(100);
					expect(captured.auth.strategy).toBe("token");
				});

				it("passes authenticated JWT requests to handler", function() {
					var svc = jwtService;
					var token = svc.encode(claims = {sub = 42, role = "editor"});
					var mw = new wheels.middleware.AuthMiddleware(authenticator = authenticator);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {auth = {}};
					var result = pipeline.run(
						request = {headers = {authorization = "Bearer " & token}},
						coreHandler = function(required struct request) {
							captured.auth = arguments.request.auth;
							return "OK";
						}
					);

					expect(result).toBe("OK");
					expect(captured.auth.success).toBeTrue();
					expect(captured.auth.principal.sub).toBe(42);
				});

				it("passes authenticated session requests to handler", function() {
					sessionStrategy.login(principal = {id = 10, role = "user"});

					var mw = new wheels.middleware.AuthMiddleware(authenticator = authenticator);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {auth = {}};
					var result = pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							captured.auth = arguments.request.auth;
							return "OK";
						}
					);

					expect(result).toBe("OK");
					expect(captured.auth.success).toBeTrue();
					expect(captured.auth.principal.id).toBe(10);
					expect(captured.auth.strategy).toBe("session");
				});

			});

			// =================================================================
			// Strategy restriction per route
			// =================================================================

			describe("Per-route strategy restriction", function() {

				it("API route accepts only token strategy", function() {
					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = authenticator,
						strategies = "token"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					// Session is active but middleware only allows "token"
					sessionStrategy.login(principal = {id = 1});

					var result = pipeline.run(
						request = {headers = {authorization = "Bearer valid-api-key-123"}},
						coreHandler = function(required struct request) {
							return arguments.request.auth.strategy;
						}
					);

					expect(result).toBe("token");
				});

				it("JWT-only route rejects static tokens", function() {
					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = authenticator,
						strategies = "jwt"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(
						request = {headers = {authorization = "Bearer valid-api-key-123"}},
						coreHandler = function(required struct request) {
							return "should not reach";
						}
					);

					var parsed = DeserializeJSON(result);
					expect(parsed.status).toBe(401);
				});

				it("JWT-only route accepts valid JWT", function() {
					var svc = jwtService;
					var token = svc.encode(claims = {sub = 88});
					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = authenticator,
						strategies = "jwt"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {sub = 0};
					pipeline.run(
						request = {headers = {authorization = "Bearer " & token}},
						coreHandler = function(required struct request) {
							captured.sub = arguments.request.auth.principal.sub;
							return "OK";
						}
					);

					expect(captured.sub).toBe(88);
				});

				it("session-only route works with logged-in user", function() {
					sessionStrategy.login(principal = {id = 5, role = "member"});

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = authenticator,
						strategies = "session"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {auth = {}};
					var result = pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							captured.auth = arguments.request.auth;
							return "OK";
						}
					);

					expect(result).toBe("OK");
					expect(captured.auth.principal.id).toBe(5);
					expect(captured.auth.strategy).toBe("session");
				});

				it("multi-strategy route tries both token and jwt", function() {
					var svc = jwtService;
					var token = svc.encode(claims = {sub = 33});
					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = authenticator,
						strategies = "token,jwt"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					// The JWT won't match static tokens, so token strategy fails,
					// then jwt strategy succeeds
					var captured = {strategy = ""};
					pipeline.run(
						request = {headers = {authorization = "Bearer " & token}},
						coreHandler = function(required struct request) {
							captured.strategy = arguments.request.auth.strategy;
							return "OK";
						}
					);

					expect(captured.strategy).toBe("jwt");
				});

			});

			// =================================================================
			// allowAnonymous with real strategies
			// =================================================================

			describe("allowAnonymous mode with real strategies", function() {

				it("proceeds to handler even without auth", function() {
					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = authenticator,
						allowAnonymous = true
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {auth = {}};
					var result = pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							captured.auth = arguments.request.auth;
							return "OK";
						}
					);

					expect(result).toBe("OK");
					expect(captured.auth.success).toBeFalse();
				});

				it("attaches successful auth when user is authenticated", function() {
					sessionStrategy.login(principal = {id = 3});

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = authenticator,
						allowAnonymous = true
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {auth = {}};
					pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							captured.auth = arguments.request.auth;
							return "OK";
						}
					);

					expect(captured.auth.success).toBeTrue();
					expect(captured.auth.principal.id).toBe(3);
				});

			});

			// =================================================================
			// Custom failure handler with real strategies
			// =================================================================

			describe("Custom failure handler", function() {

				it("invokes onFailure with real auth result", function() {
					var customHandler = function(request, authResult) {
						return "DENIED:" & authResult.statusCode & ":" & authResult.error;
					};
					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = authenticator,
						onFailure = customHandler
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							return "should not reach";
						}
					);

					expect(result).toInclude("DENIED:401:");
				});

			});

			// =================================================================
			// Pipeline with multiple middleware layers
			// =================================================================

			describe("Pipeline with auth + other middleware", function() {

				it("auth middleware works after other middleware in chain", function() {
					// Simulate a request-id middleware that adds a header
					var requestIdMw = {
						handle = function(required struct request, required any next) {
							arguments.request.requestId = CreateUUID();
							return arguments.next(arguments.request);
						}
					};

					var authMw = new wheels.middleware.AuthMiddleware(authenticator = authenticator);
					var pipeline = new wheels.middleware.Pipeline(middleware = [requestIdMw, authMw]);

					sessionStrategy.login(principal = {id = 20});

					var captured = {requestId = "", authOk = false};
					pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							captured.requestId = arguments.request.requestId;
							captured.authOk = arguments.request.auth.success;
							return "OK";
						}
					);

					expect(Len(captured.requestId)).toBeGT(0);
					expect(captured.authOk).toBeTrue();
				});

				it("auth failure short-circuits before later middleware runs", function() {
					var laterCalled = {value = false};
					var laterMw = {
						handle = function(required struct request, required any next) {
							laterCalled.value = true;
							return arguments.next(arguments.request);
						}
					};

					var authMw = new wheels.middleware.AuthMiddleware(authenticator = authenticator);
					// Auth middleware first, then later middleware
					var pipeline = new wheels.middleware.Pipeline(middleware = [authMw, laterMw]);

					pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							return "nope";
						}
					);

					expect(laterCalled.value).toBeFalse();
				});

			});

			// =================================================================
			// JWT token generation and validation lifecycle
			// =================================================================

			describe("JWT token lifecycle", function() {

				it("encode-decode round trip preserves custom claims", function() {
					var token = jwtService.encode(claims = {
						sub = 42,
						role = "admin",
						permissions = "read,write,delete"
					});

					var claims = jwtService.decode(token);

					expect(claims.sub).toBe(42);
					expect(claims.role).toBe("admin");
					expect(claims.permissions).toBe("read,write,delete");
					expect(claims.iss).toBe("wheels-test");
					expect(claims).toHaveKey("iat");
					expect(claims).toHaveKey("exp");
				});

				it("verify returns true for valid token", function() {
					var token = jwtService.encode(claims = {sub = 1});
					expect(jwtService.verify(token)).toBeTrue();
				});

				it("verify returns false for tampered token", function() {
					var token = jwtService.encode(claims = {sub = 1});
					// Tamper with the payload
					var tampered = Replace(token, ".", "X.", "one");
					expect(jwtService.verify(tampered)).toBeFalse();
				});

				it("refresh produces a new valid token with same claims", function() {
					var original = jwtService.encode(claims = {sub = 99, role = "editor"});
					var refreshed = jwtService.refresh(token = original);

					expect(refreshed).notToBe(original);

					var claims = jwtService.decode(refreshed);
					expect(claims.sub).toBe(99);
					expect(claims.role).toBe("editor");
				});

			});

			// =================================================================
			// Application scope authenticator resolution
			// =================================================================

			describe("Authenticator resolution from application scope", function() {

				it("middleware resolves authenticator from application.$wheels", function() {
					var savedAuth = "";
					var hadAuth = false;
					if (StructKeyExists(application, "$wheels") && StructKeyExists(application.$wheels, "authenticator")) {
						savedAuth = application.$wheels.authenticator;
						hadAuth = true;
					}

					try {
						application.$wheels.authenticator = authenticator;
						sessionStrategy.login(principal = {id = 50});

						// No authenticator passed to init — should resolve from app scope
						var mw = new wheels.middleware.AuthMiddleware();
						var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

						var captured = {auth = {}};
						pipeline.run(
							request = {},
							coreHandler = function(required struct request) {
								captured.auth = arguments.request.auth;
								return "OK";
							}
						);

						expect(captured.auth.success).toBeTrue();
						expect(captured.auth.principal.id).toBe(50);
					} finally {
						if (hadAuth) {
							application.$wheels.authenticator = savedAuth;
						} else if (StructKeyExists(application, "$wheels")) {
							StructDelete(application.$wheels, "authenticator");
						}
					}
				});

			});

			// =================================================================
			// Token strategy with validator callback
			// =================================================================

			describe("Token strategy with validator callback", function() {

				it("validates tokens via callback function", function() {
					var validatorFn = function(required string token) {
						if (arguments.token == "callback-token-ok") {
							return {id = 200, role = "callback_user"};
						}
						return false;
					};

					var callbackTokenStrategy = new wheels.auth.TokenStrategy(
						validator = validatorFn
					);

					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "callbackToken", strategy = callbackTokenStrategy);

					var req = {headers = {authorization = "Bearer callback-token-ok"}};
					var result = auth.authenticate(request = req);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(200);
					expect(result.principal.role).toBe("callback_user");
				});

				it("callback returning false rejects the token", function() {
					var validatorFn = function(required string token) {
						return false;
					};

					var callbackTokenStrategy = new wheels.auth.TokenStrategy(
						validator = validatorFn
					);

					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "callbackToken", strategy = callbackTokenStrategy);

					var req = {headers = {authorization = "Bearer any-token"}};
					var result = auth.authenticate(request = req);

					expect(result.success).toBeFalse();
				});

			});

			// =================================================================
			// End-to-end scenario: login, access protected route, logout
			// =================================================================

			describe("End-to-end session scenario", function() {

				it("full login-access-logout cycle through middleware", function() {
					var mw = new wheels.middleware.AuthMiddleware(authenticator = authenticator);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					// Step 1: No session → blocked
					var result1 = pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							return "OK";
						}
					);
					var parsed1 = DeserializeJSON(result1);
					expect(parsed1.status).toBe(401);

					// Step 2: Login
					sessionStrategy.login(principal = {id = 1, role = "admin", name = "Alice"});

					// Step 3: Access protected route → success
					var captured = {auth = {}};
					var result2 = pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							captured.auth = arguments.request.auth;
							return "protected-content";
						}
					);
					expect(result2).toBe("protected-content");
					expect(captured.auth.principal.name).toBe("Alice");

					// Step 4: Logout
					sessionStrategy.logout();

					// Step 5: Access protected route again → blocked
					var result3 = pipeline.run(
						request = {},
						coreHandler = function(required struct request) {
							return "should not reach";
						}
					);
					var parsed3 = DeserializeJSON(result3);
					expect(parsed3.status).toBe(401);
				});

			});

		});

	}

}
