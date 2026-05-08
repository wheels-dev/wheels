component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new cli.lucli.services.Helpers();
		variables.destroy = new cli.lucli.services.Destroy(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Destroy Service", () => {

			describe("destroyModel()", () => {

				it("deletes model file and generates migration", () => {
					// Create a model file to destroy
					var modelPath = tempRoot & "/app/models/Deleteme.cfc";
					directoryCreate(getDirectoryFromPath(modelPath), true, true);
					fileWrite(modelPath, 'component extends="Model" {}');

					var result = destroy.destroyModel("Deleteme");
					expect(result.success).toBeTrue();
					expect(fileExists(modelPath)).toBeFalse();
					expect(len(result.migrationPath)).toBeGT(0);
					expect(fileExists(result.migrationPath)).toBeTrue();

					// Verify migration content
					var migContent = fileRead(result.migrationPath);
					expect(migContent).toInclude("dropTable");
					expect(migContent).toInclude("deletemes");
				});

				it("warns when model file does not exist", () => {
					var result = destroy.destroyModel("Nonexistent");
					expect(result.success).toBeTrue();
					expect(arrayLen(result.warnings)).toBeGT(0);
				});

			});

			describe("destroyController()", () => {

				it("deletes controller, views directory, and test files (##2330)", () => {
					var controllerPath = tempRoot & "/app/controllers/Deletemes.cfc";
					var viewsDir = tempRoot & "/app/views/deletemes";
					// Generator writes <name>ControllerSpec.cfc (CodeGen.cfc
					// suffix = "ControllerSpec"); destroy must use the same
					// name. See issue ##2492.
					var testPath = tempRoot & "/tests/specs/controllers/DeletemesControllerSpec.cfc";
					directoryCreate(getDirectoryFromPath(controllerPath), true, true);
					directoryCreate(viewsDir, true, true);
					fileWrite(viewsDir & "/index.cfm", "<p>i</p>");
					directoryCreate(getDirectoryFromPath(testPath), true, true);
					fileWrite(controllerPath, 'component extends="Controller" {}');
					fileWrite(testPath, 'component {}');

					// Input matches the controller filename verbatim — destroy
					// no longer pluralises (which used to produce wrong target
					// filenames for non-conventional names; see #2330).
					var result = destroy.destroyController("Deletemes");
					expect(fileExists(controllerPath)).toBeFalse();
					expect(directoryExists(viewsDir)).toBeFalse();
					expect(fileExists(testPath)).toBeFalse();
				});

				it("preserves PascalCase for non-conventional names (##2330 side-finding)", () => {
					// The previous implementation pluralised + lowercased then
					// recapitalised, mangling `WidgetTest` into `Widgettests`
					// which never matched the actually-generated file.
					var controllerPath = tempRoot & "/app/controllers/WidgetTest.cfc";
					var viewsDir = tempRoot & "/app/views/widgettest";
					directoryCreate(getDirectoryFromPath(controllerPath), true, true);
					directoryCreate(viewsDir, true, true);
					fileWrite(controllerPath, 'component extends="Controller" {}');

					var result = destroy.destroyController("WidgetTest");
					expect(fileExists(controllerPath)).toBeFalse();
					expect(directoryExists(viewsDir)).toBeFalse();
				});

				it("does not generate a migration", () => {
					var result = destroy.destroyController("Deletemes");
					expect(structKeyExists(result, "migrationPath")).toBeFalse();
				});

			});

			describe("destroyResource()", () => {

				it("deletes all resource files and cleans up route", () => {
					// Create resource files
					var modelPath = tempRoot & "/app/models/Widget.cfc";
					var controllerPath = tempRoot & "/app/controllers/Widgets.cfc";
					var viewsDir = tempRoot & "/app/views/widgets";
					var modelTestPath = tempRoot & "/tests/specs/models/WidgetSpec.cfc";
					var controllerTestPath = tempRoot & "/tests/specs/controllers/WidgetsControllerSpec.cfc";
					var viewTestsDir = tempRoot & "/tests/specs/views/widgets";

					directoryCreate(getDirectoryFromPath(modelPath), true, true);
					directoryCreate(getDirectoryFromPath(controllerPath), true, true);
					directoryCreate(viewsDir, true, true);
					directoryCreate(getDirectoryFromPath(modelTestPath), true, true);
					directoryCreate(getDirectoryFromPath(controllerTestPath), true, true);
					directoryCreate(viewTestsDir, true, true);

					fileWrite(modelPath, 'component extends="Model" {}');
					fileWrite(controllerPath, 'component extends="Controller" {}');
					fileWrite(viewsDir & "/index.cfm", "<p>index</p>");
					fileWrite(modelTestPath, 'component {}');
					fileWrite(controllerTestPath, 'component {}');
					fileWrite(viewTestsDir & "/indexSpec.cfc", 'component {}');

					// Add route
					var routesPath = tempRoot & "/config/routes.cfm";
					var routeContent = fileRead(routesPath);
					routeContent = replace(routeContent, "// CLI-Appends-Here",
						'.resources("widgets")' & chr(10) & chr(9) & chr(9) & "// CLI-Appends-Here");
					fileWrite(routesPath, routeContent);

					var result = destroy.destroyResource("Widget");
					expect(fileExists(modelPath)).toBeFalse();
					expect(fileExists(controllerPath)).toBeFalse();
					expect(directoryExists(viewsDir)).toBeFalse();
					expect(fileExists(modelTestPath)).toBeFalse();
					expect(fileExists(controllerTestPath)).toBeFalse();
					expect(directoryExists(viewTestsDir)).toBeFalse();
					expect(len(result.migrationPath)).toBeGT(0);

					// Verify route removed
					var updatedRoutes = fileRead(routesPath);
					expect(updatedRoutes).notToInclude('.resources("widgets")');
				});

			});

			describe("destroyView()", () => {

				it("deletes a single view file when path contains /", () => {
					var viewDir = tempRoot & "/app/views/items";
					directoryCreate(viewDir, true, true);
					fileWrite(viewDir & "/show.cfm", "<p>show</p>");

					var result = destroy.destroyView("items/show");
					expect(fileExists(viewDir & "/show.cfm")).toBeFalse();
					// Directory should still exist
					expect(directoryExists(viewDir)).toBeTrue();
				});

				it("deletes entire view directory when no /", () => {
					var viewDir = tempRoot & "/app/views/things";
					directoryCreate(viewDir, true, true);
					fileWrite(viewDir & "/index.cfm", "<p>index</p>");

					var result = destroy.destroyView("Thing");
					expect(directoryExists(viewDir)).toBeFalse();
				});

				it("returns error for invalid view path", () => {
					var result = destroy.destroyView("invalid/");
					expect(result.success).toBeFalse();
				});

			});

			describe("previewDestroy()", () => {

				it("returns expected items for resource type", () => {
					var preview = destroy.previewDestroy("Product", "resource");
					expect(arrayLen(preview)).toBeGTE(6);
					expect(arrayToList(preview)).toInclude("Product.cfc");
					expect(arrayToList(preview)).toInclude("Products.cfc");
					expect(arrayToList(preview)).toInclude("drop table");
				});

				it("returns expected items for controller type (##2330)", () => {
					// 3 items: controller .cfc, views/ directory, controller spec.
					// Issue #2330 added the views directory to controller destroy.
					var preview = destroy.previewDestroy("Products", "controller");
					expect(arrayLen(preview)).toBe(3);
					expect(arrayToList(preview)).toInclude("Products.cfc");
					expect(arrayToList(preview)).toInclude("app/views/products/");
					expect(arrayToList(preview)).toInclude("ProductsControllerSpec.cfc");
				});

			});

		});

	}

}
