component extends="wheels.WheelsTest" {

	function run() {
		describe("browserDescribe() skip status", () => {

			it("records a gate-skipped browser spec as Skipped, with its reason", () => {
				var testBox = new wheels.wheelstest.system.TestBox(
					bundles = ["wheels.tests.resources.wheelstest.BrowserDescribeSkippedFixture"]
				);
				var results = testBox.runRaw();

				// The fixture has one spec; a skip must not affect pass/fail/error.
				expect(results.getTotalPass()).toBe(0);
				expect(results.getTotalSkipped()).toBe(1);
				expect(results.getTotalFail()).toBe(0);
				expect(results.getTotalError()).toBe(0);

				var bs = results.getBundleStats();
				expect(arrayLen(bs)).toBe(1);
				expect(bs[1].path).toInclude("BrowserDescribeSkippedFixture");
				expect(bs[1].totalPass).toBe(0);
				expect(bs[1].totalSkipped).toBe(1);

				// Bundle -> top-level suite -> spec (created by the runner).
				expect(arrayLen(bs[1].suiteStats)).toBe(1);
				var specs = bs[1].suiteStats[1].specStats;
				expect(arrayLen(specs)).toBe(1);
				expect(Compare(specs[1].status, "Skipped")).toBe(0);
				expect(Compare(specs[1].failMessage, "Browser layer unavailable (skip-status fixture)")).toBe(0);
			});

		});
	}
}
