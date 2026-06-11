component extends="wheels.WheelsTest" {

	function run() {

		// Sentinel that onapplicationstart writes into
		// application.$wheels.allowEnvironmentSwitchViaUrl *before* including
		// config/settings.cfm. It is a non-boolean value, so an explicit
		// set(allowEnvironmentSwitchViaUrl=true|false) in settings.cfm is always
		// distinguishable from "developer never touched it" (issue #3031).
		variables.UNSET = "$wheelsDefault";

		describe("allowEnvironmentSwitchViaUrl resolution (issue #3031)", () => {

			it("disables switching in production-like envs when not explicitly set", () => {
				expect(
					application.wo.$resolveEnvironmentSwitchViaUrl(
						settingValue = variables.UNSET,
						defaultValue = true,
						environment = "production"
					)
				).toBeFalse();
				expect(
					application.wo.$resolveEnvironmentSwitchViaUrl(
						settingValue = variables.UNSET,
						defaultValue = true,
						environment = "testing"
					)
				).toBeFalse();
				expect(
					application.wo.$resolveEnvironmentSwitchViaUrl(
						settingValue = variables.UNSET,
						defaultValue = true,
						environment = "maintenance"
					)
				).toBeFalse();
			});

			it("honors an explicit true in production-like envs (documented override)", () => {
				expect(
					application.wo.$resolveEnvironmentSwitchViaUrl(
						settingValue = true,
						defaultValue = true,
						environment = "production"
					)
				).toBeTrue();
				expect(
					application.wo.$resolveEnvironmentSwitchViaUrl(
						settingValue = true,
						defaultValue = true,
						environment = "testing"
					)
				).toBeTrue();
			});

			it("defaults to true in development when not explicitly set", () => {
				expect(
					application.wo.$resolveEnvironmentSwitchViaUrl(
						settingValue = variables.UNSET,
						defaultValue = true,
						environment = "development"
					)
				).toBeTrue();
			});

			it("honors an explicit false in development", () => {
				expect(
					application.wo.$resolveEnvironmentSwitchViaUrl(
						settingValue = false,
						defaultValue = true,
						environment = "development"
					)
				).toBeFalse();
			});

			it("carries a previously-disabled default through development when not explicitly set", () => {
				// A prior reload may have carried allowEnvironmentSwitchViaUrl=false
				// across into the computed default; with no explicit set it must stick.
				expect(
					application.wo.$resolveEnvironmentSwitchViaUrl(
						settingValue = variables.UNSET,
						defaultValue = false,
						environment = "development"
					)
				).toBeFalse();
			});

			it("always returns a real boolean", () => {
				local.cases = [
					{settingValue: variables.UNSET, defaultValue: true, environment: "production"},
					{settingValue: true, defaultValue: true, environment: "production"},
					{settingValue: variables.UNSET, defaultValue: true, environment: "development"},
					{settingValue: false, defaultValue: true, environment: "development"}
				];
				local.iEnd = ArrayLen(local.cases);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.c = local.cases[local.i];
					local.result = application.wo.$resolveEnvironmentSwitchViaUrl(
						settingValue = local.c.settingValue,
						defaultValue = local.c.defaultValue,
						environment = local.c.environment
					);
					expect(IsBoolean(local.result)).toBeTrue();
				}
			});

		});
	}
}
