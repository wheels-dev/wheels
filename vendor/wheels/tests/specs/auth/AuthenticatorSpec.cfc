component extends="wheels.WheelsTest" {

	function run() {

		describe("Authenticator", function() {

			beforeEach(function() {
				auth = new wheels.auth.Authenticator();
			});

			describe("Strategy registry", function() {

				it("starts with no strategies", function() {
					expect(auth.getStrategyNames()).toHaveLength(0);
					expect(auth.hasStrategy("token")).toBeFalse();
				});

				it("registers a strategy", function() {
					var s = new wheels.tests._assets.auth.AlwaysPassStrategy();
					auth.registerStrategy(name = "alwaysPass", strategy = s);

					expect(auth.hasStrategy("alwaysPass")).toBeTrue();
					expect(auth.getStrategyNames()).toHaveLength(1);
					expect(auth.getStrategyNames()[1]).toBe("alwaysPass");
				});

				it("registers multiple strategies and preserves order", function() {
					auth.registerStrategy(name = "first", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "first"));
					auth.registerStrategy(name = "second", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy(name = "second"));

					var names = auth.getStrategyNames();
					expect(names).toHaveLength(2);
					expect(names[1]).toBe("first");
					expect(names[2]).toBe("second");
				});

				it("replaces a strategy with the same name", function() {
					auth.registerStrategy(name = "test", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "test"));
					auth.registerStrategy(name = "test", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy(name = "test"));

					expect(auth.getStrategyNames()).toHaveLength(1);

					// The replacement should be the fail strategy
					var result = auth.authenticate(request = {});
					expect(result.success).toBeFalse();
				});

				it("removes a strategy", function() {
					auth.registerStrategy(name = "test", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());
					auth.removeStrategy("test");

					expect(auth.hasStrategy("test")).toBeFalse();
					expect(auth.getStrategyNames()).toHaveLength(0);
				});

				it("removing a non-existent strategy does not error", function() {
					auth.removeStrategy("nonexistent");
					expect(auth.getStrategyNames()).toHaveLength(0);
				});

				it("retrieves a strategy by name", function() {
					var s = new wheels.tests._assets.auth.AlwaysPassStrategy();
					auth.registerStrategy(name = "myStrategy", strategy = s);

					var retrieved = auth.getStrategy("myStrategy");
					expect(retrieved.getName()).toBe("alwaysPass");
				});

				it("throws when retrieving a non-existent strategy", function() {
					expect(function() {
						auth.getStrategy("missing");
					}).toThrow("Wheels.Auth.StrategyNotFound");
				});

			});

			describe("Authentication", function() {

				it("returns a diagnostic failure when no strategies are registered", function() {
					// Bug-driven: the previous generic "No authentication strategy
					// supports this request" was indistinguishable from the case
					// where strategies are registered but none claim the request.
					// A user wired up via services.cfm + onApplicationStart who hit
					// the DI singleton bug saw the same message they'd get for an
					// expired session — costing ~30 minutes of wrong-trail debugging.
					// The zero-strategies case now points at the wiring.
					var result = auth.authenticate(request = {});
					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
					expect(result.error).toInclude("No authentication strategies registered");
					expect(result.error).toInclude("registerStrategy");
				});

				it("returns the strategy-supports message when strategies are registered but none claim the request", function() {
					// Pins down the existing behavior so it doesn't collide with
					// the new no-strategies diagnostic. With at least one strategy
					// registered, the message stays generic.
					auth.registerStrategy(name = "unsupported", strategy = new wheels.tests._assets.auth.UnsupportedStrategy());

					var result = auth.authenticate(request = {});
					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
					expect(result.error).toBe("No authentication strategy supports this request");
				});

				it("returns success from the first supporting strategy that passes", function() {
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var result = auth.authenticate(request = {});
					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(1);
					expect(result.strategy).toBe("alwaysPass");
					expect(result.statusCode).toBe(200);
				});

				it("tries the next strategy when the first fails", function() {
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var result = auth.authenticate(request = {});
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("alwaysPass");
				});

				it("skips strategies that do not support the request", function() {
					auth.registerStrategy(name = "unsupported", strategy = new wheels.tests._assets.auth.UnsupportedStrategy());
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var result = auth.authenticate(request = {});
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("alwaysPass");
				});

				it("returns the last failure error when all strategies fail", function() {
					auth.registerStrategy(name = "fail1", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy(name = "fail1", error = "First error"));
					auth.registerStrategy(name = "fail2", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy(name = "fail2", error = "Second error"));

					var result = auth.authenticate(request = {});
					expect(result.success).toBeFalse();
					expect(result.error).toBe("Second error");
				});

				it("returns the last failure status code when all strategies fail", function() {
					auth.registerStrategy(name = "fail1", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy(name = "fail1", statusCode = 401));
					auth.registerStrategy(name = "fail2", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy(name = "fail2", statusCode = 403));

					var result = auth.authenticate(request = {});
					expect(result.statusCode).toBe(403);
				});

			});

			describe("Restricted authentication (authenticateWith)", function() {

				it("tries only the named strategies", function() {
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());

					var result = auth.authenticateWith(request = {}, strategies = "fail");
					expect(result.success).toBeFalse();
					expect(result.error).toBe("Invalid credentials");
				});

				it("accepts an array of strategy names", function() {
					auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var result = auth.authenticateWith(request = {}, strategies = ["pass"]);
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("alwaysPass");
				});

				it("skips unknown names when a registered strategy can still authenticate", function() {
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var result = auth.authenticateWith(request = {}, strategies = "ghost,pass");
					expect(result.success).toBeTrue();
				});

				it("surfaces a wiring diagnostic when restricted to only unregistered names", function() {
					auth.registerStrategy(name = "token", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var result = auth.authenticateWith(request = {}, strategies = "tokn");
					expect(result.success).toBeFalse();
					expect(result.statusCode).toBe(401);
					expect(result.error).toInclude("tokn");
					expect(result.error).toInclude("Registered strategies: token");
				});

				it("returns the zero-strategies diagnostic when nothing is registered", function() {
					var result = auth.authenticateWith(request = {}, strategies = "token");
					expect(result.success).toBeFalse();
					expect(result.error).toInclude("No authentication strategies registered");
				});

				it("behaves like authenticate() when the filter is empty", function() {
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var result = auth.authenticateWith(request = {}, strategies = "");
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("alwaysPass");
				});

			});

			describe("Header token strategy integration", function() {

				it("authenticates with a valid Bearer token", function() {
					auth.registerStrategy(name = "token", strategy = new wheels.tests._assets.auth.HeaderTokenStrategy(validToken = "abc-xyz"));

					var reqData = {headers = {authorization = "Bearer abc-xyz"}};
					var result = auth.authenticate(request = reqData);

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(42);
					expect(result.strategy).toBe("headerToken");
				});

				it("fails with an invalid token", function() {
					auth.registerStrategy(name = "token", strategy = new wheels.tests._assets.auth.HeaderTokenStrategy(validToken = "abc-xyz"));

					var reqData = {headers = {authorization = "Bearer wrong-token"}};
					var result = auth.authenticate(request = reqData);

					expect(result.success).toBeFalse();
					expect(result.error).toBe("Invalid token");
				});

				it("skips token strategy when no Authorization header present", function() {
					auth.registerStrategy(name = "token", strategy = new wheels.tests._assets.auth.HeaderTokenStrategy());
					auth.registerStrategy(name = "fallback", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "fallback"));

					var reqData = {headers = {}};
					var result = auth.authenticate(request = reqData);

					// Token strategy doesn't support this request, falls through to fallback
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("fallback");
				});

			});

			describe("Default strategy", function() {

				it("tries the default strategy first", function() {
					auth = new wheels.auth.Authenticator(defaultStrategy = "second");
					auth.registerStrategy(name = "first", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "first"));
					auth.registerStrategy(name = "second", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "second"));

					var result = auth.authenticate(request = {});
					// Default "second" should be tried before "first"
					expect(result.strategy).toBe("second");
				});

				it("falls back to other strategies if default does not support", function() {
					auth = new wheels.auth.Authenticator(defaultStrategy = "unsupported");
					auth.registerStrategy(name = "unsupported", strategy = new wheels.tests._assets.auth.UnsupportedStrategy());
					auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

					var result = auth.authenticate(request = {});
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("alwaysPass");
				});

				it("setDefaultStrategy changes the default", function() {
					auth.registerStrategy(name = "first", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "first"));
					auth.registerStrategy(name = "second", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "second"));
					auth.setDefaultStrategy("second");

					var result = auth.authenticate(request = {});
					expect(result.strategy).toBe("second");
					expect(auth.getDefaultStrategy()).toBe("second");
				});

			});

			describe("Constructor with strategies array", function() {

				it("registers strategies passed at construction", function() {
					var strategies = [
						new wheels.tests._assets.auth.AlwaysPassStrategy(name = "pass"),
						new wheels.tests._assets.auth.AlwaysFailStrategy(name = "fail")
					];
					auth = new wheels.auth.Authenticator(strategies = strategies);

					expect(auth.getStrategyNames()).toHaveLength(2);
					expect(auth.hasStrategy("pass")).toBeTrue();
					expect(auth.hasStrategy("fail")).toBeTrue();
				});

			});

			describe("Fluent registration", function() {

				it("supports chained registerStrategy calls", function() {
					auth
						.registerStrategy(name = "a", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "a"))
						.registerStrategy(name = "b", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy(name = "b"));

					expect(auth.getStrategyNames()).toHaveLength(2);
				});

			});

		});

	}

}
