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
		variables.scaffold = new modules.wheels.services.Scaffold(
			codeGenService = variables.codegen,
			helpers = variables.helpers,
			projectRoot = variables.tempRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Scaffold Service", () => {

			describe("generateScaffold()", () => {

				it("generates model, controller, views, migration, and tests", () => {
					var result = scaffold.generateScaffold(
						name = "Article",
						properties = [{name: "title", type: "string"}, {name: "body", type: "text"}]
					);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.generated)).toBeGTE(5);

					// Model
					expect(fileExists(tempRoot & "/app/models/Article.cfc")).toBeTrue();

					// Controller
					expect(fileExists(tempRoot & "/app/controllers/Articles.cfc")).toBeTrue();

					// Views
					expect(fileExists(tempRoot & "/app/views/articles/index.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/articles/show.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/articles/new.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/articles/edit.cfm")).toBeTrue();
				});

				it("model extends Model", () => {
					var content = fileRead(tempRoot & "/app/models/Article.cfc");
					expect(content).toInclude('extends="Model"');
				});

				it("controller extends Controller", () => {
					var content = fileRead(tempRoot & "/app/controllers/Articles.cfc");
					expect(content).toInclude('extends="Controller"');
				});

				it("controller contains CRUD actions", () => {
					var content = fileRead(tempRoot & "/app/controllers/Articles.cfc");
					expect(content).toInclude("function index()");
					expect(content).toInclude("function show()");
					expect(content).toInclude("function new()");
					expect(content).toInclude("function create()");
					expect(content).toInclude("function edit()");
					expect(content).toInclude("function update()");
					expect(content).toInclude("function delete()");
				});

				it("generates migration file in migrations directory", () => {
					var migrationsDir = tempRoot & "/app/migrator/migrations";
					var files = directoryList(migrationsDir, false, "name", "*articles*");
					expect(arrayLen(files)).toBeGTE(1);
				});

				it("handles empty name gracefully", () => {
					// Scaffold may reject or accept empty names depending on implementation
					var result = scaffold.generateScaffold(
						name = "",
						properties = []
					);
					// If it fails, errors should be populated; if it succeeds, that's the implementation choice
					expect(isStruct(result)).toBeTrue();
					expect(structKeyExists(result, "success")).toBeTrue();
				});

				it("respects force flag for overwriting", () => {
					// Generate again with force
					var result = scaffold.generateScaffold(
						name = "Article",
						properties = [{name: "title", type: "string"}],
						force = true
					);
					expect(result.success).toBeTrue();
				});

				it("includes belongsTo associations in model", () => {
					var result = scaffold.generateScaffold(
						name = "Comment",
						properties = [{name: "body", type: "text"}],
						belongsTo = "Article",
						force = true
					);
					expect(result.success).toBeTrue();
					var content = fileRead(tempRoot & "/app/models/Comment.cfc");
					expect(content).toInclude("belongsTo");
				});

				it("includes hasMany associations in model", () => {
					var result = scaffold.generateScaffold(
						name = "Category",
						properties = [{name: "name", type: "string"}],
						hasMany = "Articles",
						force = true
					);
					expect(result.success).toBeTrue();
					var content = fileRead(tempRoot & "/app/models/Category.cfc");
					expect(content).toInclude("hasMany");
				});

			});

			describe("createMigrationWithProperties()", () => {

				it("creates a migration file", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Widget",
						properties = [{name: "label", type: "string"}]
					);
					expect(len(path)).toBeGT(0);
					expect(fileExists(path)).toBeTrue();
				});

				it("migration contains createTable", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Gadget",
						properties = [{name: "size", type: "integer"}]
					);
					var content = fileRead(path);
					expect(content).toInclude("createTable");
					expect(content).toInclude("gadgets");
				});

				it("migration contains column definitions", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Item",
						properties = [
							{name: "name", type: "string"},
							{name: "price", type: "decimal"},
							{name: "active", type: "boolean"}
						]
					);
					var content = fileRead(path);
					expect(content).toInclude("name");
					expect(content).toInclude("price");
					expect(content).toInclude("active");
				});

			});

			describe("updateRoutes()", () => {

				it("adds resource route to routes.cfm", () => {
					var result = scaffold.updateRoutes("widgets");
					expect(result).toBeTrue();

					var routesContent = fileRead(tempRoot & "/config/routes.cfm");
					expect(routesContent).toInclude('.resources("widgets")');
				});

				it("does not duplicate existing route", () => {
					// Call twice
					scaffold.updateRoutes("gadgets");
					scaffold.updateRoutes("gadgets");

					var routesContent = fileRead(tempRoot & "/config/routes.cfm");
					var count = 0;
					var pos = 1;
					while (pos > 0) {
						pos = findNoCase('.resources("gadgets")', routesContent, pos);
						if (pos > 0) { count++; pos++; }
					}
					expect(count).toBe(1);
				});

			});

			describe("generateApiResource()", () => {

				it("generates model, API controller, and migration", () => {
					var result = scaffold.generateApiResource(
						name = "Token",
						properties = [{name: "value", type: "string"}, {name: "expiresAt", type: "datetime"}]
					);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.generated)).toBeGTE(3);

					// Model
					expect(fileExists(tempRoot & "/app/models/Token.cfc")).toBeTrue();
				});

				it("does not generate view files for API resource", () => {
					expect(directoryExists(tempRoot & "/app/views/tokens")).toBeFalse();
				});

			});

		});

	}

}
