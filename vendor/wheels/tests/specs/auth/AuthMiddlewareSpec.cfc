component extends="wheels.WheelsTest" {

	function run() {

		describe("AuthMiddleware", function() {

			beforeEach(function() {
				auth = new wheels.auth.Authenticator();
				passStrategy = new wheels.tests._assets.auth.AlwaysPassStrategy();
				failStrategy = new wheels.tests._assets.auth.AlwaysFailStrategy();
			});

			describe("Successful authentication", function() {

				it("calls next when authentication succeeds", function() {
					auth.registerStrategy(name = "pass", strategy = passStrategy);
					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var reqData = {};
					var result = pipeline.run(request = reqData, coreHandler = function(required struct request) {
						return "OK";
					});

					expect(result).toBe("OK");
				});

				it("attaches auth result to request context", function() {
					auth.registerStrategy(name = "pass", strategy = passStrategy);
					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var reqData = {};
					var captured = {auth = {}};

					pipeline.run(request = reqData, coreHandler = function(required struct request) {
						captured.auth = arguments.request.auth;
						return "OK";
					});

					expect(captured.auth.success).toBeTrue();
					expect(captured.auth.principal.id).toBe(1);
					expect(captured.auth.strategy).toBe("alwaysPass");
				});

			});

			describe("Failed authentication", function() {

				it("short-circuits pipeline on failure", function() {
					auth.registerStrategy(name = "fail", strategy = failStrategy);
					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var reqData = {};
					var handlerCalled = {value = false};

					var result = pipeline.run(request = reqData, coreHandler = function(required struct request) {
						handlerCalled.value = true;
						return "should not reach";
					});

					expect(handlerCalled.value).toBeFalse();
				});

				it("returns JSON error on failure", function() {
					auth.registerStrategy(name = "fail", strategy = failStrategy);
					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "nope";
					});

					var parsed = DeserializeJSON(result);
					expect(parsed.error).toBe("Invalid credentials");
					expect(parsed.status).toBe(401);
				});

				it("returns 403 status when strategy returns forbidden", function() {
					var forbiddenStrategy = new wheels.tests._assets.auth.AlwaysFailStrategy(
						name = "forbidden",
						error = "Insufficient permissions",
						statusCode = 403
					);
					auth.registerStrategy(name = "forbidden", strategy = forbiddenStrategy);
					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "nope";
					});

					var parsed = DeserializeJSON(result);
					expect(parsed.status).toBe(403);
					expect(parsed.error).toBe("Insufficient permissions");
				});

			});

			describe("Strategy restriction", function() {

				it("only tries the specified strategies", function() {
					auth.registerStrategy(name = "pass", strategy = passStrategy);
					auth.registerStrategy(name = "fail", strategy = failStrategy);

					// Restrict to only the "fail" strategy — should not try "pass"
					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						strategies = "fail"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "should not reach";
					});

					var parsed = DeserializeJSON(result);
					expect(parsed.status).toBe(401);
				});

				it("succeeds when restricted strategy passes", function() {
					auth.registerStrategy(name = "fail", strategy = failStrategy);
					auth.registerStrategy(name = "pass", strategy = passStrategy);

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						strategies = "pass"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "OK";
					});

					expect(result).toBe("OK");
				});

				it("accepts strategies as an array", function() {
					auth.registerStrategy(name = "pass", strategy = passStrategy);

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						strategies = ["pass"]
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "OK";
					});

					expect(result).toBe("OK");
				});

				it("tries multiple restricted strategies in order", function() {
					auth.registerStrategy(name = "fail", strategy = failStrategy);
					auth.registerStrategy(name = "pass", strategy = passStrategy);

					// List both — fail first, then pass should succeed
					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						strategies = "fail,pass"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {strategy = ""};
					pipeline.run(request = {}, coreHandler = function(required struct request) {
						captured.strategy = arguments.request.auth.strategy;
						return "OK";
					});

					expect(captured.strategy).toBe("alwaysPass");
				});

				it("skips strategies not registered in authenticator", function() {
					auth.registerStrategy(name = "pass", strategy = passStrategy);

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						strategies = "nonexistent,pass"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "OK";
					});

					expect(result).toBe("OK");
				});

				it("skips strategies that do not support the request", function() {
					var unsupported = new wheels.tests._assets.auth.UnsupportedStrategy();
					auth.registerStrategy(name = "unsupported", strategy = unsupported);
					auth.registerStrategy(name = "pass", strategy = passStrategy);

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						strategies = "unsupported,pass"
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "OK";
					});

					expect(result).toBe("OK");
				});

			});

			describe("allowAnonymous mode", function() {

				it("proceeds to next middleware even on failure", function() {
					auth.registerStrategy(name = "fail", strategy = failStrategy);

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						allowAnonymous = true
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "reached";
					});

					expect(result).toBe("reached");
				});

				it("attaches failed auth result to request when anonymous", function() {
					auth.registerStrategy(name = "fail", strategy = failStrategy);

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						allowAnonymous = true
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {auth = {}};
					pipeline.run(request = {}, coreHandler = function(required struct request) {
						captured.auth = arguments.request.auth;
						return "OK";
					});

					expect(captured.auth.success).toBeFalse();
					expect(captured.auth.error).toBe("Invalid credentials");
				});

				it("attaches successful auth result when user is authenticated", function() {
					auth.registerStrategy(name = "pass", strategy = passStrategy);

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						allowAnonymous = true
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {auth = {}};
					pipeline.run(request = {}, coreHandler = function(required struct request) {
						captured.auth = arguments.request.auth;
						return "OK";
					});

					expect(captured.auth.success).toBeTrue();
					expect(captured.auth.principal.id).toBe(1);
				});

			});

			describe("Custom failure handler", function() {

				it("invokes onFailure callback instead of default response", function() {
					auth.registerStrategy(name = "fail", strategy = failStrategy);

					var mw = new wheels.middleware.AuthMiddleware(
						authenticator = auth,
						onFailure = function(request, authResult) {
							return "CUSTOM:" & authResult.statusCode;
						}
					);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "nope";
					});

					expect(result).toBe("CUSTOM:401");
				});

			});

			describe("Authenticator resolution", function() {

				it("throws when no authenticator is available", function() {
					// No authenticator passed, no application scope authenticator
					var savedWheels = {};
					var hasWheelsKey = false;
					if (StructKeyExists(application, "$wheels") && StructKeyExists(application.$wheels, "authenticator")) {
						savedWheels = application.$wheels.authenticator;
						hasWheelsKey = true;
						StructDelete(application.$wheels, "authenticator");
					}

					try {
						var mw = new wheels.middleware.AuthMiddleware();
						var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

						expect(function() {
							pipeline.run(request = {}, coreHandler = function(required struct request) {
								return "nope";
							});
						}).toThrow("Wheels.Auth.NoAuthenticator");
					} finally {
						// Restore
						if (hasWheelsKey) {
							application.$wheels.authenticator = savedWheels;
						}
					}
				});

				it("resolves authenticator from application.$wheels scope", function() {
					var scopeAuth = new wheels.auth.Authenticator();
					scopeAuth.registerStrategy(name = "pass", strategy = passStrategy);

					// Temporarily inject into application scope
					var hadKey = StructKeyExists(application, "$wheels") && StructKeyExists(application.$wheels, "authenticator");
					var savedValue = "";
					if (hadKey) {
						savedValue = application.$wheels.authenticator;
					}
					if (!StructKeyExists(application, "$wheels")) {
						application["$wheels"] = {};
					}
					application.$wheels.authenticator = scopeAuth;

					try {
						var mw = new wheels.middleware.AuthMiddleware();
						var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

						var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
							return "resolved";
						});

						expect(result).toBe("resolved");
					} finally {
						if (hadKey) {
							application.$wheels.authenticator = savedValue;
						} else {
							StructDelete(application.$wheels, "authenticator");
						}
					}
				});

			});

			describe("Pipeline integration", function() {

				it("works with other middleware in the pipeline", function() {
					auth.registerStrategy(name = "pass", strategy = passStrategy);
					var authMw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var traceMw = new wheels.tests._assets.middleware.TestMiddlewareA();

					var pipeline = new wheels.middleware.Pipeline(middleware = [traceMw, authMw]);

					var captured = {trace = [], auth = {}};
					pipeline.run(request = {}, coreHandler = function(required struct request) {
						captured.trace = StructKeyExists(arguments.request, "trace") ? arguments.request.trace : [];
						captured.auth = arguments.request.auth;
						return "OK";
					});

					// TestMiddlewareA adds "A" to trace
					expect(captured.trace).toHaveLength(1);
					expect(captured.trace[1]).toBe("A");
					// Auth was attached
					expect(captured.auth.success).toBeTrue();
				});

				it("short-circuits before reaching later middleware", function() {
					auth.registerStrategy(name = "fail", strategy = failStrategy);
					var authMw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var traceMw = new wheels.tests._assets.middleware.TestMiddlewareA();

					// Auth first, trace second — trace should not run on failure
					var pipeline = new wheels.middleware.Pipeline(middleware = [authMw, traceMw]);

					var handlerCalled = {value = false};
					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						handlerCalled.value = true;
						return "nope";
					});

					expect(handlerCalled.value).toBeFalse();
					var parsed = DeserializeJSON(result);
					expect(parsed.status).toBe(401);
				});

			});

			describe("No registered strategies", function() {

				it("fails when authenticator has no strategies", function() {
					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "nope";
					});

					var parsed = DeserializeJSON(result);
					expect(parsed.status).toBe(401);
					expect(parsed.error).toInclude("No authentication strategy");
				});

			});

		});

	}

}
