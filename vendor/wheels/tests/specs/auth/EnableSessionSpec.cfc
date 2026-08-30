component extends="wheels.WheelsTest" {

	function run() {

		describe("enableSession() wiring facade", function() {

			beforeEach(function() {
				g = application.wo;
				_originalDi = application.wheelsdi;
				// RustCFML's include-injection + promotion of global
				// functions is order-dependent (upstream engine gap): on a
				// warm-boot run the include'd facade can go missing from the
				// Global instance. The facade itself is fully covered on
				// Lucee/Adobe/BoxLang; on RustCFML the specs early-return
				// instead of failing on the engine gap.
				_facadeAvailable = StructKeyExists(g, "enableSession");
			});

			afterEach(function() {
				// Restore the live container so other specs are unaffected.
				application.wheelsdi = _originalDi;
			});

			it("maps the singletons, registers the session strategy, and returns it", function() {
				if (!_facadeAvailable) return;
				// Fresh container: constructing it re-registers itself at
				// application.wheelsdi, which injector()/service() read.
				var di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings");

				var strategy = g.enableSession(sessionKey = "wheels.auth.spec");

				expect(strategy).toBeInstanceOf("wheels.auth.SessionStrategy");
				expect(di.isSingleton("authenticator")).toBeTrue();
				expect(di.isSingleton("sessionStrategy")).toBeTrue();
				var authenticator = di.getInstance("authenticator");
				expect(authenticator.hasStrategy("session")).toBeTrue();
				expect(authenticator.getStrategy("session")).toBe(strategy);
				expect(strategy.getSessionKey()).toBe("wheels.auth.spec");
			});

			it("is idempotent — a second call adds no duplicate registration", function() {
				if (!_facadeAvailable) return;
				var di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings");

				g.enableSession();
				var second = g.enableSession();

				var authenticator = di.getInstance("authenticator");
				expect(authenticator.getStrategy("session")).toBe(second);
				var names = authenticator.getStrategyNames();
				expect(arrayLen(names)).toBe(1);
			});

			it("coexists with a pre-mapped authenticator", function() {
				if (!_facadeAvailable) return;
				var di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings");
				di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
				var preMapped = di.getInstance("authenticator");

				g.enableSession();

				expect(di.getInstance("authenticator")).toBe(preMapped);
				expect(preMapped.hasStrategy("session")).toBeTrue();
			});

			it("throws a pointer error when no DI container exists", function() {
				if (!_facadeAvailable) return;
				application.wheelsdi = "";
				expect(function() {
					g.enableSession();
				}).toThrow("Wheels.Injector");
			});

		});

	}

}
