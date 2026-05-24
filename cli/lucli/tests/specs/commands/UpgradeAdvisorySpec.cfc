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

			it("uses stripCfmlComments on the settings-file pre-check for the guard", () => {
				// The flag-already-set guard must also strip comments so a
				// commented-out `// set(useUnderscoreReferenceColumns=true);`
				// doesn't satisfy the guard and suppress a real advisory.
				expect(variables.moduleSource).toInclude("stripCfmlComments(fileRead(settingsFile))");
			});

		});

	}

}
