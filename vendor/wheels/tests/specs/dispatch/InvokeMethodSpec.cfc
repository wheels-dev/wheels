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
				// End-to-end shape of the dispatch flow at Dispatch.cfc:419.
				// We don't actually serve a request — we just verify the
				// adapter can invoke a Public.cfc handler. index() calls
				// $blockInProduction() first (Public.cfc ~376). In development
				// that gate is a no-op (allowlist since #2903); outside
				// development it 404s and aborts. Force development for the
				// invoke so a testing-env suite does not abort the runner.
				var priorEnv = application.wheels.environment;
				var publicCfc = createObject("component", "wheels.Public").$init();
				var adapter = application.wheels.engineAdapter;
				var receiverLossMessage = "";
				var indexReturn = "not-invoked";

				try {
					application.wheels.environment = "development";
					// index() renders the congratulations welcome page via
					// cfinclude. Capture that output so it doesn't leak into the
					// test-runner response buffer: on Adobe CF the leaked HTML
					// commits the servlet response (HTTP 404 + ~1MB prefix),
					// corrupting the JSON result for the ENTIRE suite.
					cfsavecontent(variable = "local.discardedIndexOutput") {
						indexReturn = publicCfc.index();
					}
					cfsavecontent(variable = "local.discardedInvokeOutput") {
						adapter.invokeMethod(publicCfc, "index");
					}
				} catch (any e) {
					// index() calls $blockInProduction as a development-only
					// no-op here. A "Function [$...] not found" error is the
					// receiver-loss signature from #2646. Any other error
					// (missing view path or template) is unrelated.
					if (REFindNoCase("Function \[\$[a-zA-Z]", e.message)) {
						receiverLossMessage = e.message;
					}
				} finally {
					application.wheels.environment = priorEnv;
				}

				expect(receiverLossMessage).toBe(
					"",
					"Receiver-loss error thrown from Public.cfc::index: " & receiverLossMessage
				);
				expect(indexReturn).toBe("");
			});

			it("S4: $shouldBlockInProduction is true in production", function() {
				var priorEnv = application.wheels.environment;
				var publicCfc = createObject("component", "wheels.Public").$init();
				try {
					application.wheels.environment = "production";
					expect(publicCfc.$shouldBlockInProduction()).toBeTrue();
				} finally {
					application.wheels.environment = priorEnv;
				}
			});

			it("S9: Public.cfc index() calls $blockInProduction", function() {
				var source = FileRead(ExpandPath("/wheels/Public.cfc"));
				var indexPos = ReFindNoCase("function\s+index\s*\(", source);
				expect(indexPos).toBeGT(0);
				var afterIndex = Mid(source, indexPos, 400);
				var blockPos = Find("$blockInProduction()", afterIndex);
				var includePos = Find("congratulations.cfm", afterIndex);
				expect(blockPos).toBeGT(0);
				expect(includePos).toBeGT(blockPos);
			});

		});

	}

}
