/**
 * $liveScopeTestSwapWarning(): the wheels.log warning for a test run that switches the datasource
 * in the LIVE application scope. That happens when the app's public/Application.cfc lacks the
 * test-context include (or WHEELS_ENV isn't development or testing): every other request to the
 * app then reads and writes the test datasource until the run ends. $warnLiveScopeTestSwap()
 * writes it once per run, from the built-in app runner and from the project-runner path.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$liveScopeTestSwapWarning()", () => {

			it("warns when a live (not _wheelsTest) application switches to the test datasource", () => {
				var message = application.wo.$liveScopeTestSwapWarning(
					applicationName = "shop",
					primary = "shop",
					target = "shop_test"
				);
				expect(message).toInclude("live application's datasource from 'shop' to 'shop_test'");
				expect(message).toInclude("other requests to this app read and write 'shop_test'");
				expect(message).toInclude("vendor/wheels/events/testcontext.cfm");
				expect(message).toInclude("public/Application.cfc");
				expect(message).toInclude("WHEELS_ENV=development or testing");
			});

			it("is silent in the isolated _wheelsTest application", () => {
				expect(application.wo.$liveScopeTestSwapWarning(
					applicationName = "shop_wheelsTest",
					primary = "shop",
					target = "shop_test"
				)).toBe("");
			});

			it("is silent when the run keeps the primary datasource", () => {
				expect(application.wo.$liveScopeTestSwapWarning(
					applicationName = "shop",
					primary = "shop",
					target = "shop"
				)).toBe("");
				expect(application.wo.$liveScopeTestSwapWarning(
					applicationName = "shop",
					primary = "shop",
					target = ""
				)).toBe("");
			});

			it("only treats a trailing _wheelsTest suffix as isolated", () => {
				expect(application.wo.$liveScopeTestSwapWarning(
					applicationName = "shop_wheelsTest_old",
					primary = "shop",
					target = "shop_test"
				)).toInclude("live application's datasource");
			});

			it("is called at both places a test run switches the datasource", () => {
				var util = FileRead(ExpandPath("/wheels/global/util.cfm"));
				var runner = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				var beginStart = Find("function $beginTestRunDataSource(", util);
				expect(beginStart).toBeGT(0);
				var beginEnd = Find("return local.saved;", util, beginStart);
				expect(Mid(util, beginStart, beginEnd - beginStart)).toInclude("$warnLiveScopeTestSwap(");
				expect(runner).toInclude("$warnLiveScopeTestSwap(");
			});
		});
	}

}
