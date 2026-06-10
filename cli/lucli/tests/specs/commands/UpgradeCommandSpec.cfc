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

		describe("wheels upgrade — --strict CI gate (##2963)", () => {

			// #2963 / wave-2 §5.2 (Part 1): `wheels upgrade check` already
			// throws Wheels.UpgradeCheckFailed when breaking findings exist,
			// but advisories never gate CI. `--strict` escalates advisory
			// findings to a hard failure so projects can opt into "treat
			// recommended improvements as breaking" for CI runs. Mirrors
			// Django's `--fail-level WARNING` / Mix's --warnings-as-errors.

			it("declares the --strict flag in parseUpgradeArgs", () => {
				// Source-level: parseUpgradeArgs must declare a `strict` flag
				// alongside `to` and `format` so LuCLI surfaces it.
				var startIdx = reFindNoCase("(?m)^[ \t]*private\s+struct\s+function\s+parseUpgradeArgs\s*\(", variables.moduleSource);
				expect(startIdx).toBeGT(0);
				var body = mid(variables.moduleSource, startIdx, 800);
				expect(body).toInclude("strict");
				expect(body).toInclude(".flag");
			});

			it("threads strict mode through to runUpgradeCheck", () => {
				// upgrade() must forward the parsed strict flag into the runner.
				// Window the dispatch line so we don't false-match an unrelated
				// strict reference elsewhere in the module.
				var dispatchIdx = reFindNoCase("runUpgradeCheck\s*\(", variables.moduleSource);
				expect(dispatchIdx).toBeGT(0);
				var callsite = mid(variables.moduleSource, dispatchIdx, 200);
				expect(callsite).toInclude("opts.strict");
			});

			it("runUpgradeCheck accepts a strict argument", () => {
				var startIdx = reFindNoCase("(?m)^[ \t]*private\s+string\s+function\s+runUpgradeCheck\s*\(", variables.moduleSource);
				expect(startIdx).toBeGT(0);
				var sigEnd = find(")", variables.moduleSource, startIdx);
				expect(sigEnd).toBeGT(startIdx);
				var signature = mid(variables.moduleSource, startIdx, sigEnd - startIdx + 1);
				expect(signature).toInclude("strict");
			});

			it("throws Wheels.UpgradeCheckFailed when strict mode finds advisories (no breaking)", () => {
				// The strict gate must throw with a distinct, parseable error
				// type so pipelines can distinguish "breaking" from
				// "strict-mode advisory" exits. Reuse the existing
				// UpgradeCheckFailed type so CI scripts that already filter on
				// it pick the strict case up automatically.
				expect(variables.moduleSource).toInclude("Wheels.UpgradeCheckFailed");
				// The strict gate fires when (a) strict mode is on AND (b) at
				// least one advisory was matched. Match the conjunction loosely
				// so an equivalent rewrite (e.g. `strict && arrayLen(advisories)`)
				// still satisfies the spec.
				expect(reFindNoCase("strict\s*(&&|and)\s*arrayLen\s*\(\s*advisories", variables.moduleSource)).toBeGT(0);
			});

			it("documents --strict in the upgrade() help banner", () => {
				// The help text users read when running bare `wheels upgrade`
				// must surface the new flag — otherwise it's discoverable only
				// by reading the source.
				expect(variables.moduleSource).toInclude("--strict");
			});

		});

	}

}
