// Covers all four validate() exit paths; each case gets its own temp project.
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.roots = [];

		// Missing extends="Model" → Analysis.validateModel error → results.valid = false.
		variables.errorRoot = $makeProject();
		fileWrite(variables.errorRoot & "/app/models/Bad.cfc", "component { function config() {} }");
		variables.errorMod = new cli.lucli.Module(cwd = variables.errorRoot);

		// Project with no offending files at all.
		variables.cleanRoot = $makeProject();
		variables.cleanMod = new cli.lucli.Module(cwd = variables.cleanRoot);

		// Hash without cfparam → validateView warning; results.valid stays true.
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

	// vendor/wheels stub anchors resolveProjectRoot to the temp dir.
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
