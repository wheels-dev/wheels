/**
 * Issue 3031: explicit set(allowEnvironmentSwitchViaUrl=true) used to be
 * indistinguishable from the framework default (also true), so the documented
 * production override was always silently discarded. The setting now boots as
 * a non-boolean sentinel and $resolveAllowEnvironmentSwitchViaUrl() resolves
 * it to a real boolean right after the config/settings.cfm includes: an
 * explicit boolean is honored in every environment, the sentinel falls back
 * to the framework default (disabled in production-like environments,
 * enabled everywhere else).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("allowEnvironmentSwitchViaUrl resolution (issue 3031)", () => {

			// "__wheels_unset__" stands in for the boot sentinel below: the helper's
			// contract is "explicit boolean -> honored, anything else -> default".

			it("disables switching in production-like environments when the developer never set it", () => {
				local.events = CreateObject("component", "wheels.events.onapplicationstart");
				for (local.environmentName in ["production", "testing", "maintenance"]) {
					local.resolved = local.events.$resolveAllowEnvironmentSwitchViaUrl(
						settingValue = "__wheels_unset__",
						environment = local.environmentName
					);
					expect(local.resolved).toBeFalse("expected unset to resolve to false in #local.environmentName#");
				}
			});

			it("honors explicit set(allowEnvironmentSwitchViaUrl=true) in production-like environments", () => {
				local.events = CreateObject("component", "wheels.events.onapplicationstart");
				for (local.environmentName in ["production", "testing", "maintenance"]) {
					local.resolved = local.events.$resolveAllowEnvironmentSwitchViaUrl(
						settingValue = true,
						environment = local.environmentName
					);
					expect(local.resolved).toBeTrue("expected explicit true to be honored in #local.environmentName#");
				}
			});

			it("honors explicit set(allowEnvironmentSwitchViaUrl=false) in production-like environments", () => {
				local.events = CreateObject("component", "wheels.events.onapplicationstart");
				local.resolved = local.events.$resolveAllowEnvironmentSwitchViaUrl(
					settingValue = false,
					environment = "production"
				);
				expect(local.resolved).toBeFalse();
			});

			it("enables switching in development when the developer never set it", () => {
				local.events = CreateObject("component", "wheels.events.onapplicationstart");
				local.resolved = local.events.$resolveAllowEnvironmentSwitchViaUrl(
					settingValue = "__wheels_unset__",
					environment = "development"
				);
				expect(local.resolved).toBeTrue();
			});

			it("honors explicit set(allowEnvironmentSwitchViaUrl=false) in development", () => {
				local.events = CreateObject("component", "wheels.events.onapplicationstart");
				local.resolved = local.events.$resolveAllowEnvironmentSwitchViaUrl(
					settingValue = false,
					environment = "development"
				);
				expect(local.resolved).toBeFalse();
			});

			it("always resolves to a real boolean", () => {
				local.events = CreateObject("component", "wheels.events.onapplicationstart");
				local.cases = [
					{settingValue: "__wheels_unset__", environment: "production"},
					{settingValue: true, environment: "production"},
					{settingValue: false, environment: "production"},
					{settingValue: "__wheels_unset__", environment: "development"},
					{settingValue: false, environment: "development"}
				];
				for (local.testCase in local.cases) {
					local.resolved = local.events.$resolveAllowEnvironmentSwitchViaUrl(
						settingValue = local.testCase.settingValue,
						environment = local.testCase.environment
					);
					expect(IsBoolean(local.resolved)).toBeTrue(
						"expected a boolean for #local.testCase.environment# / #local.testCase.settingValue#"
					);
				}
			});

			it("leaves the running application's setting as a real boolean after app start", () => {
				expect(IsBoolean(application.wheels.allowEnvironmentSwitchViaUrl)).toBeTrue();
			});

		});
	}
}
