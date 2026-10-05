/**
 * AuthMiddleware finds the authenticator that `wheels generate auth` and enableSession()
 * register in the DI container, so the documented `new AuthMiddleware(strategies=...)`
 * form works without passing one. Its default 401 body keeps lowercase keys.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("AuthMiddleware authenticator from the DI container", function() {

			beforeEach(function() {
				_originalDi = application.wheelsdi;
				_saved = {dollar = false, dollarValue = "", plain = false, plainValue = ""};
				if (StructKeyExists(application, "$wheels") && StructKeyExists(application.$wheels, "authenticator")) {
					_saved.dollar = true;
					_saved.dollarValue = application.$wheels.authenticator;
					StructDelete(application.$wheels, "authenticator");
				}
				if (StructKeyExists(application.wheels, "authenticator")) {
					_saved.plain = true;
					_saved.plainValue = application.wheels.authenticator;
					StructDelete(application.wheels, "authenticator");
				}
			});

			afterEach(function() {
				application.wheelsdi = _originalDi;
				if (_saved.dollar) {
					application.$wheels.authenticator = _saved.dollarValue;
				}
				if (_saved.plain) {
					application.wheels.authenticator = _saved.plainValue;
				}
			});

			it("uses the container's authenticator when none is passed", function() {
				// Constructing an Injector registers it at application.wheelsdi.
				var di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings");
				di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
				var auth = di.getInstance("authenticator");
				auth.registerStrategy(name = "pass", strategy = new wheels.tests._assets.auth.AlwaysPassStrategy());

				var mw = new wheels.middleware.AuthMiddleware(strategies = "pass");
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var captured = {auth = {}};
				var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
					captured.auth = arguments.request.auth;
					return "OK";
				});

				expect(result).toBe("OK");
				expect(captured.auth.success).toBeTrue();
				expect(captured.auth.principal.id).toBe(1);
			});

			it("still throws when the container has no authenticator either", function() {
				var di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings");
				var mw = new wheels.middleware.AuthMiddleware();
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

				expect(function() {
					pipeline.run(request = {}, coreHandler = function(required struct request) {
						return "nope";
					});
				}).toThrow("Wheels.Auth.NoAuthenticator");
			});

		});

		describe("AuthMiddleware default 401 body", function() {

			it("keeps the keys lowercase", function() {
				var auth = new wheels.auth.Authenticator();
				auth.registerStrategy(name = "fail", strategy = new wheels.tests._assets.auth.AlwaysFailStrategy());
				var mw = new wheels.middleware.AuthMiddleware(authenticator = auth);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);
				var result = pipeline.run(request = {}, coreHandler = function(required struct request) {
					return "should-not-reach";
				});

				// Find() is case-sensitive.
				expect(Find('"error"', result)).toBeGT(0, result);
				expect(Find('"status"', result)).toBeGT(0, result);
				expect(Find('"ERROR"', result)).toBe(0, result);
				expect(Find('"STATUS"', result)).toBe(0, result);
			});

		});

	}

}
