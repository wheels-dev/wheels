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

			it("asSingleton flags the just-mapped key when the container already has 20+ mappings (H1 at scale — real-world repro)", () => {
				// Real bug from full-app reproduction (2026-04-29 fresh-VM journal):
				// services.cfm calls .map("authenticator").to(...).asSingleton() on
				// an Injector that already has 20 framework bindings registered.
				// $findLastMappingKey walks variables.mappings via for-in, but Lucee 7's
				// HashMap-backed struct returns keys in HASH-BUCKET order (not insertion
				// order) once enough keys are registered to span multiple buckets. The
				// just-added key ends up in the middle of iteration, so $findLastMappingKey
				// returns the wrong key and asSingleton flags an unrelated binding.
				//
				// Pre-fix observed behavior: with 20 framework bindings + "authenticator"
				// added last, iteration ended on "global" — so singletonFlags["global"]
				// was set instead of singletonFlags["authenticator"].

				// Register 20 simple mappings to reach the scale where the bug surfaces.
				// (Counts to match wheels.Bindings — 20 framework bindings.)
				di.map("svc01").to("wheels.tests._assets.di.SimpleService");
				di.map("svc02").to("wheels.tests._assets.di.SimpleService");
				di.map("svc03").to("wheels.tests._assets.di.SimpleService");
				di.map("svc04").to("wheels.tests._assets.di.SimpleService");
				di.map("svc05").to("wheels.tests._assets.di.SimpleService");
				di.map("svc06").to("wheels.tests._assets.di.SimpleService");
				di.map("svc07").to("wheels.tests._assets.di.SimpleService");
				di.map("svc08").to("wheels.tests._assets.di.SimpleService");
				di.map("svc09").to("wheels.tests._assets.di.SimpleService");
				di.map("svc10").to("wheels.tests._assets.di.SimpleService");
				di.map("svc11").to("wheels.tests._assets.di.SimpleService");
				di.map("svc12").to("wheels.tests._assets.di.SimpleService");
				di.map("svc13").to("wheels.tests._assets.di.SimpleService");
				di.map("svc14").to("wheels.tests._assets.di.SimpleService");
				di.map("svc15").to("wheels.tests._assets.di.SimpleService");
				di.map("svc16").to("wheels.tests._assets.di.SimpleService");
				di.map("svc17").to("wheels.tests._assets.di.SimpleService");
				di.map("svc18").to("wheels.tests._assets.di.SimpleService");
				di.map("svc19").to("wheels.tests._assets.di.SimpleService");
				di.map("svc20").to("wheels.tests._assets.di.SimpleService");

				// Now register the user's binding. THIS is the one that should be flagged.
				di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();

				// The flag must land on the just-mapped key, regardless of how many
				// keys preceded it.
				expect(di.isSingleton("authenticator")).toBeTrue();

				// And resolving must return the same instance twice.
				var first = di.getInstance("authenticator");
				var second = di.getInstance("authenticator");
				expect(first).toBe(second);
			});

			it("asSingleton flags the just-mapped key, not the iteration-last key (regression for the at-scale bug)", () => {
				// Tighter version of the at-scale test: registers TWO bindings without
				// asSingleton, then a third WITH asSingleton, and asserts the flag
				// landed on the third — not the iteration-last one. This is the
				// minimal failure for the bug if Lucee's iteration order doesn't
				// match insertion order.
				di.map("first").to("wheels.tests._assets.di.SimpleService");
				di.map("second").to("wheels.tests._assets.di.SimpleService").asSingleton();
				di.map("third").to("wheels.tests._assets.di.SimpleService");

				expect(di.isSingleton("first")).toBeFalse();
				expect(di.isSingleton("second")).toBeTrue();
				expect(di.isSingleton("third")).toBeFalse();
			});

		});

	}

}
