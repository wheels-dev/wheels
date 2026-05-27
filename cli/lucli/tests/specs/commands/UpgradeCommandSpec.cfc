/**
 * Source-level regression for `wheels upgrade check` scanner structure.
 *
 * PR3 of the #2781 follow-up series introduces a `severity` field on each
 * check ("breaking" by default; "advisory" for opt-in recommendations) and
 * adds a "Recommended Improvements" output section. Same-major upgrades no
 * longer short-circuit before the checks loop — advisories must run
 * regardless of major-version-bump.
 *
 * Like other CLI command specs (ConsoleCommandSpec, ReloadCommandSpec), we
 * inspect Module.cfc source rather than instantiating it, because Module
 * extends `modules.BaseModule` which is only resolvable at LuCLI runtime,
 * not in TestBox.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {

		describe("wheels upgrade — scanner structure (PR3)", () => {

			it("declares the severity field convention in a comment", () => {
				// The check-database comment must document the severity field
				// so future contributors know the alias exists. Failure here
				// means the convention wasn't recorded in code.
				expect(variables.moduleSource).toInclude("severity");
				expect(variables.moduleSource).toInclude("advisory");
			});

			it("does not short-circuit same-major upgrades before running checks", () => {
				// Pre-PR3 behavior: `if (currentMajor == targetMajor) { ...; return ""; }`
				// halted execution before checks could run. PR3 removes that
				// early return so advisories fire on same-major upgrades too.
				// Source check: ensure the `sameMajor` boolean is set and used,
				// indicating the new flow that doesn't early-return.
				expect(variables.moduleSource).toInclude("sameMajor");
			});

			it("buckets matched checks into issues OR advisories by severity", () => {
				// The iteration loop must split matched checks into two buckets.
				expect(variables.moduleSource).toInclude("advisories");
				expect(variables.moduleSource).toInclude("matchEntry");
			});

			it("renders a 'Recommended Improvements' output section", () => {
				expect(variables.moduleSource).toInclude("Recommended Improvements");
			});

			it("preserves the 'Breaking Changes' output section", () => {
				expect(variables.moduleSource).toInclude("Breaking Changes");
			});

			it("preserves the 'All Clear' output section", () => {
				expect(variables.moduleSource).toInclude("All Clear");
			});

		});

	}

}
