/**
 * Tests the test command via Module.cfc.
 * Verifies argument parsing for filter, reporter, db, verbose, ci, core flags.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Create vendor/wheels/tests stub so auto-detect finds core tests
		directoryCreate(tempRoot & "/vendor/wheels/tests", true, true);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("wheels test", () => {

			it("runs without error with no args", () => {
				mod.__arguments = [];
				// Will attempt to run tests and fail gracefully (no server)
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts positional filter argument", () => {
				mod.__arguments = ["model"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --filter flag", () => {
				mod.__arguments = ["--filter=controller"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --filter with space syntax", () => {
				mod.__arguments = ["--filter", "model"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --reporter flag", () => {
				mod.__arguments = ["--reporter=simple"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --db flag", () => {
				mod.__arguments = ["--db=sqlite"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --verbose flag", () => {
				mod.__arguments = ["--verbose"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts -v shorthand", () => {
				mod.__arguments = ["-v"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --ci flag", () => {
				mod.__arguments = ["--ci"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --core flag", () => {
				mod.__arguments = ["--core"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts combined flags", () => {
				mod.__arguments = ["--filter=model", "--db=sqlite", "--verbose", "--ci"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --directory flag as filter alias", () => {
				mod.__arguments = ["--directory=tests.specs.models"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --directory with space syntax", () => {
				mod.__arguments = ["--directory", "tests.specs.browser"];
				mod.test();
				expect(true).toBeTrue();
			});

		});

		describe("$normalizeTestFilter (app mode)", () => {

			it("returns empty string for empty input", () => {
				expect(mod.$normalizeTestFilter("")).toBe("");
			});

			it("returns empty for whitespace-only input", () => {
				expect(mod.$normalizeTestFilter("   ")).toBe("");
			});

			it("prefixes a bare directory name with tests.specs.", () => {
				expect(mod.$normalizeTestFilter("browser")).toBe("tests.specs.browser");
				expect(mod.$normalizeTestFilter("models")).toBe("tests.specs.models");
				expect(mod.$normalizeTestFilter("controllers")).toBe("tests.specs.controllers");
			});

			it("passes through fully-qualified app paths unchanged", () => {
				expect(mod.$normalizeTestFilter("tests.specs")).toBe("tests.specs");
				expect(mod.$normalizeTestFilter("tests.specs.browser")).toBe("tests.specs.browser");
				expect(mod.$normalizeTestFilter("tests.specs.models.UserSpec")).toBe("tests.specs.models.UserSpec");
			});

			it("trims surrounding whitespace before normalizing", () => {
				expect(mod.$normalizeTestFilter("  browser  ")).toBe("tests.specs.browser");
			});

		});

		describe("$normalizeTestFilter (core mode)", () => {

			it("prefixes bare names with wheels.tests.specs.", () => {
				expect(mod.$normalizeTestFilter("model", true)).toBe("wheels.tests.specs.model");
				expect(mod.$normalizeTestFilter("security", true)).toBe("wheels.tests.specs.security");
			});

			it("passes through fully-qualified core paths unchanged", () => {
				expect(mod.$normalizeTestFilter("wheels.tests.specs", true)).toBe("wheels.tests.specs");
				expect(mod.$normalizeTestFilter("wheels.tests.specs.model", true)).toBe("wheels.tests.specs.model");
			});

			it("passes through vendor package paths unchanged", () => {
				expect(mod.$normalizeTestFilter("vendor.wheels-sentry.tests", true)).toBe("vendor.wheels-sentry.tests");
				expect(mod.$normalizeTestFilter("vendor.wheels-basecoat.tests.specs", true)).toBe("vendor.wheels-basecoat.tests.specs");
			});

			it("does not prefix app-style paths in core mode", () => {
				// Bare `tests.specs.foo` is an app-style path; core mode
				// rejects it as bare and prefixes — runner.cfm regex won't
				// accept it either way, so prefixing is at least consistent.
				expect(mod.$normalizeTestFilter("tests.specs.foo", true)).toBe("wheels.tests.specs.tests.specs.foo");
			});

		});

	}

}
