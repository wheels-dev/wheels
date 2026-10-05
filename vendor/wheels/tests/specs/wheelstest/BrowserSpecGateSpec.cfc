/**
 * A browser spec that did not run never reads as a pass: browserDescribe() asks
 * $browserSpecGate() whether to run it, skip it (reported as Skipped, with the
 * reason) or fail it (reported as an Error, when the browser could not start).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("BrowserTest $browserSpecGate()", () => {

			it("runs browser specs when the browser started", () => {
				var bundle = new wheels.wheelstest.BrowserTest();
				var gate = bundle.$browserSpecGate();
				expect(gate.action).toBe("run");
			});

			it("skips browser specs with the reason when they cannot run here", () => {
				var bundle = new wheels.wheelstest.BrowserTest();
				bundle.$skipBrowserSpecs("Playwright is not installed. Run `wheels browser setup` to run browser specs.");
				var gate = bundle.$browserSpecGate();
				expect(gate.action).toBe("skip");
				expect(gate.message).toInclude("wheels browser setup");
			});

			it("fails browser specs with the launch error when the browser could not start", () => {
				var bundle = new wheels.wheelstest.BrowserTest();
				bundle.$browserLaunchFailed("Host system is missing dependencies to run browsers");
				var gate = bundle.$browserSpecGate();
				expect(gate.action).toBe("error");
				expect(gate.message).toInclude("Host system is missing dependencies to run browsers");
				expect(gate.message).toInclude("WHEELS_BROWSER_SKIP_LAUNCH_FAILURES");
				// not a skip: a spec guarded by `if (this.browserTestSkipped) return;` does not pass
				expect(bundle.browserTestSkipped).toBeFalse();
			});

			it("makes this.browser raise the launch error after a launch failure", () => {
				var bundle = new wheels.wheelstest.BrowserTest();
				bundle.$browserLaunchFailed("Host system is missing dependencies to run browsers");
				var visit = function() {
					bundle.browser.visit("/");
				};
				expect(visit).toThrow(type = "Wheels.BrowserLaunchFailed", regex = "missing dependencies");
			});

		});

		describe("BrowserTest browserSpecGuard() for specs outside browserDescribe()", () => {

			it("lets the spec run when the browser started", () => {
				var bundle = new wheels.wheelstest.BrowserTest();
				expect(bundle.browserSpecGuard()).toBeTrue();
			});

			it("skips the spec, with the reason, when browser specs cannot run here", () => {
				var bundle = new wheels.wheelstest.BrowserTest();
				bundle.$skipBrowserSpecs("Playwright is not installed.");
				var guard = function() {
					bundle.browserSpecGuard();
				};
				expect(guard).toThrow(type = "TestBox.SkipSpec", regex = "Playwright is not installed");
			});

			it("fails the spec when the browser could not be started", () => {
				var bundle = new wheels.wheelstest.BrowserTest();
				bundle.$browserLaunchFailed("Host system is missing dependencies to run browsers");
				var guard = function() {
					bundle.browserSpecGuard();
				};
				expect(guard).toThrow(type = "Wheels.BrowserLaunchFailed", regex = "missing dependencies");
			});

			it("is what browserDescribe() uses to skip or fail a spec", () => {
				var source = FileRead(ExpandPath("/wheels/wheelstest/BrowserTest.cfc"));
				expect(FindNoCase("var gate = me.$browserSpecGate();", source)).toBeGT(0);
				expect(FindNoCase("me.skip(gate.message);", source)).toBeGT(0);
				expect(FindNoCase("throw(type = ""Wheels.BrowserLaunchFailed"", message = gate.message);", source)).toBeGT(0);
			});

		});

	}

}
