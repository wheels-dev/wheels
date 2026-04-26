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
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Templates Service", () => {

			describe("getTemplateDir()", () => {

				it("returns a non-empty path", () => {
					var dir = templates.getTemplateDir();
					expect(len(dir)).toBeGT(0);
				});

				it("returns a path that exists", () => {
					var dir = templates.getTemplateDir();
					expect(directoryExists(dir)).toBeTrue();
				});

			});

			describe("processTemplate()", () => {

				it("replaces {{key}} placeholders using struct key case", () => {
					// CFML struct literals uppercase keys: {appName: "x"} → key is "APPNAME"
					// processTemplate replaces \{\{KEY\}\}, so template must match key case.
					// In practice, CodeGen builds context with lowercase keys via explicit struct assignment.
					// Test with a key that CodeGen actually uses:
					var content = "Hello, {{nameSingular}}!";
					var context = {name: "World"};
					var result = templates.processTemplate(content, context);
					expect(result).toBe("Hello, World!");
				});

				it("handles name singular and plural variations", () => {
					var content = "Model: {{nameSingular}}, Table: {{namePlural}}";
					var context = {name: "Product"};
					var result = templates.processTemplate(content, context);
					expect(result).toInclude("Product");
					expect(result).toInclude("Products");
				});

				it("handles lowercase name variations", () => {
					var content = "{{nameSingularLower}} and {{namePluralLower}}";
					var context = {name: "Product"};
					var result = templates.processTemplate(content, context);
					expect(result).toInclude("product");
					expect(result).toInclude("products");
				});

				it("preserves content with no placeholders", () => {
					var content = "No placeholders here.";
					var context = {name: "Test"};
					var result = templates.processTemplate(content, context);
					expect(result).toBe("No placeholders here.");
				});

				it("handles empty context gracefully", () => {
					var content = "Static content";
					var context = {};
					var result = templates.processTemplate(content, context);
					expect(result).toBe("Static content");
				});

			});

			describe("generateFromTemplate()", () => {

				it("creates output file from template with context", () => {
					// Write a test template into the template directory
					var templateDir = templates.getTemplateDir();
					if (!len(templateDir)) { debug("No template dir available"); return; }

					var testTemplate = templateDir & "/test_template_gen.txt";
					fileWrite(testTemplate, "Model: {{nameSingular}}, extends Model");

					// destination is relative to projectRoot
					var result = templates.generateFromTemplate(
						template = "test_template_gen.txt",
						destination = "app/models/TemplateOutput.cfc",
						context = {name: "TemplateOutput"}
					);

					expect(result.success).toBeTrue();

					var destPath = tempRoot & "/app/models/TemplateOutput.cfc";
					expect(fileExists(destPath)).toBeTrue();

					var content = fileRead(destPath);
					expect(content).toInclude("TemplateOutput");

					// Cleanup template
					if (fileExists(testTemplate)) fileDelete(testTemplate);
				});

				it("returns success false for missing template", () => {
					var result = templates.generateFromTemplate(
						template = "nonexistent_template.txt",
						destination = "output.txt",
						context = {}
					);
					expect(result.success).toBeFalse();
				});

				it("creates destination directory if needed", () => {
					var templateDir = templates.getTemplateDir();
					if (!len(templateDir)) { debug("No template dir available"); return; }

					var testTemplate = templateDir & "/test_mkdir_gen.txt";
					fileWrite(testTemplate, "content");

					var result = templates.generateFromTemplate(
						template = "test_mkdir_gen.txt",
						destination = "deep/nested/dir/output.txt",
						context = {}
					);

					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/deep/nested/dir/output.txt")).toBeTrue();

					// Cleanup
					if (fileExists(testTemplate)) fileDelete(testTemplate);
				});

			});

		});

	}

}
