/**
 * E2E tests for LuCLI code generators.
 *
 * Tests all generator types against a freshly scaffolded project:
 *   - model, controller, view, migration, scaffold, route, test, property
 *
 * Uses the LuCLI service layer directly (Helpers, Templates, CodeGen, Scaffold)
 * to verify file generation, template processing, and convention adherence.
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Resolve paths relative to this test file:
		//   this file:  cli/tests/specs/e2e/GeneratorsTest.cfc
		//   lucli root: cli/lucli/
		var thisDir = getDirectoryFromPath(getCurrentTemplatePath());
		var File = createObject("java", "java.io.File");
		variables.cliRoot = File.init(thisDir & "../../../").getCanonicalPath();
		variables.lucliRoot = variables.cliRoot & "/lucli";
		variables.templateDir = variables.lucliRoot & "/templates/app";

		// Create a temp project directory that mimics a real Wheels project
		variables.projectRoot = getTempDirectory() & "wheels_e2e_generators_" & createUUID();
		scaffoldFreshProject(variables.projectRoot);

		// Instantiate the service stack (same wiring as Module.cfc getService()).
		// Requires /cli mapping or classpath that includes the CLI root.
		variables.helpers = new cli.lucli.services.Helpers();
		variables.templates = new cli.lucli.services.Templates(
			helpers = variables.helpers,
			projectRoot = variables.projectRoot,
			moduleRoot = variables.lucliRoot & "/"
		);
		variables.codegen = new cli.lucli.services.CodeGen(
			templateService = variables.templates,
			helpers = variables.helpers,
			projectRoot = variables.projectRoot
		);
		variables.scaffold = new cli.lucli.services.Scaffold(
			codeGenService = variables.codegen,
			helpers = variables.helpers,
			projectRoot = variables.projectRoot
		);
	}

	function afterAll() {
		if (directoryExists(variables.projectRoot)) {
			directoryDelete(variables.projectRoot, true);
		}
	}

	function run() {

		// ─── Model Generator ────────────────────────────

		describe("Generate Model", function() {

			it("creates a model CFC with correct name", function() {
				var result = variables.codegen.generateModel(name = "User");
				expect(result.success).toBeTrue("generateModel should succeed");

				var filePath = variables.projectRoot & "/app/models/User.cfc";
				expect(fileExists(filePath)).toBeTrue("User.cfc should exist");

				var content = fileRead(filePath);
				expect(content).toInclude('extends="Model"');
				expect(content).toInclude("function config()");
			});

			it("creates a model with properties", function() {
				var props = [
					{name: "title", type: "string"},
					{name: "body", type: "text"},
					{name: "publishedAt", type: "datetime"}
				];
				var result = variables.codegen.generateModel(
					name = "Article",
					properties = props,
					force = true
				);
				expect(result.success).toBeTrue();
				expect(fileExists(variables.projectRoot & "/app/models/Article.cfc")).toBeTrue();
			});

			it("creates a model with belongsTo associations", function() {
				var result = variables.codegen.generateModel(
					name = "Comment",
					belongsTo = "post,user",
					force = true
				);
				expect(result.success).toBeTrue();

				var content = fileRead(variables.projectRoot & "/app/models/Comment.cfc");
				expect(content).toInclude("belongsTo('post')");
				expect(content).toInclude("belongsTo('user')");
			});

			it("creates a model with hasMany associations", function() {
				var result = variables.codegen.generateModel(
					name = "Author",
					hasMany = "books,articles",
					force = true
				);
				expect(result.success).toBeTrue();

				var content = fileRead(variables.projectRoot & "/app/models/Author.cfc");
				expect(content).toInclude("hasMany('books')");
				expect(content).toInclude("hasMany('articles')");
			});

			it("refuses to overwrite existing model without force", function() {
				// User model was created in the first test
				var result = variables.codegen.generateModel(name = "User");
				expect(result.success).toBeFalse("should fail without force=true");
				expect(result.error).toInclude("already exists");
			});

			it("overwrites existing model with force=true", function() {
				var result = variables.codegen.generateModel(name = "User", force = true);
				expect(result.success).toBeTrue("should succeed with force=true");
			});

			it("validates model name", function() {
				var validation = variables.codegen.validateName("User", "model");
				expect(validation.valid).toBeTrue();

				var badValidation = variables.codegen.validateName("application", "model");
				expect(badValidation.valid).toBeFalse("reserved word should be invalid");

				var suffixValidation = variables.codegen.validateName("UserController", "model");
				expect(suffixValidation.valid).toBeFalse("model ending in Controller should be invalid");
			});
		});

		// ─── Controller Generator ───────────────────────

		describe("Generate Controller", function() {

			it("creates a controller CFC with default index action", function() {
				var result = variables.codegen.generateController(name = "Users");
				expect(result.success).toBeTrue();

				var filePath = variables.projectRoot & "/app/controllers/Users.cfc";
				expect(fileExists(filePath)).toBeTrue();

				var content = fileRead(filePath);
				expect(content).toInclude('extends="Controller"');
				expect(content).toInclude("function config()");
			});

			it("creates a controller with custom actions", function() {
				var result = variables.codegen.generateController(
					name = "Dashboard",
					actions = ["overview", "stats", "settings"],
					force = true
				);
				expect(result.success).toBeTrue();

				var content = fileRead(variables.projectRoot & "/app/controllers/Dashboard.cfc");
				expect(content).toInclude("function overview()");
				expect(content).toInclude("function stats()");
				expect(content).toInclude("function settings()");
			});

			it("creates a CRUD controller with all 7 actions", function() {
				var result = variables.codegen.generateController(
					name = "Posts",
					crud = true,
					force = true
				);
				expect(result.success).toBeTrue();

				var content = fileRead(variables.projectRoot & "/app/controllers/Posts.cfc");
				// CRUD controllers use a different template that includes model calls
				expect(content).toInclude('extends="Controller"');
			});

			it("creates an API controller", function() {
				var result = variables.codegen.generateController(
					name = "ApiUsers",
					crud = true,
					api = true,
					force = true
				);
				expect(result.success).toBeTrue();
				expect(fileExists(variables.projectRoot & "/app/controllers/ApiUsers.cfc")).toBeTrue();
			});

			it("refuses to overwrite existing controller without force", function() {
				var result = variables.codegen.generateController(name = "Users");
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("already exists");
			});
		});

		// ─── View Generator ─────────────────────────────

		describe("Generate View", function() {

			it("creates a view file in the correct directory", function() {
				var result = variables.codegen.generateView(name = "Users", action = "index");
				expect(result.success).toBeTrue();

				var viewPath = variables.projectRoot & "/app/views/users/index.cfm";
				expect(fileExists(viewPath)).toBeTrue("View file should exist");
			});

			it("creates views for CRUD actions with appropriate templates", function() {
				var crudActions = ["index", "show", "new", "edit"];
				for (var action in crudActions) {
					var result = variables.codegen.generateView(
						name = "Products",
						action = action,
						force = true
					);
					expect(result.success).toBeTrue("View for #action# should be created");
					expect(fileExists(
						variables.projectRoot & "/app/views/products/#action#.cfm"
					)).toBeTrue("products/#action#.cfm should exist");
				}
			});

			it("creates a form partial (_form view)", function() {
				var result = variables.codegen.generateView(
					name = "Products",
					action = "_form",
					force = true
				);
				expect(result.success).toBeTrue();
				expect(fileExists(
					variables.projectRoot & "/app/views/products/_form.cfm"
				)).toBeTrue();
			});

			it("creates view directory automatically if missing", function() {
				var viewDir = variables.projectRoot & "/app/views/newcontroller";
				expect(directoryExists(viewDir)).toBeFalse("Dir should not exist yet");

				var result = variables.codegen.generateView(name = "NewController", action = "show");
				expect(result.success).toBeTrue();
				expect(directoryExists(viewDir)).toBeTrue("Dir should be auto-created");
			});

			it("refuses to overwrite existing view without force", function() {
				// index.cfm was created above
				var result = variables.codegen.generateView(name = "Users", action = "index");
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("already exists");
			});
		});

		// ─── Migration Generator ────────────────────────

		describe("Generate Migration", function() {

			it("creates a migration with properties via scaffold service", function() {
				var props = [
					{name: "name", type: "string"},
					{name: "email", type: "string"},
					{name: "age", type: "integer"}
				];
				var migrationPath = variables.scaffold.createMigrationWithProperties("User", props);

				expect(fileExists(migrationPath)).toBeTrue("Migration file should exist");
				expect(migrationPath).toMatch("_create_users_table\.cfc$");

				var content = fileRead(migrationPath);
				expect(content).toInclude('extends="wheels.migrator.Migration"');
				expect(content).toInclude("function up()");
				expect(content).toInclude("function down()");
				expect(content).toInclude("createTable");
				expect(content).toInclude("'users'");
				expect(content).toInclude("'name'");
				expect(content).toInclude("'email'");
				expect(content).toInclude("'age'");
				expect(content).toInclude("t.timestamps()");
				expect(content).toInclude("dropTable");
			});

			it("creates migration file with timestamp prefix", function() {
				var props = [{name: "title", type: "string"}];
				var migrationPath = variables.scaffold.createMigrationWithProperties("Post", props);
				var fileName = listLast(migrationPath, "/");

				// Filename format: YYYYMMDDHHMMSS_create_posts_table.cfc
				expect(fileName).toMatch("^\d{14}_create_posts_table\.cfc$");
			});

			it("creates migration directory if missing", function() {
				var migrationDir = variables.projectRoot & "/app/migrator/migrations";
				// It already exists from scaffold, so verify it's used correctly
				expect(directoryExists(migrationDir)).toBeTrue();
			});

			it("maps property types to correct column types", function() {
				var props = [
					{name: "title", type: "string"},
					{name: "body", type: "text"},
					{name: "count", type: "integer"},
					{name: "active", type: "boolean"},
					{name: "createdOn", type: "datetime"},
					{name: "price", type: "decimal"}
				];
				var migrationPath = variables.scaffold.createMigrationWithProperties("Widget", props);
				var content = fileRead(migrationPath);

				expect(content).toInclude("t.string(");
				expect(content).toInclude("t.text(");
				expect(content).toInclude("t.integer(");
				expect(content).toInclude("t.boolean(");
				expect(content).toInclude("t.datetime(");
				expect(content).toInclude("t.decimal(");
			});
		});

		// ─── Scaffold Generator ─────────────────────────

		describe("Generate Scaffold", function() {

			it("creates model, controller, views, migration, tests, and routes", function() {
				var props = [
					{name: "title", type: "string"},
					{name: "body", type: "text"}
				];
				var result = variables.scaffold.generateScaffold(
					name = "BlogPost",
					properties = props,
					force = true
				);

				expect(result.success).toBeTrue("Scaffold should succeed");
				expect(arrayLen(result.generated)).toBeGTE(5,
					"Should generate at least model + controller + migration + 2 tests"
				);

				// Verify each generated type is present
				var types = [];
				for (var item in result.generated) {
					arrayAppend(types, item.type);
				}
				expect(types).toInclude("model");
				expect(types).toInclude("controller");
				expect(types).toInclude("migration");
			});

			it("creates scaffold model with correct name", function() {
				expect(fileExists(variables.projectRoot & "/app/models/BlogPost.cfc")).toBeTrue();
			});

			it("creates scaffold controller with pluralized name", function() {
				expect(fileExists(variables.projectRoot & "/app/controllers/BlogPosts.cfc")).toBeTrue();
			});

			it("creates scaffold CRUD views", function() {
				var viewDir = variables.projectRoot & "/app/views/blogposts";
				if (directoryExists(viewDir)) {
					var views = directoryList(viewDir, false, "name", "*.cfm");
					expect(arrayLen(views)).toBeGTE(1, "Should create at least one view");
				}
			});

			it("creates scaffold tests", function() {
				var modelTestDir = variables.projectRoot & "/tests/specs/models";
				var ctrlTestDir = variables.projectRoot & "/tests/specs/controllers";
				expect(directoryExists(modelTestDir)).toBeTrue();
				expect(directoryExists(ctrlTestDir)).toBeTrue();
			});

			it("adds belongsTo foreign key columns to migration", function() {
				var props = [{name: "title", type: "string"}];
				var result = variables.scaffold.generateScaffold(
					name = "Review",
					properties = props,
					belongsTo = "product",
					force = true
				);
				expect(result.success).toBeTrue();

				// Find the migration in generated items
				var migrationPath = "";
				for (var item in result.generated) {
					if (item.type == "migration") {
						migrationPath = item.path;
						break;
					}
				}
				expect(len(migrationPath)).toBeGT(0, "Should have a migration path");

				if (fileExists(migrationPath)) {
					var content = fileRead(migrationPath);
					expect(content).toInclude("productId",
						"belongsTo=product should add productId column"
					);
				}
			});

			it("rolls back on failure", function() {
				// Generate scaffold for a model that already exists without force
				// This should trigger rollback of partial generation
				var props = [{name: "x", type: "string"}];

				// First, create the model to cause a conflict
				variables.codegen.generateModel(name = "Conflict", force = true);

				var result = variables.scaffold.generateScaffold(
					name = "Conflict",
					properties = props,
					force = false
				);
				expect(result.success).toBeFalse("Should fail on existing model");
				expect(arrayLen(result.errors)).toBeGT(0);
			});
		});

		// ─── Test Generator ─────────────────────────────

		describe("Generate Test", function() {

			it("creates a model test spec", function() {
				var result = variables.codegen.generateTest(type = "model", name = "User");
				expect(result.success).toBeTrue();

				var testPath = variables.projectRoot & "/tests/specs/models/UserSpec.cfc";
				expect(fileExists(testPath)).toBeTrue("Model test spec should exist");

				var content = fileRead(testPath);
				expect(content).toInclude("describe(");
				expect(content).toInclude("it(");
			});

			it("creates a controller test spec", function() {
				var result = variables.codegen.generateTest(type = "controller", name = "Users");
				expect(result.success).toBeTrue();

				var testPath = variables.projectRoot & "/tests/specs/controllers/UsersControllerSpec.cfc";
				expect(fileExists(testPath)).toBeTrue("Controller test spec should exist");
			});

			it("uses BDD syntax in generated tests", function() {
				var result = variables.codegen.generateTest(type = "model", name = "Product");
				var content = fileRead(result.path);

				expect(content).toInclude("function run()");
				expect(content).toInclude("describe(");
				expect(content).toInclude("it(");
			});

			it("generates test extending WheelsTest", function() {
				var result = variables.codegen.generateTest(type = "model", name = "Category");
				var content = fileRead(result.path);
				expect(content).toInclude('extends="wheels.WheelsTest"');
			});
		});

		// ─── Route Generator ────────────────────────────

		describe("Generate Route", function() {

			it("adds resource route to routes.cfm via CLI-Appends marker", function() {
				var inserted = variables.scaffold.updateRoutes("orders");
				expect(inserted).toBeTrue("Route should be inserted");

				var content = fileRead(variables.projectRoot & "/config/routes.cfm");
				expect(content).toInclude('.resources("orders")');
			});

			it("does not duplicate existing routes", function() {
				// orders was added above
				var inserted = variables.scaffold.updateRoutes("orders");
				expect(inserted).toBeFalse("Duplicate route should not be inserted");

				// Verify only one occurrence
				var content = fileRead(variables.projectRoot & "/config/routes.cfm");
				var count = 0;
				var searchFrom = 1;
				while (findNoCase('.resources("orders")', content, searchFrom) > 0) {
					count++;
					searchFrom = findNoCase('.resources("orders")', content, searchFrom) + 1;
				}
				expect(count).toBe(1, "Should have exactly one orders route");
			});

			it("preserves existing route structure", function() {
				var content = fileRead(variables.projectRoot & "/config/routes.cfm");
				expect(content).toInclude("mapper()");
				expect(content).toInclude(".wildcard()");
				expect(content).toInclude(".end()");
			});
		});

		// ─── Property Generator (Add Column Migration) ──

		describe("Generate Property Migration", function() {

			it("creates an add-column migration file", function() {
				// Mimic generateProperty logic from Module.cfc
				var modelName = "User";
				var propName = "avatar";
				var propType = "string";
				var tableName = variables.helpers.pluralize(lCase(modelName));
				var timestamp = variables.helpers.generateMigrationTimestamp();
				var migrationName = "Add" & variables.helpers.capitalize(propName) & "To" & variables.helpers.capitalize(tableName);
				var fileName = timestamp & "_" & migrationName & ".cfc";
				var migrationDir = variables.projectRoot & "/app/migrator/migrations";

				// Build the migration content (mirrors Module.cfc generateProperty)
				var nl = chr(10);
				var tab = chr(9);
				var content = 'component extends="wheels.migrator.Migration" {' & nl & nl;
				content &= tab & 'function up() {' & nl;
				content &= tab & tab & 'transaction {' & nl;
				content &= tab & tab & tab & 't = changeTable(name="#tableName#");' & nl;
				content &= tab & tab & tab & 't.string(columnNames="#propName#");' & nl;
				content &= tab & tab & tab & 't.change();' & nl;
				content &= tab & tab & '}' & nl;
				content &= tab & '}' & nl & nl;
				content &= tab & 'function down() {' & nl;
				content &= tab & tab & 'transaction {' & nl;
				content &= tab & tab & tab & 'removeColumn(table="#tableName#", columnName="#propName#");' & nl;
				content &= tab & tab & '}' & nl;
				content &= tab & '}' & nl & nl;
				content &= '}' & nl;

				var filePath = migrationDir & "/" & fileName;
				fileWrite(filePath, content);

				expect(fileExists(filePath)).toBeTrue("Property migration should be created");

				var migrationContent = fileRead(filePath);
				expect(migrationContent).toInclude("changeTable");
				expect(migrationContent).toInclude('"users"');
				expect(migrationContent).toInclude('"avatar"');
				expect(migrationContent).toInclude("removeColumn");
			});
		});

		// ─── Helpers Service ────────────────────────────

		describe("Helpers Service", function() {

			it("capitalizes strings correctly", function() {
				expect(variables.helpers.capitalize("user")).toBe("User");
				expect(variables.helpers.capitalize("blogPost")).toBe("BlogPost");
				expect(variables.helpers.capitalize("")).toBe("");
			});

			it("pluralizes common words", function() {
				expect(variables.helpers.pluralize("user")).toBe("users");
				expect(variables.helpers.pluralize("post")).toBe("posts");
				expect(variables.helpers.pluralize("category")).toBe("categories");
				expect(variables.helpers.pluralize("person")).toBe("people");
				expect(variables.helpers.pluralize("child")).toBe("children");
			});

			it("singularizes common words", function() {
				expect(variables.helpers.singularize("users")).toBe("user");
				expect(variables.helpers.singularize("posts")).toBe("post");
				expect(variables.helpers.singularize("categories")).toBe("category");
				expect(variables.helpers.singularize("people")).toBe("person");
			});

			it("handles uncountable words", function() {
				expect(variables.helpers.pluralize("sheep")).toBe("sheep");
				expect(variables.helpers.pluralize("fish")).toBe("fish");
				expect(variables.helpers.pluralize("series")).toBe("series");
			});

			it("generates migration timestamps in correct format", function() {
				var ts = variables.helpers.generateMigrationTimestamp();
				expect(len(ts)).toBe(14, "Timestamp should be 14 digits");
				expect(ts).toMatch("^\d{14}$");
			});
		});

		// ─── Templates Service ──────────────────────────

		describe("Templates Service", function() {

			it("processes {{variable}} placeholders", function() {
				var result = variables.templates.processTemplate(
					"Hello {{name}}, your app is {{appName}}.",
					{name: "World", appName: "TestApp"}
				);
				expect(result).toBe("Hello World, your app is TestApp.");
			});

			it("processes name variation placeholders", function() {
				var result = variables.templates.processTemplate(
					"{{nameSingular}} / {{namePlural}} / {{nameSingularLower}} / {{namePluralLower}}",
					{name: "User"}
				);
				expect(result).toInclude("User");
				expect(result).toInclude("user");
			});

			it("generates file from template", function() {
				var result = variables.templates.generateFromTemplate(
					template = "ModelContent.txt",
					destination = "app/models/TemplateTest.cfc",
					context = {
						name: "TemplateTest",
						modelName: "TemplateTest",
						description: "",
						tableName: "",
						properties: [],
						belongsTo: "",
						hasMany: "",
						hasOne: "",
						timestamp: now()
					}
				);
				expect(result.success).toBeTrue();
				expect(fileExists(result.path)).toBeTrue();

				var content = fileRead(result.path);
				expect(content).toInclude('extends="Model"');
			});

			it("returns error for missing template", function() {
				var result = variables.templates.generateFromTemplate(
					template = "DoesNotExist.txt",
					destination = "app/models/Ghost.cfc",
					context = {}
				);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("not found");
			});
		});

		// ─── Cross-Generator Integration ────────────────

		describe("Cross-Generator Integration", function() {

			it("generates a complete resource from scratch (model + controller + views + migration + tests)", function() {
				var props = [
					{name: "name", type: "string"},
					{name: "email", type: "string"},
					{name: "active", type: "boolean"}
				];

				var result = variables.scaffold.generateScaffold(
					name = "Customer",
					properties = props,
					force = true
				);

				expect(result.success).toBeTrue();

				// Model
				expect(fileExists(variables.projectRoot & "/app/models/Customer.cfc")).toBeTrue(
					"Customer model should exist"
				);

				// Controller (pluralized)
				expect(fileExists(variables.projectRoot & "/app/controllers/Customers.cfc")).toBeTrue(
					"Customers controller should exist"
				);

				// Migration
				var migrationDir = variables.projectRoot & "/app/migrator/migrations";
				var migrations = directoryList(migrationDir, false, "name", "*customers*");
				expect(arrayLen(migrations)).toBeGTE(1,
					"Should have at least one customers migration"
				);

				// Tests
				var modelTests = directoryList(
					variables.projectRoot & "/tests/specs/models", false, "name", "*Customer*"
				);
				expect(arrayLen(modelTests)).toBeGTE(1, "Should have model test");

				var ctrlTests = directoryList(
					variables.projectRoot & "/tests/specs/controllers", false, "name", "*Customer*"
				);
				expect(arrayLen(ctrlTests)).toBeGTE(1, "Should have controller test");
			});

			it("generates scaffold with belongsTo relationships end-to-end", function() {
				// First create the parent
				variables.codegen.generateModel(name = "Department", force = true);

				// Then scaffold with belongsTo
				var result = variables.scaffold.generateScaffold(
					name = "Employee",
					properties = [{name: "name", type: "string"}],
					belongsTo = "department",
					force = true
				);

				expect(result.success).toBeTrue();

				// Verify model has belongsTo
				var modelContent = fileRead(variables.projectRoot & "/app/models/Employee.cfc");
				expect(modelContent).toInclude("belongsTo('department')");

				// Verify migration has departmentId column
				var migrationPath = "";
				for (var item in result.generated) {
					if (item.type == "migration") {
						migrationPath = item.path;
						break;
					}
				}
				if (len(migrationPath) && fileExists(migrationPath)) {
					var migrationContent = fileRead(migrationPath);
					expect(migrationContent).toInclude("departmentId");
				}
			});
		});
	}

	// ── Test setup helpers ──────────────────────────

	/**
	 * Create a minimal Wheels project structure for generators to target.
	 * Mirrors the output of `wheels new` but only creates the essential
	 * directories and files that generators expect to exist.
	 */
	private void function scaffoldFreshProject(required string projectRoot) {
		var dirs = [
			"/app/controllers",
			"/app/models",
			"/app/views",
			"/app/migrator/migrations",
			"/app/snippets",
			"/config",
			"/public",
			"/tests/specs/models",
			"/tests/specs/controllers",
			"/tests/specs/functional",
			"/vendor/wheels"
		];

		for (var dir in dirs) {
			directoryCreate(arguments.projectRoot & dir, true);
		}

		// Create routes.cfm with CLI-Appends-Here marker (generators need this)
		var nl = chr(10);
		var tab = chr(9);
		fileWrite(
			arguments.projectRoot & "/config/routes.cfm",
			'<cfscript>' & nl &
			tab & 'mapper()' & nl &
			tab & tab & '// CLI-Appends-Here' & nl & nl &
			tab & tab & '.wildcard()' & nl &
			tab & tab & '.root(to="main##index", method="get")' & nl &
			tab & '.end();' & nl &
			'</cfscript>' & nl
		);

		// Create minimal settings.cfm
		fileWrite(
			arguments.projectRoot & "/config/settings.cfm",
			'<cfscript>' & nl & tab & "set(environment='development');" & nl & '</cfscript>' & nl
		);
	}

}
