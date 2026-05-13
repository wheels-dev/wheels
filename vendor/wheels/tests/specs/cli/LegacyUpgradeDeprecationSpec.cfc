/**
 * Regression: cli/src/commands/wheels/upgrade.cfc is the legacy CommandBox
 * `box wheels upgrade` command. Its getAvailableVersions() hardcoded a static
 * list maxing at "3.1.0", so a user on 3.0.0 running `box wheels upgrade` was
 * told "You are already on the latest version" — silently missing every 4.x
 * release. The post-upgrade-recommendations URL pointed at the pre-4.0
 * upgrade page, and the breaking-changes map had no 3.x -> 4.x entries.
 *
 * Issue #2634: the CommandBox `wheels-cli` module is already deprecated for
 * v5.0 removal per the 4.0 CHANGELOG. The fix is to print a deprecation
 * banner directing users to the new `wheels` CLI and short-circuit before the
 * stale ForgeBox lookup. The fix MUST also update the post-upgrade URL to
 * the canonical v4.0 guide so any user still reaching it lands somewhere
 * useful.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("cli/src/commands/wheels/upgrade.cfc", () => {

			// expandPath("/wheels") resolves to vendor/wheels; the repo root is
			// two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var upgradePath = repoRoot & "/cli/src/commands/wheels/upgrade.cfc";

			it("the legacy upgrade command source file exists", () => {
				expect(fileExists(upgradePath)).toBeTrue("Missing file: " & upgradePath);
			});

			it("declares itself deprecated and points users at the new Wheels CLI", () => {
				var content = fileRead(upgradePath);

				expect(reFindNoCase("box\s+wheels\s+upgrade.{0,40}deprecated", content) > 0).toBeTrue(
					"upgrade.cfc should declare that the `box wheels upgrade` command is deprecated "
					& "(e.g. a banner string mentioning both `box wheels upgrade` and `deprecated`)."
				);

				expect(content contains "brew install wheels-dev/wheels/wheels").toBeTrue(
					"upgrade.cfc should point users at the new Wheels CLI (`brew install wheels-dev/wheels/wheels`)."
				);
			});

			it("short-circuits before the stale ForgeBox / hardcoded version lookup", () => {
				var content = fileRead(upgradePath);

				// The short-circuit must come before getAvailableVersions() is
				// called, otherwise a 3.x user still lands in the stale
				// hardcoded-version branch. We assert this by checking that
				// run() contains a `return;` (deprecation short-circuit) at a
				// position before the first `getAvailableVersions(` call.
				var runStart = reFind("function\s+run\s*\(", content);
				expect(runStart > 0).toBeTrue("run() function not found in upgrade.cfc");

				var firstReturnInRun = reFind("(?m)^\s*return\s*;", content, runStart);
				// Match the actual call site, not stray mentions in comments
				// (the deprecation banner's explanatory comment also names
				// the function). The real call assigns to a local.
				var firstAvailableCall = reFind("=\s*getAvailableVersions\s*\(", content, runStart);

				expect(firstReturnInRun > 0).toBeTrue(
					"upgrade.cfc run() should contain a short-circuit `return;` after printing the deprecation banner."
				);
				expect(firstAvailableCall > 0).toBeTrue("getAvailableVersions() call not found in run()");
				expect(firstReturnInRun < firstAvailableCall).toBeTrue(
					"upgrade.cfc must short-circuit (return) BEFORE calling getAvailableVersions() — "
					& "otherwise 3.x users still hit the stale hardcoded list that maxes at 3.1.0."
				);
			});

			it("updates the post-upgrade recommendations URL to the canonical v4.0 guide", () => {
				var content = fileRead(upgradePath);

				expect(content contains "guides.wheels.dev/v4-0-0").toBeTrue(
					"upgrade.cfc should reference the canonical v4.0 upgrade guide "
					& "(https://guides.wheels.dev/v4-0-0/upgrading/3x-to-4x/)."
				);

				expect(content contains "wheels.dev/guides/introduction/upgrading").toBeFalse(
					"upgrade.cfc still references the pre-4.0 upgrade-guide URL — "
					& "replace with the canonical v4.0 guide URL."
				);
			});

		});

	}

}
