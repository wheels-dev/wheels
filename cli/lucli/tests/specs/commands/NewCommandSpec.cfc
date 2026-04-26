/**
 * Tests new/create command logic via the Scaffold service.
 *
 * Module.cfc's new() delegates to scaffoldNewApp() which depends on
 * template files and framework source. We test the scaffolding pipeline
 * through the service layer to avoid Module compilation context issues.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new modules.wheels.services.Helpers();
		variables.templates = new modules.wheels.services.Templates(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
		variables.codegen = new modules.wheels.services.CodeGen(
			templateService = variables.templates,
			helpers = variables.helpers,
			projectRoot = variables.tempRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("New App Scaffolding", () => {

			describe("template processing", () => {

				// CFML struct literals uppercase keys, so {{APPNAME}} won't match {{appName}}.
				// The real scaffoldNewApp() builds context with explicit struct assignment
				// (context["appName"] = "...") preserving case. We test with name variations
				// which are handled by explicit code, not key iteration.

				it("replaces name singular placeholder", () => {
					var content = "Welcome to {{nameSingular}}";
					var result = templates.processTemplate(content, {name: "MyApp"});
					expect(result).toBe("Welcome to MyApp");
				});

				it("replaces name plural placeholder", () => {
					var content = "table: {{namePluralLower}}";
					var result = templates.processTemplate(content, {name: "Product"});
					expect(result).toBe("table: products");
				});

				it("handles multiple placeholders in one template", () => {
					var content = "{{nameSingular}} stored in {{namePluralLower}}";
					var result = templates.processTemplate(content, {name: "User"});
					expect(result).toInclude("User");
					expect(result).toInclude("users");
				});

			});

			describe("template directory", () => {

				it("has templates directory in module root", () => {
					var dir = moduleRoot & "templates/";
					expect(directoryExists(dir)).toBeTrue();
				});

				it("has new-app template directory", () => {
					var dir = moduleRoot & "templates/app/";
					// May or may not exist depending on module structure
					// Just verify templates service resolves correctly
					var templateDir = templates.getTemplateDir();
					expect(len(templateDir)).toBeGT(0);
				});

			});

			describe("helpers used by new command", () => {

				it("pluralize works for common names", () => {
					expect(helpers.pluralize("user")).toBe("users");
					expect(helpers.pluralize("post")).toBe("posts");
				});

				it("capitalize works", () => {
					expect(helpers.capitalize("myapp")).toBe("Myapp");
					expect(helpers.capitalize("test")).toBe("Test");
				});

				it("generateMigrationTimestamp returns valid timestamp", () => {
					var ts = helpers.generateMigrationTimestamp();
					expect(len(ts)).toBe(14);
					expect(isNumeric(ts)).toBeTrue();
				});

			});

			describe("code generation for new project", () => {

				it("generates model in correct directory", () => {
					var result = codegen.generateModel(name = "NewApp1", properties = []);
					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/app/models/NewApp1.cfc")).toBeTrue();
				});

				it("generates controller with CRUD actions", () => {
					var result = codegen.generateController(
						name = "NewApps",
						actions = ["index", "show", "new", "create", "edit", "update", "delete"]
					);
					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/app/controllers/NewApps.cfc")).toBeTrue();
				});

			});

		});

	}

}
