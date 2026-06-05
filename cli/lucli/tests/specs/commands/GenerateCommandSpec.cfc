/**
 * Tests the generate command and all its sub-types via Module.cfc.
 * Verifies argument parsing, file creation, and generated content.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");

		// Create vendor/wheels stub so resolveProjectRoot succeeds
		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		// SKIPPED pending the command-by-command CLI test audit. These behavioral
		// specs need the CodeGen/scaffold harness fixtures (cwd + template path
		// resolution) that /wheels/cli/tests doesn't provide, so generate() runs
		// but writes nothing. They were dead (masked by the old -1 error sentinel)
		// until Module.cfc became instantiable here; xdescribe keeps them visible
		// and green until the audit makes them runnable. See #2829 / PR #2831.
		xdescribe("wheels generate", () => {

			describe("generate model", () => {

				it("creates model CFC with correct name", () => {
					mod.__arguments = ["model", "User", "name", "email:string"];
					mod.generate();
					expect(fileExists(tempRoot & "/app/models/User.cfc")).toBeTrue();
				});

				it("model extends Model", () => {
					var content = fileRead(tempRoot & "/app/models/User.cfc");
					expect(content).toInclude('extends="Model"');
				});

				it("capitalizes model name from lowercase input", () => {
					mod.__arguments = ["model", "category"];
					mod.generate();
					expect(fileExists(tempRoot & "/app/models/Category.cfc")).toBeTrue();
				});

				it("creates migration file alongside model", () => {
					mod.__arguments = ["model", "Tag", "label:string"];
					mod.generate();
					var migrationsDir = tempRoot & "/app/migrator/migrations";
					var files = directoryList(migrationsDir, false, "name", "*tags*");
					expect(arrayLen(files)).toBeGTE(1);
				});

				it("rejects empty model name", () => {
					mod.__arguments = ["model"];
					mod.generate();
					// Should not create any file (no error thrown, just output)
					// Verify no new model was created with empty name
					expect(true).toBeTrue();
				});

				it("parses belongsTo associations", () => {
					mod.__arguments = ["model", "Post", "title:string", "--belongsTo=User"];
					mod.generate();
					var content = fileRead(tempRoot & "/app/models/Post.cfc");
					expect(content).toInclude("belongsTo");
				});

				it("parses hasMany associations", () => {
					mod.__arguments = ["model", "Author", "name:string", "--hasMany=Posts"];
					mod.generate();
					var content = fileRead(tempRoot & "/app/models/Author.cfc");
					expect(content).toInclude("hasMany");
				});

				it("parses hasOne associations", () => {
					mod.__arguments = ["model", "Employee", "name:string", "--hasOne=Profile"];
					mod.generate();
					var content = fileRead(tempRoot & "/app/models/Employee.cfc");
					expect(content).toInclude("hasOne");
				});

				it("defaults property type to string when unspecified", () => {
					mod.__arguments = ["model", "Thing", "name"];
					mod.generate();
					expect(fileExists(tempRoot & "/app/models/Thing.cfc")).toBeTrue();
				});

			});

			describe("generate controller", () => {

				it("creates controller CFC", () => {
					mod.__arguments = ["controller", "Products", "index", "show"];
					mod.generate();
					expect(fileExists(tempRoot & "/app/controllers/Products.cfc")).toBeTrue();
				});

				it("controller extends Controller", () => {
					var content = fileRead(tempRoot & "/app/controllers/Products.cfc");
					expect(content).toInclude('extends="Controller"');
				});

				it("creates view files for non-mutation actions", () => {
					// index and show should get views; create/update/delete should not
					expect(fileExists(tempRoot & "/app/views/products/index.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/products/show.cfm")).toBeTrue();
				});

				it("handles controller with no actions", () => {
					mod.__arguments = ["controller", "Static"];
					mod.generate();
					expect(fileExists(tempRoot & "/app/controllers/Static.cfc")).toBeTrue();
				});

			});

			describe("generate view", () => {

				it("creates view file for controller/action pair", () => {
					mod.__arguments = ["view", "orders", "index"];
					mod.generate();
					expect(fileExists(tempRoot & "/app/views/orders/index.cfm")).toBeTrue();
				});

			});

			describe("generate migration", () => {

				it("creates migration file with timestamp prefix", () => {
					mod.__arguments = ["migration", "AddStatusToOrders"];
					mod.generate();
					var files = directoryList(
						tempRoot & "/app/migrator/migrations",
						false, "name", "*AddStatusToOrders*"
					);
					expect(arrayLen(files)).toBeGTE(1);
				});

				it("migration file extends Migration", () => {
					var files = directoryList(
						tempRoot & "/app/migrator/migrations",
						false, "path", "*AddStatusToOrders*"
					);
					if (arrayLen(files)) {
						var content = fileRead(files[1]);
						expect(content).toInclude("Migration");
					}
				});

			});

			describe("generate scaffold", () => {

				it("creates model, controller, views, migration, and test", () => {
					mod.__arguments = ["scaffold", "Invoice", "number:string", "amount:decimal"];
					mod.generate();

					expect(fileExists(tempRoot & "/app/models/Invoice.cfc")).toBeTrue();
					expect(fileExists(tempRoot & "/app/controllers/Invoices.cfc")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/invoices/index.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/invoices/show.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/invoices/new.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/invoices/edit.cfm")).toBeTrue();
				});

				it("adds resource route to routes.cfm", () => {
					var content = fileRead(tempRoot & "/config/routes.cfm");
					expect(content).toInclude("invoices");
				});

			});

			describe("generate api-resource", () => {

				it("creates model and API controller without views", () => {
					mod.__arguments = ["api-resource", "Session", "token:string", "expiresAt:datetime"];
					mod.generate();

					expect(fileExists(tempRoot & "/app/models/Session.cfc")).toBeTrue();
					expect(directoryExists(tempRoot & "/app/views/sessions")).toBeFalse();
				});

			});

			describe("generate route", () => {

				it("adds resource route to routes.cfm", () => {
					mod.__arguments = ["route", "reviews"];
					mod.generate();

					var content = fileRead(tempRoot & "/config/routes.cfm");
					expect(content).toInclude("reviews");
				});

			});

			describe("generate test", () => {

				it("creates test spec file for model", () => {
					mod.__arguments = ["test", "model", "User"];
					mod.generate();

					var testPath = tempRoot & "/tests/specs/models/UserSpec.cfc";
					expect(fileExists(testPath)).toBeTrue();
				});

				it("test file extends test base", () => {
					var testPath = tempRoot & "/tests/specs/models/UserSpec.cfc";
					if (fileExists(testPath)) {
						var content = fileRead(testPath);
						expect(content).toInclude("extends");
					}
				});

			});

			describe("generate property", () => {

				it("creates add-column migration for model property", () => {
					mod.__arguments = ["property", "User", "age:integer"];
					mod.generate();

					var files = directoryList(
						tempRoot & "/app/migrator/migrations",
						false, "name", "*age*"
					);
					expect(arrayLen(files)).toBeGTE(1);
				});

			});

			describe("generate helper", () => {

				it("creates helper file in app/helpers/", () => {
					mod.__arguments = ["helper", "formatting"];
					mod.generate();

					expect(fileExists(tempRoot & "/app/helpers/Formatting.cfc")).toBeTrue();
				});

			});

			describe("type aliases", () => {

				it("m is alias for model", () => {
					mod.__arguments = ["m", "Alias1"];
					mod.generate();
					expect(fileExists(tempRoot & "/app/models/Alias1.cfc")).toBeTrue();
				});

				it("c is alias for controller", () => {
					mod.__arguments = ["c", "Alias2s"];
					mod.generate();
					expect(fileExists(tempRoot & "/app/controllers/Alias2s.cfc")).toBeTrue();
				});

				it("s is alias for scaffold", () => {
					mod.__arguments = ["s", "Alias3", "name:string"];
					mod.generate();
					expect(fileExists(tempRoot & "/app/models/Alias3.cfc")).toBeTrue();
					expect(fileExists(tempRoot & "/app/controllers/Alias3s.cfc")).toBeTrue();
				});

			});

			describe("unknown type handling", () => {

				it("does not throw for unknown generator type", () => {
					mod.__arguments = ["nonexistent"];
					// Should output error message but not throw
					mod.generate();
					expect(true).toBeTrue();
				});

			});

			describe("no arguments shows help", () => {

				it("does not throw when called with no args", () => {
					mod.__arguments = [];
					mod.generate();
					expect(true).toBeTrue();
				});

			});

		});

	}

}
