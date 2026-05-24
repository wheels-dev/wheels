/**
 * Source-level coverage for the underscore-references advisory entries
 * shipped in PR4 of the #2781 follow-up series. These advisories surface in
 * the "Recommended Improvements" section of `wheels upgrade check` output
 * (severity=advisory — runs regardless of major-version-jump, doesn't gate
 * CI exit codes).
 *
 * Like UpgradeCommandSpec, source-level inspection — Module.cfc can't be
 * instantiated under TestBox.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {

		describe("wheels upgrade — t.references() opt-in advisory", () => {

			it("declares an advisory check that greps app/migrator/migrations for t.references(", () => {
				expect(variables.moduleSource).toInclude("t\.references\s*\(");
				expect(variables.moduleSource).toInclude("severity: ""advisory""");
				expect(variables.moduleSource).toInclude("app/migrator/migrations");
			});

			it("mentions useUnderscoreReferenceColumns in the fix message", () => {
				expect(variables.moduleSource).toInclude("useUnderscoreReferenceColumns=true");
			});

			it("notes that applied migrations are unaffected (avoids alarming users)", () => {
				expect(variables.moduleSource).toInclude("Existing applied migrations are unaffected");
			});

		});

		describe("wheels upgrade — mixed-convention warning", () => {

			it("declares an advisory check that greps config/ for useUnderscoreReferenceColumns=true", () => {
				expect(variables.moduleSource).toInclude("useUnderscoreReferenceColumns\s*=\s*true");
			});

			it("warns about legacy migrations possibly leaving <name>id columns", () => {
				expect(variables.moduleSource).toInclude("legacy migrations");
				expect(variables.moduleSource).toInclude("data migration");
			});

		});

		describe("wheels upgrade — false-positive guards", () => {

			it("suppresses the opt-in advisory when the flag is already set in config/settings.cfm", () => {
				// Source-level assertion on the guard variable: the t.references()
				// advisory must only fire when the flag isn't already set, else
				// new apps (which ship with the flag on by default) would see
				// advisory #1 contradicting advisory #2.
				expect(variables.moduleSource).toInclude("underscoreFlagAlreadySet");
				expect(variables.moduleSource).toInclude("if (!underscoreFlagAlreadySet)");
			});

			it("strips CFML comments before grepping (Anti-Pattern ##14)", () => {
				// The grep loop must run input through stripCfmlComments so a
				// commented-out `// t.references(...)` or
				// `// set(useUnderscoreReferenceColumns=true);` doesn't trip
				// the advisory. The fix lives in the shared grep loop, so this
				// is also a framework-wide benefit for every check struct.
				expect(variables.moduleSource).toInclude("stripCfmlComments(fileRead(filePath))");
			});

			it("scans config/ recursively for the underscore flag pre-check (matches advisory ##2 scope)", () => {
				// Fix for ##2808: the pre-check originally read only
				// `config/settings.cfm`, but advisory ##2 below scans all of
				// `config/` recursively. If a user sets the flag in an
				// environment override file (e.g.
				// `config/production/settings.cfm`), the pre-check missed it
				// and both advisories fired contradicting each other.
				// Scope-symmetry: walk the same tree the warning scans.
				expect(variables.moduleSource).toInclude("directoryExists(configDir)");
				expect(variables.moduleSource).toInclude("directoryList(configDir, true");
			});

			it("strips CFML comments on every config/ file scanned by the guard", () => {
				// The flag-already-set guard must still strip comments so a
				// commented-out `// set(useUnderscoreReferenceColumns=true);`
				// in any env-override file doesn't satisfy the guard and
				// suppress a real advisory (Anti-Pattern ##14).
				expect(variables.moduleSource).toInclude("stripCfmlComments(fileRead(configFile))");
			});

			it("does not wrap reFindNoCase with len() — that pattern is always truthy", () => {
				// `reFindNoCase()` returns an integer position (0 = no match).
				// `len(0)` returns 1 (digit count of "0"), `len(25)` returns 2,
				// so any reFindNoCase result wrapped in len() is truthy. The
				// guard would be dead in every app whose config/settings.cfm
				// exists. Use direct `> 0` comparison instead.
				expect(variables.moduleSource).notToInclude("len(reFindNoCase");
			});

		});

	}

}
