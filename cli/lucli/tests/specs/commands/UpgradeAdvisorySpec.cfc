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

	}

}
