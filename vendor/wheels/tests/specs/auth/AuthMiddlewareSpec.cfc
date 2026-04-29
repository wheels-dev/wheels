component extends="wheels.WheelsTest" {

	function run() {

		describe("AuthMiddleware", function() {

			describe("Successful authentication", function() {

				it("calls next when authentication succeeds", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var reqData = {};
					var result = pipeline.run(request = reqData, coreHandler = function(required struct request) {
						return "OK";
					});

					expect(result).toBe("OK");
				});

				it("attaches auth result to request context", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

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
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());

					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var handlerCalled = {value = false};
					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						handlerCalled.value = true;
						return "should not reach";
					});

					expect(handlerCalled.value).toBeFalse();
				});

				it("returns JSON error on failure", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());

					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "nope";
					});

					var parsed = DeserializeJSON(result);
					expect(parsed.error).toBe("Invalid credentials");
					expect(parsed.status).toBe(401);
				});

			});

			describe("Strategy restriction", function() {

				it("only tries the specified strategies", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());

					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth, strategies = "fail");
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "should not reach";
					});

					var parsed = DeserializeJSON(result);
					expect(parsed.status).toBe(401);
				});

				it("succeeds when restricted strategy passes", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth, strategies = "pass");
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "OK";
					});

					expect(result).toBe("OK");
				});

				it("tries multiple restricted strategies in order", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth, strategies = "fail,pass");
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {strategy = ""};
					pipeline.run(request = {}, coreHandler = function(required struct request) {
						captured.strategy = arguments.request.auth.strategy;
						return "OK";
					});

					expect(captured.strategy).toBe("alwaysPass");
				});

				it("skips unregistered strategies gracefully", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth, strategies = "nonexistent,pass");
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "OK";
					});

					expect(result).toBe("OK");
				});

			});

			describe("allowAnonymous mode", function() {

				it("proceeds to next middleware even on failure", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());

					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth, allowAnonymous = true);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "reached";
					});

					expect(result).toBe("reached");
				});

				it("attaches failed auth result when anonymous", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());

					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth, allowAnonymous = true);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var captured = {auth = {}};
					pipeline.run(request = {}, coreHandler = function(required struct request) {
						captured.auth = arguments.request.auth;
						return "OK";
					});

					expect(captured.auth.success).toBeFalse();
					expect(captured.auth.error).toBe("Invalid credentials");
				});

			});

			describe("Custom failure handler", function() {

				it("invokes onFailure callback", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());

					var customHandler = function(request, authResult) {
						return "CUSTOM:" & authResult.statusCode;
					};
					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth, onFailure = customHandler);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "nope";
					});

					expect(result).toBe("CUSTOM:401");
				});

			});

			describe("Authenticator resolution", function() {

				it("throws when no authenticator is available", function() {
					var savedValue = "";
					var hadKey = false;
					if (StructKeyExists(application, "$wheels") && StructKeyExists(application.$wheels, "authenticator")) {
						savedValue = application.$wheels.authenticator;
						hadKey = true;
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
						if (hadKey) {
							application.$wheels.authenticator = savedValue;
						}
					}
				});

			});

			describe("Pipeline integration", function() {

				it("works with other middleware in the pipeline", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());
					var authMw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var traceMw = new wheels.tests._assets.middleware.TestMiddlewareA();

					var pipeline = new wheels.middleware.Pipeline(middleware = [traceMw, authMw]);

					var captured = {trace = [], authOk = false};
					pipeline.run(request = {}, coreHandler = function(required struct request) {
						if (StructKeyExists(arguments.request, "trace")) {
							captured.trace = arguments.request.trace;
						}
						captured.authOk = arguments.request.auth.success;
						return "OK";
					});

					expect(captured.trace).toHaveLength(1);
					expect(captured.trace[1]).toBe("A");
					expect(captured.authOk).toBeTrue();
				});

				it("short-circuits before reaching later middleware", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());
					var authMw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var traceMw = new wheels.tests._assets.middleware.TestMiddlewareA();

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

				it("fails with a diagnostic message when authenticator has no strategies", function() {
					var auth = new wheels.auth.Authenticator();
					var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
					var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

					var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "nope";
					});

					var parsed = DeserializeJSON(result);
					expect(parsed.status).toBe(401);
					expect(parsed.error).toInclude("No authentication strategies registered");
				});

			});

		});

	}

}
