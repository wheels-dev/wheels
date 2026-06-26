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
				// adapter can invoke a Public.cfc handler. In the development
				// environment $blockInProduction() short-circuits to a no-op
				// (since #2903 the gate is a development-only allowlist), so
				// the only thing we're testing is "did the receiver survive
				// the dispatch?" If it didn't, the call throws before the
				// include statement runs. (This spec invokes index(), which now
				// calls $blockInProduction() too (a development-only no-op per
				// the allowlist), so the production-only early-return below is
				// belt-and-suspenders.)
				if (
					StructKeyExists(application, "wheels")
					&& StructKeyExists(application.wheels, "environment")
					&& application.wheels.environment == "production"
				) {
					return;
				}

				var publicCfc = createObject("component", "wheels.Public").$init();
				var adapter = application.wheels.engineAdapter;
				var receiverLossMessage = "";

				try {
					// index() renders the congratulations welcome page via
					// cfinclude. Capture that output so it doesn't leak into the
					// test-runner response buffer: on Adobe CF the leaked HTML
					// commits the servlet response (HTTP 404 + ~1MB prefix),
					// corrupting the JSON result for the ENTIRE suite. We only
					// care that the dispatch invocation survives without a
					// receiver-loss error, not what index() prints.
					cfsavecontent(variable = "local.discardedIndexOutput") {
						adapter.invokeMethod(publicCfc, "index");
					}
				} catch (any e) {
					// index() doesn't call $blockInProduction so this should
					// never throw a "Function [$...] not found" error. Any
					// other error (e.g. missing view path or template) is
					// unrelated — match only the receiver-loss signature so
					// the captured message surfaces directly in the failure.
					if (REFindNoCase("Function \[\$[a-zA-Z]", e.message)) {
						receiverLossMessage = e.message;
					}
				}

				expect(receiverLossMessage).toBe(
					"",
					"Receiver-loss error thrown from Public.cfc::index: " & receiverLossMessage
				);
			});

		});

	}

}
