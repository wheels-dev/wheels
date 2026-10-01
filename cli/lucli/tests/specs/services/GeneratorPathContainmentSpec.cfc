/**
 * Generator names become file paths. A generated file must always land inside
 * the project, and names that are not identifiers (or view action names) are
 * refused before anything is written.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new cli.lucli.services.Helpers();
		variables.templates = new cli.lucli.services.Templates(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
		variables.codegen = new cli.lucli.services.CodeGen(
			templateService = variables.templates,
			helpers = variables.helpers,
			projectRoot = variables.tempRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private string function $canonical(required string path) {
		return createObject("java", "java.io.File").init(arguments.path).getCanonicalPath();
	}

	private string function $errorType(required any fn) {
		try {
			arguments.fn();
		} catch (any e) {
			return e.type;
		}
		return "";
	}

	function run() {
		describe("Generator path containment", () => {

			it("refuses a view whose controller name climbs out of the project", () => {
				var marker = "outside-" & lCase(left(createUUID(), 8));
				var escaped = $canonical(tempRoot & "/app/views/../../../" & marker);
				var type = $errorType(() => codegen.generateView(name = "../../../" & marker, action = "index"));
				var written = directoryExists(escaped);
				if (written) directoryDelete(escaped, true);
				expect(written).toBeFalse();
				expect(type).toBe("Wheels.Generate.InvalidName");
			});

			it("refuses a view action name that is a path", () => {
				var type = $errorType(() => codegen.generateView(name = "Users", action = "../../../../stray"));
				expect(type).toBe("Wheels.Generate.InvalidName");
			});

			it("refuses a controller name with a parent-directory segment", () => {
				var type = $errorType(() => codegen.generateController(name = "../../Stray", actions = ["index"]));
				expect(type).toBe("Wheels.Generate.InvalidName");
				expect(fileExists($canonical(tempRoot & "/app/controllers/../../Stray.cfc"))).toBeFalse();
			});

			it("refuses a template destination outside the project", () => {
				var type = $errorType(() => templates.generateFromTemplate(
					template = "ViewContent.txt",
					destination = "../outside-template.cfm",
					context = {controllerName: "Users", modelName: "User", action: "index"}
				));
				expect(type).toBe("Wheels.Generate.OutsideProject");
				expect(fileExists($canonical(tempRoot & "/../outside-template.cfm"))).toBeFalse();
			});

			it("refuses names ending in a line feed, carriage return or tab", () => {
				var paths = new cli.lucli.services.GeneratorPaths();
				for (var ending in [chr(10), chr(13), chr(9)]) {
					expect($errorType(() => paths.componentName("Users" & ending, "controller"))).toBe("Wheels.Generate.InvalidName");
					expect($errorType(() => paths.identifier("email" & ending, "property"))).toBe("Wheels.Generate.InvalidName");
					expect($errorType(() => paths.viewAction("index" & ending))).toBe("Wheels.Generate.InvalidName");
				}
			});

			it("still generates a package-prefixed controller and a partial view", () => {
				var ctl = codegen.generateController(name = "api/Widgets", actions = ["index"]);
				expect(ctl.success).toBeTrue();
				expect(fileExists(tempRoot & "/app/controllers/api/Widgets.cfc")).toBeTrue();
				var partial = codegen.generateView(name = "Widgets", action = "_form");
				expect(partial.success).toBeTrue();
				expect(fileExists(tempRoot & "/app/views/widgets/_form.cfm")).toBeTrue();
			});
		});
	}
}
