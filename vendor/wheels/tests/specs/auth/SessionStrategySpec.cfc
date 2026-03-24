component extends="wheels.WheelsTest" {

	function run() {

		describe("SessionStrategy", function() {

			beforeEach(function() {
				// Clean slate: remove any test session data
				StructDelete(session, "wheels");
				StructDelete(session, "customAuth");
				strategy = new wheels.auth.SessionStrategy();
			});

			afterEach(function() {
				StructDelete(session, "wheels");
				StructDelete(session, "customAuth");
			});

			describe("getName()", function() {

				it("returns 'session'", function() {
					expect(strategy.getName()).toBe("session");
				});

			});

			describe("supports()", function() {

				it("returns false when no session data exists", function() {
					expect(strategy.supports(request = {})).toBeFalse();
				});

				it("returns true when session principal is populated", function() {
					session.wheels = {auth = {id = 1, role = "admin"}};
					expect(strategy.supports(request = {})).toBeTrue();
				});

				it("returns false when session key exists but is empty struct", function() {
					session.wheels = {auth = {}};
					expect(strategy.supports(request = {})).toBeFalse();
				});

			});

			describe("authenticate()", function() {

				it("returns success with the stored principal", function() {
					session.wheels = {auth = {id = 42, role = "editor"}};

					var result = strategy.authenticate(request = {});

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(42);
					expect(result.principal.role).toBe("editor");
					expect(result.strategy).toBe("session");
					expect(result.statusCode).toBe(200);
				});

				it("returns failure when no session exists", function() {
					var result = strategy.authenticate(request = {});

					expect(result.success).toBeFalse();
					expect(result.error).toBe("No active session");
					expect(result.statusCode).toBe(401);
					expect(result.strategy).toBe("session");
				});

				it("returns failure when session key holds an empty struct", function() {
					session.wheels = {auth = {}};

					var result = strategy.authenticate(request = {});
					expect(result.success).toBeFalse();
				});

			});

			describe("login()", function() {

				it("stores the principal in the session", function() {
					strategy.login(principal = {id = 7, role = "admin"});

					expect(session.wheels.auth.id).toBe(7);
					expect(session.wheels.auth.role).toBe("admin");
				});

				it("subsequent authenticate calls succeed after login", function() {
					strategy.login(principal = {id = 7, role = "user"});

					var result = strategy.authenticate(request = {});
					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(7);
				});

				it("invokes the onLogin callback", function() {
					var captured = {principal = {}};
					strategy = new wheels.auth.SessionStrategy(
						onLogin = function(p) { captured.principal = p; }
					);

					strategy.login(principal = {id = 99});
					expect(captured.principal.id).toBe(99);
				});

				it("creates intermediate session structs for nested keys", function() {
					strategy.login(principal = {id = 5});

					expect(StructKeyExists(session, "wheels")).toBeTrue();
					expect(StructKeyExists(session.wheels, "auth")).toBeTrue();
					expect(session.wheels.auth.id).toBe(5);
				});

			});

			describe("logout()", function() {

				it("clears the session principal", function() {
					strategy.login(principal = {id = 7});
					strategy.logout();

					expect(strategy.isLoggedIn()).toBeFalse();
				});

				it("authenticate fails after logout", function() {
					strategy.login(principal = {id = 7});
					strategy.logout();

					var result = strategy.authenticate(request = {});
					expect(result.success).toBeFalse();
				});

				it("invokes the onLogout callback", function() {
					var captured = {called = false};
					strategy = new wheels.auth.SessionStrategy(
						onLogout = function() { captured.called = true; }
					);

					strategy.login(principal = {id = 1});
					strategy.logout();
					expect(captured.called).toBeTrue();
				});

				it("is safe to call when not logged in", function() {
					// Should not throw
					strategy.logout();
					expect(strategy.isLoggedIn()).toBeFalse();
				});

			});

			describe("currentUser()", function() {

				it("returns empty struct when not logged in", function() {
					expect(StructIsEmpty(strategy.currentUser())).toBeTrue();
				});

				it("returns the principal when logged in", function() {
					strategy.login(principal = {id = 10, name = "Alice"});

					var user = strategy.currentUser();
					expect(user.id).toBe(10);
					expect(user.name).toBe("Alice");
				});

			});

			describe("isLoggedIn()", function() {

				it("returns false when not logged in", function() {
					expect(strategy.isLoggedIn()).toBeFalse();
				});

				it("returns true after login", function() {
					strategy.login(principal = {id = 1});
					expect(strategy.isLoggedIn()).toBeTrue();
				});

				it("returns false after logout", function() {
					strategy.login(principal = {id = 1});
					strategy.logout();
					expect(strategy.isLoggedIn()).toBeFalse();
				});

			});

			describe("Custom session key", function() {

				it("supports a flat session key", function() {
					strategy = new wheels.auth.SessionStrategy(sessionKey = "customAuth");

					strategy.login(principal = {id = 88});
					expect(session.customAuth.id).toBe(88);

					var result = strategy.authenticate(request = {});
					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(88);
				});

				it("supports a deeply nested session key", function() {
					strategy = new wheels.auth.SessionStrategy(sessionKey = "wheels.api.auth");
					StructDelete(session, "wheels");

					strategy.login(principal = {id = 33});
					expect(session.wheels.api.auth.id).toBe(33);

					var result = strategy.authenticate(request = {});
					expect(result.success).toBeTrue();
				});

				it("returns the configured key via getSessionKey()", function() {
					strategy = new wheels.auth.SessionStrategy(sessionKey = "myApp.session");
					expect(strategy.getSessionKey()).toBe("myApp.session");
				});

			});

			describe("Authenticator integration", function() {

				it("works as a registered strategy in the Authenticator", function() {
					strategy.login(principal = {id = 50, role = "admin"});

					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "session", strategy = strategy);

					var result = auth.authenticate(request = {});
					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(50);
					expect(result.strategy).toBe("session");
				});

				it("is skipped by the Authenticator when no session exists", function() {
					var auth = new wheels.auth.Authenticator();
					auth.registerStrategy(name = "session", strategy = strategy);
					auth.registerStrategy(
						name = "fallback",
						strategy = new wheels.tests._assets.auth.AlwaysPassStrategy(name = "fallback")
					);

					var result = auth.authenticate(request = {});
					// Session strategy doesn't support (no session), falls to fallback
					expect(result.success).toBeTrue();
					expect(result.strategy).toBe("fallback");
				});

			});

		});

	}

}
