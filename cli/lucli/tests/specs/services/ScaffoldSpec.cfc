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
		variables.scaffold = new cli.lucli.services.Scaffold(
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

				it("adds the PLURAL resource route to routes.cfm (regression for F4)", () => {
					// Scaffold takes a singular name (`Article`) but routes.cfm
					// must follow the plural convention. Onboarding finding F4
					// reported the scaffold writing `.resources("post")` (singular)
					// after `wheels generate scaffold Post`, which conflicts with
					// any hand-added plural route and breaks the PostsController
					// mapping.
					var result = scaffold.generateScaffold(
						name = "Article",
						properties = [{name: "title", type: "string"}]
					);
					expect(result.success).toBeTrue();
					var routesContent = fileRead(tempRoot & "/config/routes.cfm");
					expect(routesContent).toInclude('.resources("articles")');
					expect(routesContent).notToInclude('.resources("article")');
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

				it("show.cfm heading uses first string column, not id (F4)", () => {
					// Scaffolding a model with a string column should put that
					// column in the <h1> heading instead of the numeric primary
					// key. Onboarding F4: scaffolded show.cfm previously rendered
					// `<h1>#post.id#</h1>` even though `title` was available.
					scaffold.generateScaffold(
						name = "Headline",
						properties = [{name: "title", type: "string"}, {name: "body", type: "text"}],
						force = true
					);
					var showContent = fileRead(tempRoot & "/app/views/headlines/show.cfm");
					expect(showContent).toInclude("##headline.title##");
					expect(showContent).notToInclude("<h1>##headline.id##</h1>");
				});

				it("index.cfm link text uses first string column, not id (F4)", () => {
					scaffold.generateScaffold(
						name = "Tagline",
						properties = [{name: "label", type: "string"}, {name: "weight", type: "integer"}],
						force = true
					);
					var indexContent = fileRead(tempRoot & "/app/views/taglines/index.cfm");
					expect(indexContent).toInclude("text=taglines.label");
				});

				it("falls back to id when no string column is provided (F4)", () => {
					// Defensive fallback: a scaffold with only numeric/boolean
					// columns has nothing user-facing to put in the heading,
					// so we keep the legacy `id` behavior.
					scaffold.generateScaffold(
						name = "Counter",
						properties = [{name: "value", type: "integer"}],
						force = true
					);
					var showContent = fileRead(tempRoot & "/app/views/counters/show.cfm");
					expect(showContent).toInclude("##counter.id##");
				});

				it("merges hand-edited migration columns into the form (F3)", () => {
					// Scenario from chapter 2/3 of the tutorial: user creates
					// a model with the generator, then hand-edits the migration
					// to add `publishedAt`, then scaffolds with the original
					// CLI args (no `publishedAt`). The form should still pick
					// up `publishedAt` by parsing the existing migration.
					var migrationDir = tempRoot & "/app/migrator/migrations";
					if (!directoryExists(migrationDir)) directoryCreate(migrationDir, true);
					var migrationPath = migrationDir & "/20260419120000_create_articulars_table.cfc";
					fileWrite(migrationPath, '
						component extends="wheels.migrator.Migration" {
							function up() {
								t = createTable(name="articulars");
								t.string(columnNames="title", default="", allowNull=true, limit=255);
								t.text(columnNames="body", default="", allowNull=true);
								t.datetime(columnNames="publishedAt", allowNull=true);
								t.timestamps();
								t.create();
							}
						}
					');

					scaffold.generateScaffold(
						name = "Articular",
						properties = [{name: "title", type: "string"}, {name: "body", type: "text"}],
						force = true
					);

					var formContent = fileRead(tempRoot & "/app/views/articulars/_form.cfm");
					// CLI-arg columns still present
					expect(formContent).toInclude('property="title"');
					expect(formContent).toInclude('property="body"');
					// Migration-only column merged in
					expect(formContent).toInclude('property="publishedAt"');
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

			describe("matches tutorial chapter 3 output (batch C snapshot)", () => {

				// Helper: scaffold a Post with the chapter-3 properties so
				// each `it` operates on a known set of files. Inline rather
				// than beforeAll because TestBox nested-describe lifecycle
				// doesn't reliably share generated state.
				function $scaffoldPost() {
					scaffold.generateScaffold(
						name = "Post",
						properties = [
							{name: "title", type: "string"},
							{name: "body", type: "text"},
							{name: "status", type: "enum", values: "draft,published,archived"}
						],
						force = true
					);
				}

				it("Posts.cfc uses route model binding for show/edit/update/delete", () => {
					$scaffoldPost();
					var content = fileRead(tempRoot & "/app/controllers/Posts.cfc");
					expect(content).toInclude("post=params.post");
					expect(content).notToInclude('findByKey(params.key)');
				});

				it("Posts.cfc create uses model.new(...) + .save() (not .create() + hasErrors)", () => {
					$scaffoldPost();
					var content = fileRead(tempRoot & "/app/controllers/Posts.cfc");
					expect(content).toInclude('model("Post").new(params.post)');
					expect(content).toInclude("post.save()");
					expect(content).notToInclude('model("post").create(');
					expect(content).notToInclude("hasErrors()");
				});

				it("Posts.cfc redirects use route= and key=, not action=index", () => {
					$scaffoldPost();
					var content = fileRead(tempRoot & "/app/controllers/Posts.cfc");
					expect(content).toInclude('redirectTo(route="post", key=post.id)');
					expect(content).toInclude('redirectTo(route="posts")');
					expect(content).notToInclude('redirectTo(action="index"');
				});

				it("Posts.cfc has no objectNotFound handler or verifies(...handler=)", () => {
					$scaffoldPost();
					var content = fileRead(tempRoot & "/app/controllers/Posts.cfc");
					expect(content).notToInclude("objectNotFound");
					expect(content).notToInclude('handler="objectNotFound"');
				});

				it("_form.cfm wraps fields in startFormTag/endFormTag with errorMessagesFor + submit", () => {
					$scaffoldPost();
					var content = fileRead(tempRoot & "/app/views/posts/_form.cfm");
					expect(content).toInclude('errorMessagesFor("post")');
					expect(content).toInclude("startFormTag(");
					expect(content).toInclude("endFormTag()");
					expect(content).toInclude('<button type="submit">');
				});

				it("_form.cfm renders a select for status:enum, not a textField", () => {
					$scaffoldPost();
					var content = fileRead(tempRoot & "/app/views/posts/_form.cfm");
					expect(content).toInclude('select(objectName="post", property="status"');
					expect(content).toInclude('options="draft,published,archived"');
					expect(content).notToInclude('textField(objectName="post", property="status"');
				});

				it("index.cfm uses article markup, not Bootstrap table classes", () => {
					$scaffoldPost();
					var content = fileRead(tempRoot & "/app/views/posts/index.cfm");
					expect(content).toInclude("<article>");
					// Build the cfloop opening tag from chr(60) so Lucee's
					// file-level tag-balance scan doesn't see an unclosed tag
					// in this spec source.
					var loopOpen = chr(60) & "cfloop query=""posts"">";
					expect(content).toInclude(loopOpen);
					expect(content).notToInclude('<table class="table">');
					expect(content).notToInclude('class="btn btn-default"');
				});

				it("show.cfm has clean heading + link/buttonTo footer (no Bootstrap)", () => {
					$scaffoldPost();
					var content = fileRead(tempRoot & "/app/views/posts/show.cfm");
					// The scaffold can't reliably assume a "title" field
					// exists on every model, so the default heading uses
					// the id. Tutorial readers still get a clean show.cfm
					// they can swap the heading on.
					expect(content).toInclude("<h1>");
					expect(content).toInclude('linkTo(route="editPost", key=post.id, text="Edit")');
					expect(content).toInclude('buttonTo(route="post", key=post.id, text="Delete", method="delete")');
					expect(content).notToInclude("View Post");
					expect(content).notToInclude('class="btn btn-primary"');
				});

				it("does NOT inject a duplicate .resources line when one already exists in any form", () => {
					// Pre-seed routes with the named-arg form (chapter 2's shape).
					var routesPath = tempRoot & "/config/routes.cfm";
					var seeded = "mapper()" & chr(10)
						& '    .resources(name="dupcheckposts", only="index,show")' & chr(10)
						& ".end();" & chr(10);
					fileWrite(routesPath, seeded);

					scaffold.generateScaffold(
						name = "Dupcheckpost",
						properties = [{name: "title", type: "string"}],
						force = true
					);

					var routesContent = fileRead(routesPath);
					var matches = reMatch('\.resources\([^)]*dupcheckposts', routesContent);
					expect(arrayLen(matches)).toBe(1);
				});

			});

		});

	}

}
