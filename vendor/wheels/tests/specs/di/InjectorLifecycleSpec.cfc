component extends="wheels.WheelsTest" {

	function run() {

		describe("Injector lifecycle — singleton survival", () => {

			beforeEach(() => {
				di = new wheels.Injector(binderPath="wheels.tests._assets.di.TestBindings");
			});

			it("auth Authenticator + SessionStrategy survive ServiceProvider re-registration (H1 broad repro)", () => {
				// Step A: First registration — what config/services.cfm does
				di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
				di.map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton();

				// Step B: Resolve and register a strategy — what app/events/onapplicationstart.cfm does
				var auth = di.getInstance("authenticator");
				var sessionStrategy = di.getInstance("sessionStrategy");
				auth.registerStrategy(name="session", strategy=sessionStrategy);

				expect(auth.getStrategyNames()).toBe(["session"]);

				// Step C: Simulate plugin/package reload — what $loadPlugins/$loadPackages does
				// on every dev-mode request. ServiceProviders call .map().to().asSingleton() again.
				di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
				di.map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton();

				// Step D: Resolve again — must return the SAME authenticator with strategies intact
				var authAgain = di.getInstance("authenticator");
				expect(authAgain).toBe(auth);
				expect(authAgain.getStrategyNames()).toBe(["session"]);
			});

			it("singleton flag survives a third-party mapping registered between (H1 focused)", () => {
				// Hypothesis H1: $findLastMappingKey returns the wrong key when a
				// service provider adds an unrelated mapping after the user's.
				di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();

				// A plugin's ServiceProvider registers an unrelated service AFTER ours.
				di.map("loggerService").to("wheels.tests._assets.di.SimpleService").asSingleton();

				// Now the user's authenticator should still be a singleton.
				expect(di.isSingleton("authenticator")).toBeTrue();
				expect(di.isSingleton("loggerService")).toBeTrue();

				var first = di.getInstance("authenticator");
				var second = di.getInstance("authenticator");
				expect(first).toBe(second);
			});

		});

	}

}
