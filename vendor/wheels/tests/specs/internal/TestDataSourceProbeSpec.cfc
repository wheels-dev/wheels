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

			it("app-runner.cfm probes only the candidate test datasource before refusing", () => {
				var source = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				var probePos = FindNoCase("$dataSourceIsReachable(name = local.candidate)", source);
				expect(probePos).toBeGT(0, "app-runner must probe <datasource>_test by name");
				// The probe sits in the same decision that swaps or refuses.
				var window = Mid(source, probePos, 4000);
				expect(FindNoCase("local.candidateRegistered", window) > 0).toBeTrue();
				expect(FindNoCase("Test database not available", window) > 0).toBeTrue(
					"a failed probe must still reach the refusal"
				);
				// The primary datasource is never probed.
				expect(FindNoCase("$dataSourceIsReachable(name = local.originalDataSource", source)).toBe(0);
			});

		});

	}

}
