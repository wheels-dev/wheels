/**
 * `wheels test` scopes (issues 3963, 3893).
 *
 * A filesystem-style scope (tests/specs/models, tests/specs/models/BookSpec.cfc,
 * a trailing slash, a leading ./, a path relative to tests/specs) resolves to
 * the dotted form the runner takes. A scope the runner would reject, or one
 * that names no folder or spec file in the project, is refused before
 * anything runs, instead of running the full suite and then reporting that no
 * test bundles ran.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.tempRoot = getTempDirectory() & "wheels-cli-test-scope-" & createUUID();
		for (var dir in [
			"/config",
			"/tests/specs/models",
			"/tests/specs/controllers",
			"/vendor/wheels/tests/specs/model",
			"/vendor/wheels-sentry/tests"
		]) {
			directoryCreate(variables.tempRoot & dir, true, true);
		}
		fileWrite(variables.tempRoot & "/config/settings.cfm", "<cfscript>" & chr(10) & "</cfscript>" & chr(10));
		for (var spec in [
			"/tests/specs/models/BookSpec.cfc",
			"/tests/specs/controllers/BooksSpec.cfc",
			"/vendor/wheels/tests/specs/model/FooSpec.cfc"
		]) {
			fileWrite(variables.tempRoot & spec, "component {}" & chr(10));
		}
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
		variables.root = reReplace(replace(variables.tempRoot, "\", "/", "all"), "/+$", "");
	}

	function afterAll() {
		if (Len(variables.tempRoot) > 10 && directoryExists(variables.tempRoot)) {
			directoryDelete(variables.tempRoot, true);
		}
	}

	/** Run `wheels test` with the given arguments; return the refusal, or "" when it was not refused. */
	private struct function refusal(required struct args) {
		var state = {type = "", message = ""};
		try {
			mod.test(argumentCollection = arguments.args);
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		return state;
	}

	function run() {

		describe("path scopes resolve to dotted scopes (issue 3963)", () => {

			it("resolves a spec file path", () => {
				expect(mod.$resolveTestFilter("tests/specs/models/BookSpec.cfc")).toBe("tests.specs.models.BookSpec");
			});

			it("resolves a directory path, with or without a trailing slash", () => {
				expect(mod.$resolveTestFilter("tests/specs/models")).toBe("tests.specs.models");
				expect(mod.$resolveTestFilter("tests/specs/models/")).toBe("tests.specs.models");
			});

			it("drops a leading ./", () => {
				expect(mod.$resolveTestFilter("./tests/specs/models")).toBe("tests.specs.models");
				expect(mod.$resolveTestFilter("./tests/specs/models/BookSpec.cfc")).toBe("tests.specs.models.BookSpec");
			});

			it("takes a path relative to tests/specs", () => {
				expect(mod.$resolveTestFilter("models/BookSpec.cfc")).toBe("tests.specs.models.BookSpec");
				expect(mod.$resolveTestFilter("models/")).toBe("tests.specs.models");
			});

			it("accepts Windows separators", () => {
				expect(mod.$resolveTestFilter("tests\specs\models\BookSpec.cfc")).toBe("tests.specs.models.BookSpec");
			});

			it("accepts an absolute path under the project root", () => {
				expect(mod.$resolveTestFilter(variables.root & "/tests/specs/models")).toBe("tests.specs.models");
			});

			it("looks a bare spec file name up like the spec name", () => {
				expect(mod.$resolveTestFilter("BookSpec.cfc")).toBe("tests.specs.models.BookSpec");
			});

			it("leaves dotted scopes and spec names as before", () => {
				expect(mod.$resolveTestFilter("tests.specs.models")).toBe("tests.specs.models");
				expect(mod.$resolveTestFilter("BookSpec")).toBe("tests.specs.models.BookSpec");
				expect(mod.$resolveTestFilter("models")).toBe("tests.specs.models");
			});

			it("maps core-mode paths", () => {
				expect(mod.$resolveTestFilter("vendor/wheels/tests/specs/model", true)).toBe("wheels.tests.specs.model");
				expect(mod.$resolveTestFilter("model/FooSpec.cfc", true)).toBe("wheels.tests.specs.model.FooSpec");
				expect(mod.$resolveTestFilter("vendor/wheels-sentry/tests", true)).toBe("vendor.wheels-sentry.tests");
			});

		});

		describe("$testScopeProblem (issues 3963, 3893)", () => {

			it("accepts the default scope", () => {
				expect(mod.$testScopeProblem("")).toBe("");
			});

			it("accepts a folder or spec file that exists", () => {
				expect(mod.$testScopeProblem("tests.specs.models")).toBe("");
				expect(mod.$testScopeProblem("tests.specs.models.BookSpec")).toBe("");
				expect(mod.$testScopeProblem("tests")).toBe("");
				expect(mod.$testScopeProblem("wheels.tests.specs.model", true)).toBe("");
				expect(mod.$testScopeProblem("vendor.wheels-sentry.tests", true)).toBe("");
			});

			it("refuses a scope that names nothing, naming the scope and the accepted forms", () => {
				var problem = mod.$testScopeProblem("tests.specs.nope", false, "tests/specs/nope");
				expect(problem).toInclude("'tests/specs/nope'");
				expect(problem).toInclude("tests/specs/nope.cfc");
				expect(problem).toInclude("--filter=");
				expect(problem).toInclude("Nothing was run");
			});

			it("refuses a scope the runner would reject", () => {
				var problem = mod.$testScopeProblem("tests.specs.models;x");
				expect(problem).toInclude("is not a test scope");
				expect(problem).toInclude("Nothing was run");
				expect(mod.$testScopeProblem("tests.specs..models")).toInclude("is not a test scope");
				expect(mod.$testScopeProblem("tests.specs.models", true)).toInclude("is not a test scope");
			});

		});

		describe("wheels test refuses an unmatched scope before running (issues 3963, 3893)", () => {

			it("refuses a nonexistent path scope", () => {
				var result = refusal({filter = "tests/specs/nope"});
				expect(result.type).toBe("Wheels.TestScopeNotFound");
				expect(result.message).toInclude("'tests/specs/nope'");
			});

			it("refuses a nonexistent dotted scope", () => {
				var result = refusal({filter = "tests.specs.nope"});
				expect(result.type).toBe("Wheels.TestScopeNotFound");
			});

			it("refuses a rejected directory passed as directory= (the MCP test tool)", () => {
				var result = refusal({directory = "tests.specs.models;x"});
				expect(result.type).toBe("Wheels.TestScopeNotFound");
				expect(result.message).toInclude("is not a test scope");
			});

		});

	}

}
