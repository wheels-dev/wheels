/**
 * Tests the validate command's exit-code behaviour via Module.cfc.
 *
 * `wheels validate` must exit non-zero when validation finds errors so CI
 * can gate on it (framework review H5). LuCLI maps an uncaught throw to a
 * non-zero exit, so these specs use toThrow as the exit-code proxy — the
 * same convention as the migrate/db/generate exit-code fixes (#2890) and
 * the runTests Wheels.TestsFailed throw (CLI audit H6).
 *
 * Each case gets its own minimal temp project and Module instance so the
 * fixtures can't contaminate each other (the analysis service is cached
 * per Module with its projectRoot baked in).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.roots = [];

		// Project whose model is missing extends="Model" → severity "error"
		// from Analysis.validateModel → results.valid = false.
		variables.errorRoot = $makeProject();
		fileWrite(variables.errorRoot & "/app/models/Bad.cfc", "component { function config() {} }");
		variables.errorMod = new cli.lucli.Module(cwd = variables.errorRoot);

		// Project with no offending files at all.
		variables.cleanRoot = $makeProject();
		variables.cleanMod = new cli.lucli.Module(cwd = variables.cleanRoot);

		// Project whose only issue is a warning: a view that uses ## without
		// any cfparam/cfset (Analysis.validateView severity "warning").
		// results.valid stays true, so validate must NOT throw.
		variables.warningRoot = $makeProject();
		directoryCreate(variables.warningRoot & "/app/views/things", true, true);
		fileWrite(variables.warningRoot & "/app/views/things/index.cfm", "<p>##foo##</p>");
		variables.warningMod = new cli.lucli.Module(cwd = variables.warningRoot);

		// Project root with no app/ directory — user-error path.
		variables.noAppRoot = $makeProject(includeApp = false);
		variables.noAppMod = new cli.lucli.Module(cwd = variables.noAppRoot);
	}

	function afterAll() {
		for (var root in variables.roots) {
			if (len(root) > 10 && directoryExists(root)) {
				directoryDelete(root, true);
			}
		}
	}

	/**
	 * Build a minimal temp project. The vendor/wheels stub anchors
	 * resolveProjectRoot so the Module treats the temp dir itself as the
	 * project root instead of walking up to the repo checkout.
	 */
	private string function $makeProject(boolean includeApp = true) {
		var root = getTempDirectory() & "wheels-cli-validate-" & createUUID();
		directoryCreate(root & "/vendor/wheels", true, true);
		if (arguments.includeApp) {
			directoryCreate(root & "/app/models", true, true);
			directoryCreate(root & "/app/controllers", true, true);
			directoryCreate(root & "/app/views", true, true);
			directoryCreate(root & "/config", true, true);
		}
		arrayAppend(variables.roots, root);
		return root;
	}

	function run() {

		describe("wheels validate exit codes", () => {

			it("throws Wheels.ValidationFailed when validation finds errors", () => {
				expect(() => variables.errorMod.validate()).toThrow(type = "Wheels.ValidationFailed");
			});

			it("returns normally on a clean project", () => {
				variables.cleanMod.validate();
				expect(true).toBeTrue();
			});

			it("stays green when only warnings exist", () => {
				variables.warningMod.validate();
				expect(true).toBeTrue();
			});

			it("throws Wheels.InvalidArguments when no app directory exists", () => {
				expect(() => variables.noAppMod.validate()).toThrow(type = "Wheels.InvalidArguments");
			});

		});

	}

}
