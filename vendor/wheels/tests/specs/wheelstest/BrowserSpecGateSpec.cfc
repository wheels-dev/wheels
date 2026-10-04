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
				expect(bundle.browserTestSkipped).toBeTrue();
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
