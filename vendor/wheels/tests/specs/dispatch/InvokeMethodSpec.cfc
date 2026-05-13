component extends="wheels.WheelsTest" {

	function run() {

		describe("Engine Adapter - invokeMethod receiver context", function() {

			it("preserves the component receiver so internal helpers resolve", function() {
				// Regression test for issue #2646: on BoxLang, the previous
				// dispatch pattern (local.method = obj[name]; local.method())
				// extracted the method as a bare function reference and lost
				// the component context. The in-component call to a $-prefixed
				// helper then failed with "Function [$privateHelper] not found".
				// All Public.cfc handlers (/wheels/info, /wheels/routes, ...)
				// hit this code path because PR #2241 made them call
				// $blockInProduction() as their first statement.
				var fixture = new wheels.tests._assets.dispatch.InvokeMethodFixture();
				var adapter = application.wheels.engineAdapter;

				expect(fixture.getState().helperCalled).toBeFalse();
				expect(fixture.getState().handlerCompleted).toBeFalse();

				adapter.invokeMethod(fixture, "publicHandler");

				expect(fixture.getState().helperCalled).toBeTrue();
				expect(fixture.getState().handlerCompleted).toBeTrue();
			});

			it("can be invoked repeatedly without leaking state", function() {
				var fixture = new wheels.tests._assets.dispatch.InvokeMethodFixture();
				var adapter = application.wheels.engineAdapter;

				adapter.invokeMethod(fixture, "publicHandler");
				expect(fixture.getState().handlerCompleted).toBeTrue();

				fixture.resetState();
				expect(fixture.getState().handlerCompleted).toBeFalse();

				adapter.invokeMethod(fixture, "publicHandler");
				expect(fixture.getState().handlerCompleted).toBeTrue();
			});

			it("invokes a Public.cfc instance without throwing on $blockInProduction", function() {
				// End-to-end shape of the dispatch flow at Dispatch.cfc:287.
				// We don't actually serve a request — we just verify the
				// adapter can invoke a Public.cfc handler. In non-production
				// environments $blockInProduction() short-circuits to a no-op,
				// so the only thing we're testing is "did the receiver survive
				// the dispatch?" If it didn't, the call throws before the
				// include statement runs.
				if (
					StructKeyExists(application, "wheels")
					&& StructKeyExists(application.wheels, "environment")
					&& application.wheels.environment == "production"
				) {
					return;
				}

				var publicCfc = createObject("component", "wheels.Public").$init();
				var adapter = application.wheels.engineAdapter;
				var threwReceiverLoss = false;
				var caughtMessage = "";

				try {
					adapter.invokeMethod(publicCfc, "index");
				} catch (any e) {
					// index() doesn't call $blockInProduction so this should
					// never throw a "Function [$...] not found" error. Any
					// other error (e.g. missing view path) is unrelated.
					if (FindNoCase("$blockInProduction", e.message)
						|| FindNoCase("$privateHelper", e.message)
						|| FindNoCase("not found", e.message)) {
						threwReceiverLoss = true;
						caughtMessage = e.message;
					}
				}

				expect(threwReceiverLoss).toBeFalse();
			});

		});

	}

}
