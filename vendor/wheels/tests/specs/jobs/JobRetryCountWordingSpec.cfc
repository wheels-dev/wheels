/**
 * maxRetries counts the retries after the first run (JobHardenerSpec S9: maxRetries=3 allows
 * 4 tries). The failure log and the guide say the same.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("maxRetries wording", () => {

			it("logs how many times a job ran when it runs out of retries", () => {
				var source = FileRead(ExpandPath("/wheels/Job.cfc"));
				expect(FindNoCase("permanently failed after ##local.currentAttempts## attempts (##local.maxRetries## retries)", source)).toBeGT(0);
				expect(FindNoCase("permanently failed after ##local.maxRetries## attempts", source)).toBe(0);
			});

			it("the background-jobs guide counts maxRetries as retries after the first run", () => {
				var guide = FileRead(ExpandPath("/wheels/../..") & "/web/sites/guides/src/content/docs/v4-2-0/digging-deeper/background-jobs.mdx");
				expect(FindNoCase("counts total attempts", guide)).toBe(0);
				expect(FindNoCase("counts the retries after the first run", guide)).toBeGT(0);
			});

		});
	}

}
