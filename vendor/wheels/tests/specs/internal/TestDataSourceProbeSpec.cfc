/**
 * Before refusing a missing `<datasource>_test`, the app test runner
 * probes it by name, so a datasource registered at server level (the Lucee
 * admin, lucee.json configuration, the CF Administrator, CommandBox cfconfig),
 * which GetApplicationMetaData().datasources doesn't list, is accepted instead
 * of refused. Any probe failure still counts as "not registered" (fail closed),
 * and only the candidate name is probed.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Test datasource probe", () => {

			it("finds a datasource the engine can open, even when the application metadata doesn't list it", () => {
				var ds = g.get("dataSourceName");
				expect(g.$dataSourceIsReachable(name = ds)).toBeTrue("datasource " & ds);
			});

			it("reports an unregistered datasource as not reachable", () => {
				var missing = "wheels_no_such_ds_" & Replace(CreateUUID(), "-", "", "all");
				expect(g.$dataSourceIsReachable(name = missing)).toBeFalse();
			});

			it("reports an empty name as not reachable", () => {
				expect(g.$dataSourceIsReachable(name = "")).toBeFalse();
				expect(g.$dataSourceIsReachable(name = "   ")).toBeFalse();
			});

			it("the app test rule probes only the candidate test datasource before refusing", () => {
				var helpers = FileRead(ExpandPath("/wheels/global/util.cfm"));
				var probePos = FindNoCase("return $dataSourceIsReachable(name = arguments.name);", helpers);
				expect(probePos).toBeGT(0, "$testDataSourceRegistered() must probe the datasource by name");
				// The decision probes the candidate (<datasource>_test), never the primary.
				expect(FindNoCase("$testDataSourceRegistered(local.rv.candidate)", helpers)).toBeGT(0);
				expect(FindNoCase("$testDataSourceRegistered(arguments.primary", helpers)).toBe(0);
				expect(FindNoCase("$dataSourceIsReachable(name = local.originalDataSource", FileRead(ExpandPath("/wheels/tests/app-runner.cfm")))).toBe(0);
				// A candidate that is neither registered nor reachable is refused.
				expect(g.$testDataSourceDecision(primary = "aow_no_such_datasource", requestUrl = {useTestDB = true}).action).toBe("refuse");
			});

		});

	}

}
