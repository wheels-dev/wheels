component extends="wheels.wheelstest.BrowserTest" {

	function beforeAll() {
		// No super.beforeAll(): skip before the launcher is touched, so this is
		// deterministic without Playwright or a network.
		$skipBrowserSpecs("Browser layer unavailable (skip-status fixture)");
	}

	function run() {
		browserDescribe("skip-status fixture", () => {
			it("must not execute when the gate says skip", () => {
				throw(
					type    = "Wheels.BrowserTest.SkipFixtureExecuted",
					message = "browserDescribe() ran the spec body despite a skip gate."
				);
			});
		});
	}
}
