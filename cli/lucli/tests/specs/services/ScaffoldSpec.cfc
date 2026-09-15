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
			projectRoot = variables.tempRoot,
			// Production passes the module root explicitly. The parent-wiring
			// regressions below also exercise direct callers that omit it.
			moduleRoot = variables.moduleRoot
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

				it("guards every key-loading action against a missing record", () => {
					// findByKey returns a non-object for BOTH a missing key and a
					// soft-deleted row. Without a guard the action renders against
					// that empty value and the view throws a 500 where a 404
					// belongs — reproduced on a soft-deleted post before the fix.
					var result = scaffold.generateScaffold(
						name = "Notefile",
						properties = [{name = "title", type = "string"}],
						force = true
					);
					expect(result.success).toBeTrue();
					var content = fileRead(tempRoot & "/app/controllers/Notefiles.cfc");

					// A BEFORE filter covering all four key-loading actions.
					expect(content).toInclude('filters(through="requireRecord", only="show,edit,update,delete")');
					expect(content).toInclude("private function requireRecord()");
					expect(content).toInclude('if (!IsObject(model("Notefile").findByKey(key=params.key))) {');
					expect(content).toInclude('type = "Wheels.RecordNotFound"');

					// The guard must NOT live inside show(): ScaffoldSource only
					// rewrites show() when its finder is the whole body, so an
					// inline guard there disables `--belongsTo` include= wiring.
					var showBody = ReMatchNoCase("function show\(\) \{[^}]+\}", content);
					expect(ArrayLen(showBody)).toBe(1);
					expect(showBody[1]).notToInclude("IsObject");

					// And the generated file must still SCAN. ScaffoldSource fails
					// closed on any interpolated string, so a single `##...##` in
					// the guard's message would silently switch off the parent
					// wiring for every child of this model. Pin it at the source.
					var scanned = new cli.lucli.services.ScaffoldSource().scan(content);
					expect(scanned.valid).toBeTrue(scanned.reason);
				});

				it("emits a full CRUD controller spec with model().create() test data", () => {
					var result = scaffold.generateScaffold(
						name = "Chronicle",
						properties = [
							{name: "title", type: "string"},
							{name: "body", type: "text"},
							{name: "publishedAt", type: "datetime"}
						],
						force = true
					);
					expect(result.success).toBeTrue();
					var specPath = tempRoot & "/tests/specs/controllers/ChroniclesControllerSpec.cfc";
					expect(fileExists(specPath)).toBeTrue();
					var content = fileRead(specPath);
					expect(content).toInclude('action = "index"');
					expect(content).toInclude('action = "new"');
					expect(content).toInclude('action = "create"');
					expect(content).toInclude('action = "show"');
					expect(content).toInclude('action = "edit"');
					expect(content).toInclude('action = "update"');
					expect(content).toInclude('action = "delete"');
					expect(content).toInclude('model("Chronicle").create(properties = {"title": "MyString", "body": "MyText", "publishedAt": Now()})');
					expect(content).toInclude("beforeCount + 1");
					expect(content).toInclude("beforeCount - 1");
					expect(content).toInclude("expect(result.status).toBe(303)");

					var modelSpec = fileRead(tempRoot & "/tests/specs/models/ChronicleSpec.cfc");
					expect(modelSpec).toInclude("is invalid without required attributes");
					expect(modelSpec).toInclude('new(properties = {"title": "MyString", "body": "MyText", "publishedAt": Now()})');
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

				it("includes hasOne associations in model", () => {
					var result = scaffold.generateScaffold(
						name = "Employee",
						properties = [{name: "name", type: "string"}],
						hasOne = "Profile",
						force = true
					);
					expect(result.success).toBeTrue();
					var content = fileRead(tempRoot & "/app/models/Employee.cfc");
					expect(content).toInclude("hasOne");
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

				it("emits default string limit 255 when no brace modifier is present", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Barestring",
						properties = [{name: "title", type: "string"}]
					);
					var content = fileRead(path);
					expect(content).toInclude("t.string(columnNames='title', allowNull=true, limit='255')");
				});

				it("emits custom string limit from title:string{50}", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Sizedstring",
						properties = [{name: "title", type: "string", limit: "50"}]
					);
					var content = fileRead(path);
					expect(content).toInclude("t.string(columnNames='title', allowNull=true, limit='50')");
					expect(content).notToInclude("limit='255'");
				});

				it("emits default decimal precision 10 scale 2 without braces", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Baredecimal",
						properties = [{name: "price", type: "decimal"}]
					);
					var content = fileRead(path);
					expect(content).toInclude("t.decimal(columnNames='price', allowNull=true, precision='10', scale='2')");
				});

				it("emits custom decimal precision and scale from price:decimal{10,2}", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Sizeddecimal",
						properties = [{name: "price", type: "decimal", precision: "10", scale: "2"}]
					);
					var content = fileRead(path);
					expect(content).toInclude("t.decimal(columnNames='price', allowNull=true, precision='10', scale='2')");
				});

				it("emits custom decimal precision and scale from amount:decimal{12,4}", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Widedecimal",
						properties = [{name: "amount", type: "decimal", precision: "12", scale: "4"}]
					);
					var content = fileRead(path);
					expect(content).toInclude("t.decimal(columnNames='amount', allowNull=true, precision='12', scale='4')");
					expect(content).notToInclude("precision='10'");
				});

				it("emits custom integer limit and optional text/binary limit", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Sizedmisc",
						properties = [
							{name: "count", type: "integer", limit: "8"},
							{name: "body", type: "text", limit: "1000"},
							{name: "payload", type: "binary", limit: "4096"}
						]
					);
					var content = fileRead(path);
					expect(content).toInclude("t.integer(columnNames='count', allowNull=true, limit='8')");
					expect(content).toInclude("t.text(columnNames='body', allowNull=true, limit='1000')");
					expect(content).toInclude("t.binary(columnNames='payload', allowNull=true, limit='4096')");
				});

				it("emits default integer limit 11 when no brace modifier is present", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Bareinteger",
						properties = [{name: "count", type: "integer"}]
					);
					var content = fileRead(path);
					expect(content).toInclude("t.integer(columnNames='count', allowNull=true, limit='11')");
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

				it("reports the routes.cfm change in its own results.routes field", () => {
					// updateRoutes() always returned this boolean; the scaffold threw
					// it away, so a real run silently rewrote config/routes.cfm while
					// --dry-run listed it. The dry run was more honest than the run.
					var result = scaffold.generateScaffold(
						name = "Sprocket",
						properties = [{name: "title", type: "string"}],
						force = true
					);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.routes)).toBe(1);
					expect(result.routes[1].path).toInclude("config/routes.cfm");
				});

				it("does not report a routes change when the resource line already exists", () => {
					scaffold.generateScaffold(
						name = "Cog",
						properties = [{name: "title", type: "string"}],
						force = true
					);
					// Re-scaffold: updateRoutes() finds the existing line and skips.
					var second = scaffold.generateScaffold(
						name = "Cog",
						properties = [{name: "title", type: "string"}],
						force = true
					);
					expect(arrayLen(second.routes)).toBe(0);
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

				it("threads hasOne association into the model", () => {
					var result = scaffold.generateApiResource(
						name = "Account",
						properties = [{name: "balance", type: "decimal"}],
						hasOne = "Wallet"
					);
					expect(result.success).toBeTrue();
					var content = fileRead(tempRoot & "/app/models/Account.cfc");
					expect(content).toInclude("hasOne");
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

				// SKIPPED pending the CLI audit: scaffolded controllers still emit
				// findByKey(params.key); route-model-binding by default is a
				// user-facing codegen change (needs binding=true routes + 404
				// semantics + tutorial alignment) for its own PR. xit keeps the
				// intent visible. See #2367 (templates) / PR #2831 context.
				xit("Posts.cfc uses route model binding for show/edit/update/delete", () => {
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

				it("_form.cfm stacks labels above fields and nests errors in the field block", () => {
					$scaffoldPost();
					var content = fileRead(tempRoot & "/app/views/posts/_form.cfm");
					expect(content).toInclude('class="field"');
					expect(content).toInclude('labelPlacement="before"');
					expect(content).toInclude("includeErrorMessage=true");
					expect(content).toInclude('textField(objectName="post", property="title"');
					expect(content).toInclude('textArea(objectName="post", property="body"');
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
					// Every action carries simple.css's `.button` class so links
					// and the form button read alike — previously Edit and
					// "all posts" were bare links beside a Delete button.
					// `linkTo` takes HTML attributes directly; `buttonTo` needs
					// the `input` prefix because it wraps a nested <button>.
					expect(content).toInclude('linkTo(route="editPost", key=post.id, text="Edit", class="button")');
					expect(content).toInclude('buttonTo(route="post", key=post.id, text="Delete", method="delete", inputClass="button")');
					expect(content).toInclude('linkTo(route="posts", text="← all posts", class="button")');
					// A <div>, not a <p>: buttonTo emits a <form>, and a form
					// inside a paragraph is invalid HTML — the browser closes
					// the <p> early and the action row breaks apart.
					expect(content).toInclude('<div class="wheels-actions">');
					expect(content).notToInclude('<p class="wheels-actions">');
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

			describe("belongsTo scaffolding (CLI-D2)", () => {

				it("injects include= into the CRUD controller finders with all-named findByKey", () => {
					var result = scaffold.generateScaffold(
						name = "Review",
						properties = [{name: "body", type: "text"}],
						belongsTo = "Author",
						force = true
					);
					expect(result.success).toBeTrue();
					var content = fileRead(tempRoot & "/app/controllers/Reviews.cfc");
					expect(content).toInclude('findAll(include="author")');
					expect(content).toInclude('findByKey(key=params.key, include="author")');
					// The mixed positional+named form is rejected at runtime by
					// Lucee/Adobe — it must never be generated.
					expect(content).notToInclude('findByKey(params.key, include=');
					expect(content).notToInclude("findByKey(params.key)");
				});

				it("index.cfm renders the raw FK column, not query.assoc.name", () => {
					scaffold.generateScaffold(
						name = "Review",
						properties = [{name: "body", type: "text"}],
						belongsTo = "Author",
						force = true
					);
					var content = fileRead(tempRoot & "/app/views/reviews/index.cfm");
					// findAll() queries are flat — reviews.author.name throws at runtime.
					expect(content).notToInclude(".author.name");
					expect(content).toInclude("##reviews.authorId##");
				});

				it("show.cfm association display is backed by the injected include", () => {
					scaffold.generateScaffold(
						name = "Review",
						properties = [{name: "body", type: "text"}],
						belongsTo = "Author",
						force = true
					);
					var showContent = fileRead(tempRoot & "/app/views/reviews/show.cfm");
					var controllerContent = fileRead(tempRoot & "/app/controllers/Reviews.cfc");
					// show.cfm walks review.author.* — valid only because the
					// controller fetches with include="author".
					expect(showContent).toInclude("review.author.name");
					expect(controllerContent).toInclude('findByKey(key=params.key, include="author")');
				});

				it("injects include= into the API controller with all-named findByKey", () => {
					var result = scaffold.generateApiResource(
						name = "Memo",
						properties = [{name: "subject", type: "string"}],
						belongsTo = "Author",
						force = true
					);
					expect(result.success).toBeTrue();
					var content = fileRead(tempRoot & "/app/controllers/api/Memos.cfc");
					expect(content).toInclude('findAll(include="author")');
					expect(content).toInclude('findByKey(key=params.key, include="author")');
					expect(content).notToInclude('findByKey(params.key, include=');
				});

				it("creates the belongsTo parent in the controller spec beforeEach so the FK is valid", () => {
					// The controller eager-loads the parent via include= (an inner
					// join); the generated spec used to hard-code <name>_id: 1, so on
					// a fresh test DB (child specs run before the parent specs) the
					// first `wheels test` returned false from findByKey(include=...) and
					// broke show/edit/update/delete. The spec now persists the parent
					// (validation skipped) and references its id for the FK.
					scaffold.generateScaffold(
						name = "Review",
						properties = [{name: "body", type: "text"}],
						belongsTo = "Author",
						force = true
					);
					var spec = fileRead(tempRoot & "/tests/specs/controllers/ReviewsControllerSpec.cfc");
					expect(spec).toInclude('variables.author = model("Author").new();');
					expect(spec).toInclude('variables.author.save(validate = false);');
					expect(spec).toInclude('variables.author.id');
				});

				it("emits <name>_id FK column when useUnderscoreReferenceColumns=true", () => {
					// `wheels new` apps opt into underscore reference columns; the
					// scaffold's belongsTo FK column must match what t.references()
					// would produce rather than hard-coding camelCase `userId`.
					var settingsPath = tempRoot & "/config/settings.cfm";
					var originalSettings = fileRead(settingsPath);
					fileWrite(settingsPath, originalSettings & chr(10) & "set(useUnderscoreReferenceColumns=true);");

					scaffold.generateScaffold(
						name = "Membership",
						properties = [{name: "level", type: "string"}],
						belongsTo = "User",
						force = true
					);

					var files = directoryList(tempRoot & "/app/migrator/migrations", false, "name", "*memberships*");
					expect(arrayLen(files)).toBeGTE(1);
					var migration = fileRead(tempRoot & "/app/migrator/migrations/" & files[1]);
					expect(migration).toInclude("t.integer(columnNames='user_id'");
					expect(migration).notToInclude("columnNames='userId'");

					fileWrite(settingsPath, originalSettings);
				});

				it("renders a parent picker, not a raw id text field, when the FK is an underscore column", () => {
					// buildForeignKeyList() used to recognise only camelCase, so in
					// a `wheels new` app (useUnderscoreReferenceColumns=true, and
					// therefore a post_id column) the belongsTo branch never fired
					// and the form shipped a bare `post_id` text input.
					var settingsPath = tempRoot & "/config/settings.cfm";
					var originalSettings = fileRead(settingsPath);
					fileWrite(settingsPath, originalSettings & chr(10) & "set(useUnderscoreReferenceColumns=true);");

					scaffold.generateScaffold(
						name = "Post",
						properties = [{name: "title", type: "string"}, {name: "body", type: "text"}],
						force = true
					);
					scaffold.generateScaffold(
						name = "Comment",
						properties = [{name: "body", type: "text"}],
						belongsTo = "post",
						force = true
					);

					// `formContent`, not `form` — a local named after the FORM
					// scope shadows it and the assertion reads the empty scope.
					var formContent = fileRead(tempRoot & "/app/views/comments/_form.cfm");
					expect(formContent).toInclude('select(objectName="comment", property="post_id"');
					expect(formContent).notToInclude('textField(objectName="comment", property="post_id"');
					// Labelled by the parent's real display column, not a
					// hardcoded "name" — a scaffolded Post has a title.
					expect(formContent).toInclude('textField="title"');

					// show.cfm shows the relationship as a link to the parent.
					var showContent = fileRead(tempRoot & "/app/views/comments/show.cfm");
					expect(showContent).toInclude('linkTo(route="post"');
					expect(showContent).notToInclude("comment.post_");

					fileWrite(settingsPath, originalSettings);
				});

				it("wires the parent side of belongsTo: hasMany, include=, and a show block", () => {
					// Scaffolding the child used to leave the parent unaware of it:
					// no hasMany, nothing eager-loaded, nothing rendered. The parent
					// files already exist, so the scaffold edits them in place.
					scaffold.generateScaffold(
						name = "Widget",
						properties = [{name: "title", type: "string"}],
						force = true
					);
					var result = scaffold.generateScaffold(
						name = "Note",
						properties = [{name: "body", type: "text"}],
						belongsTo = "widget",
						force = true
					);
					expect(result.success).toBeTrue();

					// 1. inverse association on the parent model, inside config()
					var parentModel = fileRead(tempRoot & "/app/models/Widget.cfc");
					expect(parentModel).toInclude('hasMany(name="notes")');
					expect(parentModel).toInclude("function config()");

					// 2. the parent controller eager-loads them on show
					var parentController = fileRead(tempRoot & "/app/controllers/Widgets.cfc");
					expect(parentController).toInclude('findByKey(key=params.key, include="notes")');
					// ...and never the mixed positional+named form
					expect(parentController).notToInclude("findByKey(params.key, include=");

					// 3. the parent show view renders them, inside a marked block
					var parentShow = fileRead(tempRoot & "/app/views/widgets/show.cfm");
					expect(parentShow).toInclude("CLI: related notes (generated)");
					expect(parentShow).toInclude("newNote");
					expect(parentShow).toInclude("<h2>Notes</h2>");

					// and it is all idempotent — re-running must not stack blocks
					scaffold.generateScaffold(
						name = "Note",
						properties = [{name: "body", type: "text"}],
						belongsTo = "widget",
						force = true
					);
					var again = fileRead(tempRoot & "/app/views/widgets/show.cfm");
					var marker = "CLI: related notes (generated)";
					// exactly one occurrence: strip it once and it is gone
					var stripped = Replace(again, marker, "", "one");
					expect(Find(marker, again)).toBeGT(0);
					expect(Find(marker, stripped)).toBe(0);
				});

			});

			describe("safe parent-side belongsTo wiring regressions", () => {

				// Each example seeds its own parent files, not a scaffold generated
				// by an earlier example. Resource names are unique in shared tempRoot.
				it("reports parent edits as modified, never generated, and inserts a single output-safe child link", () => {
					var fixture = $seedWiringParent("Wirebasic");
					var result = scaffold.generateScaffold(
						name = fixture.childName,
						properties = [{name: "title", type: "string"}, {name: "body", type: "text"}],
						belongsTo = fixture.parentName
					);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.modified)).toBe(3);
					$expectWiringModification(result, fixture.modelPath, "model");
					$expectWiringModification(result, fixture.controllerPath, "controller");
					$expectWiringModification(result, fixture.viewPath, "view");
					$expectNoGeneratedParent(result, fixture);
					var modelContent = fileRead(fixture.modelPath);
					expect(modelContent).toInclude('hasMany(name="' & fixture.association & '")');
					expect(arrayLen(reMatchNoCase('hasMany\s*\(', modelContent))).toBe(1);
					var expectedController = replace(fixture.controllerContent,
						fixture.showFinder, replace(fixture.showFinder, "findByKey(params.key)",
							'findByKey(key=params.key, include="' & fixture.association & '")'), "one");
					$expectWiringFileBytes(fixture.controllerPath, expectedController);
					var viewContent = fileRead(fixture.viewPath);
					expect(viewContent).toInclude("CLI: related " & fixture.association & " (generated)");
					expect(arrayLen(reMatchNoCase(chr(60) & "cfoutput\b", viewContent))).toBe(1);
					expect(arrayLen(reMatchNoCase(chr(60) & "/cfoutput\s*>", viewContent))).toBe(1);
					$expectRelatedChildLink(viewContent, fixture, "title");
					expect(viewContent).notToInclude(fixture.childVar & ".body");
				});

				it("renders each child once across multiple eager-loaded collections and still appends later blocks", () => {
					var fixture = $seedWiringParent("Wirejoined");
					var first = scaffold.generateScaffold(name=fixture.childName, properties=[{name: "title", type: "string"}], belongsTo=fixture.parentName);
					expect(first.success).toBeTrue();
					var firstView = fileRead(fixture.viewPath);
					var firstSeen = "wheelsRelated" & helpers.capitalize(fixture.association) & "Seen";
					expect(firstView).toInclude(chr(60) & "cfset " & firstSeen & " = {}>");
					expect(firstView).toInclude("not StructKeyExists(" & firstSeen & ", " & fixture.childVar & ".id)");
					expect(firstView).toInclude(chr(60) & "cfset " & firstSeen & "[" & fixture.childVar & ".id] = true>");

					var secondName = "Wirejoinedbookmark";
					var secondVar = lCase(secondName);
					var secondAssociation = lCase(helpers.pluralize(secondName));
					var second = scaffold.generateScaffold(name=secondName, properties=[{name: "label", type: "string"}], belongsTo=fixture.parentName);
					expect(second.success).toBeTrue();
					$expectWiringModification(second, fixture.viewPath, "view");
					var content = fileRead(fixture.viewPath);
					expect(fileRead(fixture.controllerPath)).toInclude('include="' & fixture.association & ',' & secondAssociation & '"');
					var closing = chr(60) & "/cfoutput>";
					var prefix = left(firstView, len(firstView) - len(closing));
					expect(compare(left(content, len(prefix)), prefix)).toBe(0);
					expect(content).toInclude("wheelsRelated" & helpers.capitalize(secondAssociation) & "Seen = {}");

					// The SQL join cross-product can materialize the same child ID
					// more than once. Equal IDs in different associations remain distinct.
					var parentRecord = {};
					parentRecord[fixture.association] = [
						{id: 1, title: "First note"}, {id: 1, title: "Duplicate note"}, {id: 2, title: "Second note"}
					];
					parentRecord[secondAssociation] = [
						{id: 1, label: "First bookmark"}, {id: 1, label: "Duplicate bookmark"}, {id: 3, label: "Third bookmark"}
					];
					var renderer = new cli.lucli.tests._helpers.RelatedBlockRenderer();
					var rendered = renderer.render(fixture.viewPath, fixture.parentVar, parentRecord);
					expect(arrayLen(reMatch("\[" & fixture.childVar & ":1:", rendered))).toBe(1);
					expect(arrayLen(reMatch("\[" & secondVar & ":1:", rendered))).toBe(1);
					expect(rendered).toInclude("[" & fixture.childVar & ":2:Second note]");
					expect(rendered).toInclude("[" & secondVar & ":3:Third bookmark]");
					expect(rendered).notToInclude("Duplicate note");
					expect(rendered).notToInclude("Duplicate bookmark");
					expect(compare(renderer.render(fixture.viewPath, fixture.parentVar, parentRecord), rendered)).toBe(0);

					scaffold.generateScaffold(name=secondName, properties=[{name: "label", type: "string"}], belongsTo=fixture.parentName, force=true);
					$expectWiringFileBytes(fixture.viewPath, content);
					parentRecord[fixture.association] = [];
					parentRecord[secondAssociation] = [];
					var empty = renderer.render(fixture.viewPath, fixture.parentVar, parentRecord);
					expect(empty).toInclude("No " & fixture.association & " yet.");
					expect(empty).toInclude("No " & secondAssociation & " yet.");
					expect(empty).toInclude("Add a " & fixture.childVar);
					expect(empty).toInclude("Add a " & secondVar);
				});

				it("does not broaden the view scanner to arbitrary set statements", () => {
					var fixture = $seedWiringParent("Wirecustomset");
					var sourceReader = new cli.lucli.services.ScaffoldSource();
					for (var statement in [
						"counter = 1", "wheelsRelatedNotesSeen = loadIds()",
						"wheelsRelatedNotesSeen[note.other] = true", "wheelsRelatedNotesSeen[note.id] = false"
					]) {
						var custom = replace(fixture.viewContent, "<h1>", chr(60) & "cfset " & statement & "><h1>", "one");
						expect(sourceReader.viewAnchor(custom, fixture.parentVar)).toBe(0);
					}
				});

				it("preserves an existing hasMany with name first and skips unsafe downstream wiring", () => {
					var fixture = $seedWiringParent("Wirecustomfirst");
					fixture.modelContent = 'component extends="Model" { function config() {' & chr(10)
						& 'hasMany(name="' & fixture.association & '", dependent="delete", foreignKey="ownerId");'
						& chr(10) & '} }';
					fileWrite(fixture.modelPath, charsetDecode(fixture.modelContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, force=true);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.modified)).toBe(0);
					$expectWiringParentsUnchanged(fixture);
					$expectWiringWarning(result, fixture.modelPath);
					$expectNoGeneratedParent(result, fixture);
				});

				it("recognizes custom hasMany options before name without duplicating or replacing them", () => {
					var fixture = $seedWiringParent("Wirecustomlast");
					fixture.modelContent = 'component extends="Model" { function config() {' & chr(10)
						& "hasMany(foreignKey='ownerId', dependent='delete', name='" & fixture.association & "');"
						& chr(10) & '} }';
					fileWrite(fixture.modelPath, charsetDecode(fixture.modelContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, force=true);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.modified)).toBe(0);
					$expectWiringParentsUnchanged(fixture);
					$expectWiringWarning(result, fixture.modelPath);
				});

				it("preserves a conflicting hasOne or a hasMany alias targeting the child and skips downstream edits", () => {
					for (var scenario in ["hasone", "alias"]) {
						var fixture = $seedWiringParent("Wireinverse" & scenario);
						var declaration = scenario == "hasone"
							? 'hasOne(name="' & fixture.association & '");'
							: 'hasMany(name="customChildren", modelName="' & fixture.childName & '");';
						fixture.modelContent = 'component extends="Model" { function config() { ' & declaration & ' } }';
						fileWrite(fixture.modelPath, charsetDecode(fixture.modelContent, "utf-8"));
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, force=true);
						expect(result.success).toBeTrue();
						expect(arrayLen(result.modified)).toBe(0);
						$expectWiringParentsUnchanged(fixture);
						$expectWiringWarning(result, fixture.modelPath);
					}
				});

				it("preserves dynamic or indirect inverse declarations instead of injecting a possible duplicate", () => {
					for (var scenario in ["dynamicname", "literalprefix", "dynamictarget", "indirect"]) {
						var fixture = $seedWiringParent("Wiredynamicinverse" & scenario);
						var associationPrefix = left(fixture.association, len(fixture.association) - len("notes"));
						var declaration = "";
						switch (scenario) {
							case "dynamicname": declaration = 'var prefix="' & associationPrefix & '"; hasMany(name=prefix & "notes");'; break;
							case "literalprefix": declaration = 'hasMany(name="' & associationPrefix & '" & "notes");'; break;
							case "dynamictarget": declaration = 'hasMany(name="aliases", modelName=getChildModel());'; break;
							case "indirect": declaration = 'this["hasMany"]("' & fixture.association & '");'; break;
						}
						fixture.modelContent = 'component extends="Model" { function config() { ' & declaration & ' } }';
						fileWrite(fixture.modelPath, charsetDecode(fixture.modelContent, "utf-8"));
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, force=true);
						expect(result.success).toBeTrue();
						expect(arrayLen(result.modified)).toBe(0);
						$expectWiringParentsUnchanged(fixture);
						$expectWiringWarning(result, fixture.modelPath);
						$expectNoGeneratedParent(result, fixture);
					}
				});

				it("reuses conventional positional or named hasMany declarations without duplicating them", () => {
					for (var style in ["positional", "named"]) {
						var fixture = $seedWiringParent("Wirereuse" & style);
						var declaration = style == "named"
							? 'hasMany(name="' & fixture.association & '");'
							: "hasMany('" & fixture.association & "');";
						fixture.modelContent = 'component extends="Model" { function config() { ' & declaration & ' } }';
						fileWrite(fixture.modelPath, charsetDecode(fixture.modelContent, "utf-8"));
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
						expect(result.success).toBeTrue();
						$expectWiringFileBytes(fixture.modelPath, fixture.modelContent);
						expect(arrayLen(result.modified)).toBe(2);
						$expectWiringModification(result, fixture.controllerPath, "controller");
						$expectWiringModification(result, fixture.viewPath, "view");
					}
				});

				it("warns when the parent model is missing and does not edit its controller or view", () => {
					var fixture = $seedWiringParent("Wiremissingmodel");
					fileDelete(fixture.modelPath);
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					expect(fileExists(fixture.modelPath)).toBeFalse();
					expect(arrayLen(result.modified)).toBe(0);
					$expectWiringFileBytes(fixture.controllerPath, fixture.controllerContent);
					$expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
					$expectWiringWarning(result, fixture.modelPath);
				});

				it("warns when no real config exists even if comments and strings contain one", () => {
					var fixture = $seedWiringParent("Wiremissingconfig");
					fixture.modelContent = 'component extends="Model" {' & chr(10)
						& '// function config() {}' & chr(10)
						& '/* function config() {} */' & chr(10)
						& chr(60) & '!--- function config() {} --->' & chr(10)
						& 'variables.example = "function config() {}";' & chr(10) & '}';
					fileWrite(fixture.modelPath, charsetDecode(fixture.modelContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.modified)).toBe(0);
					$expectWiringParentsUnchanged(fixture);
					$expectWiringWarning(result, fixture.modelPath);
					expect(arrayToList(result.skipped, chr(10))).toInclude("config");
				});

				it("ignores line, block, tag and string decoys while inserting at original model offsets", () => {
					var fixture = $seedWiringParent("Wiremodelscanner");
					var nl = chr(13) & chr(10);
					var decoy = 'function config() { hasMany(name="' & fixture.association & '"); }';
					var prefix = 'component extends="Model" {' & nl
						& '// ' & decoy & nl & '/* ' & decoy & ' */' & nl
						& chr(60) & '!--- ' & decoy & ' --->' & nl
						& "variables.example = '" & decoy & "';" & nl
						& 'function config() {';
					var suffix = nl & 'validatesPresenceOf(properties="title");' & nl & '}' & nl & '}';
					fixture.modelContent = prefix & suffix;
					fileWrite(fixture.modelPath, charsetDecode(fixture.modelContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					$expectWiringModification(result, fixture.modelPath, "model");
					var content = fileRead(fixture.modelPath);
					expect(compare(left(content, len(prefix)), prefix)).toBe(0);
					expect(compare(right(content, len(suffix)), suffix)).toBe(0);
					var insertion = mid(content, len(prefix) + 1, len(content) - len(prefix) - len(suffix));
					expect(insertion).toInclude('hasMany(name="' & fixture.association & '")');
				});

				it("rewrites only the real show finder and preserves comment/string decoys and edit byte for byte", () => {
					var fixture = $seedWiringParent("Wirecontrollerscanner");
					var nl = chr(13) & chr(10);
					var decoy = 'function show() { ' & fixture.showFinder & ' }';
					fixture.controllerContent = 'component extends="Controller" {' & nl
						& '// ' & decoy & nl & '/* ' & decoy & ' */' & nl
						& chr(60) & '!--- ' & decoy & ' --->' & nl
						& "variables.example = '" & decoy & "';" & nl
						& 'function show() {' & nl & '/* Preserve this } and fake findByKey(params.key). */' & nl
						& fixture.showFinder & nl & '// Preserve this trailing }.' & nl & '}' & nl
						& 'function edit() { ' & fixture.showFinder & ' }' & nl & '}';
					fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					var newFinder = replace(fixture.showFinder, 'findByKey(params.key)',
						'findByKey(key=params.key, include="' & fixture.association & '")');
					var expected = replace(fixture.controllerContent, nl & fixture.showFinder & nl, nl & newFinder & nl, "one");
					$expectWiringFileBytes(fixture.controllerPath, expected);
					$expectWiringModification(result, fixture.controllerPath, "controller");
				});

				it("merges flat static include lists in either quote style without duplicate include arguments", () => {
					for (var quoteStyle in ["double", "single"]) {
						var fixture = $seedWiringParent("Wireinclude" & quoteStyle);
						var quoteChar = quoteStyle == "double" ? chr(34) : chr(39);
						fixture.controllerContent = replace(fixture.controllerContent, fixture.showFinder,
							fixture.parentVar & '=model(' & quoteChar & fixture.parentName & quoteChar
							& ').findByKey(key=params.key, include=' & quoteChar & 'author,tags' & quoteChar & ');', "one");
						fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
						expect(result.success).toBeTrue();
						$expectWiringModification(result, fixture.controllerPath, "controller");
						var content = fileRead(fixture.controllerPath);
						expect(content).toInclude('author,tags,' & fixture.association);
						expect(arrayLen(reMatchNoCase('\binclude\s*=', content))).toBe(1);
						expect(content).notToInclude('findByKey(params.key,');
						var snapshot = content;
						scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, force=true);
						$expectWiringFileBytes(fixture.controllerPath, snapshot);
					}
				});

				it("merges a static include appearing before the named key without changing other controller bytes", () => {
					var fixture = $seedWiringParent("Wireincludefirst");
					fixture.controllerContent = replace(fixture.controllerContent, 'findByKey(params.key)',
						'findByKey(include="author,tags", key=params.key)', "one");
					fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					$expectWiringModification(result, fixture.controllerPath, "controller");
					var expected = replace(fixture.controllerContent, 'include="author,tags"',
						'include="author,tags,' & fixture.association & '"', "one");
					$expectWiringFileBytes(fixture.controllerPath, expected);
				});

				it("recognizes existing include tokens despite whitespace and case without adding a duplicate", () => {
					var fixture = $seedWiringParent("Wireincludepresent");
					fixture.controllerContent = replace(fixture.controllerContent, 'findByKey(params.key)',
						'findByKey(include=" author , ' & uCase(fixture.association) & ' , tags ", key=params.key)', "one");
					fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.modified)).toBe(2);
					$expectWiringModification(result, fixture.modelPath, "model");
					$expectWiringModification(result, fixture.viewPath, "view");
					$expectWiringFileBytes(fixture.controllerPath, fixture.controllerContent);
				});

				it("fills an empty static include without a leading comma in either named argument order", () => {
					for (var argumentOrder in ["keyfirst", "includefirst"]) {
						var fixture = $seedWiringParent("Wireemptyinclude" & argumentOrder);
						var finder = argumentOrder == "keyfirst"
							? 'findByKey(key=params.key, include="")'
							: 'findByKey(include="", key=params.key)';
						fixture.controllerContent = replace(fixture.controllerContent, 'findByKey(params.key)', finder, "one");
						fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
						expect(result.success).toBeTrue();
						$expectWiringModification(result, fixture.controllerPath, "controller");
						var expected = replace(fixture.controllerContent, 'include=""', 'include="' & fixture.association & '"', "one");
						$expectWiringFileBytes(fixture.controllerPath, expected);
					}
				});

				it("accepts a conventional named-key finder with no include yet", () => {
					var fixture = $seedWiringParent("Wirenamedkey");
					fixture.controllerContent = replace(fixture.controllerContent, 'findByKey(params.key)', 'findByKey(key=params.key)', "one");
					fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					$expectWiringModification(result, fixture.controllerPath, "controller");
					expect(fileRead(fixture.controllerPath)).toInclude('findByKey(key=params.key, include="' & fixture.association & '")');
				});

				it("warns and preserves the entire controller for dynamic includes or custom show statements", () => {
					var cases = ["dynamic", "interpolated", "nestedinclude", "statement", "scoped", "othermodel", "otherkey", "multiple", "branch"];
					for (var scenario in cases) {
						var fixture = $seedWiringParent("Wireunsafe" & scenario);
						var statement = fixture.showFinder;
						switch (scenario) {
							case "dynamic": statement = replace(statement, 'findByKey(params.key)', 'findByKey(key=params.key, include=params.include)'); break;
							case "interpolated": statement = replace(statement, 'findByKey(params.key)', 'findByKey(key=params.key, include="##params.include##")'); break;
							case "nestedinclude": statement = replace(statement, 'findByKey(params.key)', 'findByKey(key=params.key, include="author(tags)")'); break;
							case "statement": statement &= ' auditAccess();'; break;
							case "scoped": statement = 'local.' & statement; break;
							case "othermodel": statement = replace(statement, 'model("' & fixture.parentName & '")', 'model("SomeoneElse")'); break;
							case "otherkey": statement = replace(statement, 'params.key', 'params.slug'); break;
							case "multiple": statement &= chr(10) & fixture.showFinder; break;
							case "branch": statement = 'if (params.allowed) { ' & statement & ' }'; break;
						}
						fixture.controllerContent = replace(fixture.controllerContent, fixture.showFinder, statement, "one");
						fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, force=true);
						expect(result.success).toBeTrue();
						$expectWiringFileBytes(fixture.controllerPath, fixture.controllerContent);
						$expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
						$expectWiringWarning(result, fixture.controllerPath);
						expect(arrayLen(result.modified)).toBe(1);
						$expectWiringModification(result, fixture.modelPath, "model");
					}
				});

				it("skips missing or ambiguous show actions without rewriting any controller bytes", () => {
					for (var scenario in ["missing", "ambiguous"]) {
						var fixture = $seedWiringParent("Wireshow" & scenario);
						if (scenario == "missing") {
							fixture.controllerContent = replace(fixture.controllerContent, "function show()", "function preview()", "one");
						} else {
							fixture.controllerContent = replace(fixture.controllerContent, "function edit()", "function show()", "one");
						}
						fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
						expect(result.success).toBeTrue();
						$expectWiringFileBytes(fixture.controllerPath, fixture.controllerContent);
						$expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
						$expectWiringWarning(result, fixture.controllerPath);
					}
				});

				it("warns for missing parent HTML files instead of creating them", () => {
					for (var missingFile in ["controller", "view"]) {
						var fixture = $seedWiringParent("Wiremissing" & missingFile);
						var missingPath = missingFile == "controller" ? fixture.controllerPath : fixture.viewPath;
						fileDelete(missingPath);
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
						expect(result.success).toBeTrue();
						expect(fileExists(missingPath)).toBeFalse();
						$expectWiringWarning(result, missingPath);
						if (missingFile == "controller") $expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
					}
				});

				it("requires an unambiguous conventional parent param and one non-nested output wrapper", () => {
					for (var scenario in ["noparam", "wrongparam", "nooutput", "multiple", "nested", "duplicateparam"]) {
						var fixture = $seedWiringParent("Wirewrapper" & scenario);
						var outputOpen = chr(60) & 'cfoutput>';
						var outputClose = chr(60) & '/cfoutput>';
						var paramTag = chr(60) & 'cfparam name="' & fixture.parentVar & '" default="">';
						switch (scenario) {
							case "noparam": fixture.viewContent = replace(fixture.viewContent, paramTag, "", "one"); break;
							case "wrongparam": fixture.viewContent = replace(fixture.viewContent, paramTag, chr(60) & 'cfparam name="someoneElse" default="">', "one"); break;
							case "nooutput": fixture.viewContent = paramTag & chr(10) & '<h1>Custom rendering</h1>'; break;
							case "multiple": fixture.viewContent &= chr(10) & outputOpen & '<p>Second output</p>' & outputClose; break;
							case "nested": fixture.viewContent = replace(fixture.viewContent, '<h1>Parent</h1>', outputOpen & '<h1>Nested</h1>' & outputClose, "one"); break;
							case "duplicateparam": fixture.viewContent = paramTag & chr(10) & fixture.viewContent; break;
						}
						fileWrite(fixture.viewPath, charsetDecode(fixture.viewContent, "utf-8"));
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, force=true);
						expect(result.success).toBeTrue();
						$expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
						$expectWiringWarning(result, fixture.viewPath);
						expect(arrayLen(result.modified)).toBe(2);
					}
				});

				it("ignores commented output wrappers and preserves original view insertion offsets", () => {
					var fixture = $seedWiringParent("Wireviewscanner");
					var prefix = chr(60) & '!--- Example ' & chr(60) & 'cfoutput>not live'
						& chr(60) & '/cfoutput> --->' & chr(13) & chr(10);
					fixture.viewContent = prefix & fixture.viewContent;
					fileWrite(fixture.viewPath, charsetDecode(fixture.viewContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					$expectWiringModification(result, fixture.viewPath, "view");
					var content = fileRead(fixture.viewPath);
					var closeTag = chr(60) & '/cfoutput>';
					var originalPrefix = left(fixture.viewContent, len(fixture.viewContent) - len(closeTag));
					expect(compare(left(content, len(originalPrefix)), originalPrefix)).toBe(0);
					expect(compare(right(content, len(closeTag)), closeTag)).toBe(0);
					expect(find('CLI: related ' & fixture.association, content)).toBeGT(len(originalPrefix));
				});

				it("ignores nested tag-comment decoys in all three parent files", () => {
					var fixture = $seedWiringParent("Wirenestedcomments");
					var commentOpen = chr(60) & '!---';
					var nestedPrefix = commentOpen & ' Outer ' & commentOpen & ' Inner ---> ';
					var modelComment = nestedPrefix & 'function config() { hasMany(name="' & fixture.association & '"); } --->';
					var controllerComment = nestedPrefix & 'function show() { ' & fixture.showFinder & ' } --->';
					var viewComment = nestedPrefix & chr(60) & 'cfoutput>Ignored' & chr(60) & '/cfoutput> --->';
					fixture.modelContent = replace(fixture.modelContent, 'component extends="Model" {',
						'component extends="Model" {' & chr(10) & modelComment, "one");
					fixture.controllerContent = replace(fixture.controllerContent, 'component extends="Controller" {',
						'component extends="Controller" {' & chr(10) & controllerComment, "one");
					fixture.viewContent = viewComment & chr(10) & fixture.viewContent;
					fileWrite(fixture.modelPath, charsetDecode(fixture.modelContent, "utf-8"));
					fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
					fileWrite(fixture.viewPath, charsetDecode(fixture.viewContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.modified)).toBe(3);
					$expectWiringModification(result, fixture.modelPath, "model");
					$expectWiringModification(result, fixture.controllerPath, "controller");
					$expectWiringModification(result, fixture.viewPath, "view");
					expect(fileRead(fixture.modelPath)).toInclude(modelComment);
					expect(arrayLen(reMatchNoCase('hasMany\s*\(', fileRead(fixture.modelPath)))).toBe(2);
					var expectedController = replace(fixture.controllerContent, chr(9) & chr(9) & fixture.showFinder,
						chr(9) & chr(9) & replace(fixture.showFinder, 'findByKey(params.key)',
							'findByKey(key=params.key, include="' & fixture.association & '")'), "one");
					$expectWiringFileBytes(fixture.controllerPath, expectedController);
					expect(fileRead(fixture.viewPath)).toInclude(viewComment);
					$expectRelatedChildLink(fileRead(fixture.viewPath), fixture, "id");
				});

				it("ignores quoted closing-tag decoys in view attributes and output expressions", () => {
					var fixture = $seedWiringParent("Wirequotedview");
					var closeTag = chr(60) & '/cfoutput>';
					var decoys = '<p data-example="' & closeTag & '">##encodeForHTML("' & closeTag & '")##</p>';
					fixture.viewContent = replace(fixture.viewContent, '<h1>Parent</h1>', '<h1>Parent</h1>' & chr(10) & decoys, "one");
					fileWrite(fixture.viewPath, charsetDecode(fixture.viewContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					$expectWiringModification(result, fixture.viewPath, "view");
					var content = fileRead(fixture.viewPath);
					var originalPrefix = left(fixture.viewContent, len(fixture.viewContent) - len(closeTag));
					expect(compare(left(content, len(originalPrefix)), originalPrefix)).toBe(0);
					expect(compare(right(content, len(closeTag)), closeTag)).toBe(0);
					expect(find('CLI: related ' & fixture.association, content)).toBeGT(len(originalPrefix));
				});

				it("preserves malformed begin-only or end-only related markers even with force", () => {
					for (var markerType in ["beginonly", "endonly"]) {
						var fixture = $seedWiringParent("Wiremarker" & markerType);
						var marker = markerType == "beginonly"
							? chr(60) & '!--- CLI: related ' & fixture.association & ' (generated) --->'
							: chr(60) & '!--- /CLI: related ' & fixture.association & ' --->';
						fixture.viewContent = replace(fixture.viewContent, chr(60) & '/cfoutput>',
							marker & chr(10) & '<aside>Preserve incomplete custom block.</aside>' & chr(10) & chr(60) & '/cfoutput>', "one");
						fileWrite(fixture.viewPath, charsetDecode(fixture.viewContent, "utf-8"));
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, force=true);
						expect(result.success).toBeTrue();
						expect(arrayLen(result.modified)).toBe(2);
						$expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
						$expectWiringWarning(result, fixture.viewPath);
					}
				});

				it("never overwrites a user-edited marked related block even with force", () => {
					var fixture = $seedWiringParent("Wiremarked");
					var customBlock = chr(60) & '!--- CLI: related ' & fixture.association & ' (generated) --->' & chr(10)
						& '<aside>My hand-written related UI must survive.</aside>' & chr(10)
						& chr(60) & '!--- /CLI: related ' & fixture.association & ' --->';
					fixture.viewContent = replace(fixture.viewContent, chr(60) & '/cfoutput>', customBlock & chr(10) & chr(60) & '/cfoutput>', "one");
					fileWrite(fixture.viewPath, charsetDecode(fixture.viewContent, "utf-8"));
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[{name: "label", type: "string"}], belongsTo=fixture.parentName, force=true);
					expect(result.success).toBeTrue();
					$expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
					expect(arrayLen(result.modified)).toBe(2);
					scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, force=true);
					$expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
				});

				it("leaves all parent files byte-identical on a forced rerun and reports no modifications", () => {
					var fixture = $seedWiringParent("Wirererun");
					var first = scaffold.generateScaffold(name=fixture.childName, properties=[{name: "label", type: "string"}], belongsTo=fixture.parentName);
					expect(first.success).toBeTrue();
					expect(arrayLen(first.modified)).toBe(3);
					fixture.modelContent = fileRead(fixture.modelPath);
					fixture.controllerContent = fileRead(fixture.controllerPath);
					fixture.viewContent = fileRead(fixture.viewPath);
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[{name: "label", type: "string"}], belongsTo=fixture.parentName, force=true);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.modified)).toBe(0);
					$expectWiringParentsUnchanged(fixture);
					$expectNoGeneratedParent(result, fixture);
				});

				it("finds the bundled related template when a direct service caller omits moduleRoot", () => {
					var fixture = $seedWiringParent("Wiredirect");
					var directScaffold = new cli.lucli.services.Scaffold(codeGenService=variables.codegen, helpers=variables.helpers, projectRoot=variables.tempRoot);
					var result = directScaffold.generateScaffold(name=fixture.childName, properties=[{name: "caption", type: "string"}], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					$expectWiringModification(result, fixture.viewPath, "view");
					$expectRelatedChildLink(fileRead(fixture.viewPath), fixture, "caption");
				});

				it("prefers the first string property over an earlier text property for the related child link", () => {
					var fixture = $seedWiringParent("Wiretextdisplay");
					var result = scaffold.generateScaffold(name=fixture.childName,
						properties=[{name: "rank", type: "integer"}, {name: "summary", type: "text"}, {name: "title", type: "string"}], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					var content = fileRead(fixture.viewPath);
					$expectRelatedChildLink(content, fixture, "title");
					expect(content).notToInclude(fixture.childVar & ".body");
					expect(content).notToInclude('text=' & fixture.childVar & '.summary');
				});

				it("uses the first text property when no string or body property exists", () => {
					var fixture = $seedWiringParent("Wiretextonly");
					var result = scaffold.generateScaffold(name=fixture.childName,
						properties=[{name: "rank", type: "integer"}, {name: "summary", type: "text"}, {name: "description", type: "text"}], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					var content = fileRead(fixture.viewPath);
					$expectRelatedChildLink(content, fixture, "summary");
					expect(content).notToInclude(fixture.childVar & ".body");
					expect(content).notToInclude('text=' & fixture.childVar & '.description');
				});

				it("falls back to the child id when merged view properties have no string or text", () => {
					var fixture = $seedWiringParent("Wireiddisplay");
					var result = scaffold.generateScaffold(name=fixture.childName,
						properties=[{name: "rank", type: "integer"}, {name: "active", type: "boolean"}], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					var content = fileRead(fixture.viewPath);
					$expectRelatedChildLink(content, fixture, "id");
					expect(content).notToInclude(fixture.childVar & ".body");
				});

				it("chooses related link display from migration columns merged into viewProps", () => {
					var fixture = $seedWiringParent("Wiremergeddisplay");
					var migrationPath = tempRoot & '/app/migrator/migrations/20260419120001_create_' & fixture.association & '_table.cfc';
					fileWrite(migrationPath, 'component extends="wheels.migrator.Migration" { function up() {'
						& 't = createTable(name="' & fixture.association & '");'
						& 't.integer(columnNames="rank"); t.text(columnNames="caption"); t.string(columnNames="title"); t.create(); } }');
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[{name: "rank", type: "integer"}], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					$expectRelatedChildLink(fileRead(fixture.viewPath), fixture, "title");
				});

				it("wires only the parent model for api=true and leaves all parent HTML bytes untouched", () => {
					var fixture = $seedWiringParent("Wireapiscaffold");
					var result = scaffold.generateScaffold(name=fixture.childName, properties=[], belongsTo=fixture.parentName, api=true);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.modified)).toBe(1);
					$expectWiringModification(result, fixture.modelPath, "model");
					$expectWiringFileBytes(fixture.controllerPath, fixture.controllerContent);
					$expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
					expect(directoryExists(tempRoot & '/app/views/' & fixture.association)).toBeFalse();
					$expectNoGeneratedParent(result, fixture);
				});

				it("does not touch parent HTML when generating an API resource", () => {
					var fixture = $seedWiringParent("Wireapiresource");
					var result = scaffold.generateApiResource(name=fixture.childName, properties=[], belongsTo=fixture.parentName);
					expect(result.success).toBeTrue();
					$expectWiringFileBytes(fixture.controllerPath, fixture.controllerContent);
					$expectWiringFileBytes(fixture.viewPath, fixture.viewContent);
					expect(directoryExists(tempRoot & '/app/views/' & fixture.association)).toBeFalse();
				});

				it("records dry-run parent paths without changing bytes and always restores request state", () => {
					var fixture = $seedWiringParent("Wiredryrun");
					var prior = {
						hadFlag: structKeyExists(request, "$wheelsGenerateDryRun"),
						hadPaths: structKeyExists(request, "$wheelsDryRunPaths")
					};
					if (prior.hadFlag) prior.flag = request.$wheelsGenerateDryRun;
					if (prior.hadPaths) prior.paths = request.$wheelsDryRunPaths;
					try {
						request.$wheelsGenerateDryRun = true;
						request.$wheelsDryRunPaths = [];
						var result = scaffold.generateScaffold(name=fixture.childName, properties=[{name: "title", type: "string"}], belongsTo=fixture.parentName);
						expect(result.success).toBeTrue();
						$expectWiringParentsUnchanged(fixture);
						expect(arrayFind(request.$wheelsDryRunPaths, fixture.modelPath)).toBeGT(0);
						expect(arrayFind(request.$wheelsDryRunPaths, fixture.controllerPath)).toBeGT(0);
						expect(arrayFind(request.$wheelsDryRunPaths, fixture.viewPath)).toBeGT(0);
						$expectNoGeneratedParent(result, fixture);
					} finally {
						if (prior.hadFlag) request.$wheelsGenerateDryRun = prior.flag;
						else structDelete(request, "$wheelsGenerateDryRun");
						if (prior.hadPaths) request.$wheelsDryRunPaths = prior.paths;
						else structDelete(request, "$wheelsDryRunPaths");
					}
				});

			});

			describe("generateApiTest() (CLI-D3)", () => {

				it("emits processRequest calls matching the real framework signature", () => {
					var result = scaffold.generateApiTest("Widgets", "Widget");
					expect(result.success).toBeTrue();
					var content = fileRead(result.path);
					// Route NAME inside the params struct + returnAs="struct"
					// (the old route="/api/widgets" URL-path form never matched
					// processRequest(required struct params, ...)).
					expect(content).toInclude('params={route: "apiWidgets", format: "json"}');
					expect(content).toInclude('route: "apiWidget"');
					expect(content).toInclude('returnAs="struct"');
					expect(content).notToInclude('processRequest(route=');
				});

				it("creates a record in beforeEach and asserts create/delete count deltas", () => {
					var result = scaffold.generateApiTest(
						controllerName = "Gadgets",
						modelName = "Gadget",
						properties = [{name: "label", type: "string"}],
						force = true
					);
					expect(result.success).toBeTrue();
					var content = fileRead(result.path);
					expect(content).toInclude('model("Gadget").create(properties = {"label": "MyString"})');
					expect(content).toInclude("expect(result.status).toBe(201)");
					expect(content).toInclude("expect(result.status).toBe(204)");
					expect(content).toInclude("beforeCount + 1");
					expect(content).toInclude("beforeCount - 1");
					expect(content).toInclude("variables.gadget.id");
				});

			});

			describe("generated migration failure tracking (CLI-D4)", () => {

				it("uses the struct-field catch pattern instead of local.X (BoxLang-safe)", () => {
					var path = scaffold.createMigrationWithProperties(
						name = "Ledger",
						properties = [{name: "total", type: "decimal"}]
					);
					var content = fileRead(path);
					// `local.X = ...` inside catch is discarded on BoxLang
					// (Cross-Engine Invariant #11): a failed migration would
					// take the commit branch and be recorded as applied.
					expect(content).toInclude("var state = {};");
					expect(content).toInclude("state.exception = e;");
					expect(content).toInclude('StructKeyExists(state, "exception")');
					expect(content).notToInclude("local.exception");
				});

			});

			describe("unknown property type rejection", () => {

				it("rejects 'references' instead of silently emitting a VARCHAR", () => {
					// `user:references` was previously mapped to `string`, producing
					// a plain VARCHAR column with no FK and no warning. Unknown types
					// must fail loudly rather than generate silently-wrong output.
					var result = scaffold.generateScaffold(
						name = "Assignment",
						properties = [{name: "content", type: "text"}, {name: "user", type: "references"}],
						force = true
					);
					expect(result.success).toBeFalse();
					expect(arrayLen(result.errors)).toBeGTE(1);
					expect(result.errors[1]).toInclude("references");
				});

			});

		});

	}

	/** Hand-seed user-owned files; no example depends on another scaffold run. */
	private struct function $seedWiringParent(required string prefix) {
		var fixture = {};
		fixture.parentName = arguments.prefix & "parent";
		fixture.parentVar = lCase(fixture.parentName);
		fixture.childName = arguments.prefix & "note";
		fixture.childVar = lCase(fixture.childName);
		fixture.association = lCase(variables.helpers.pluralize(fixture.childName));
		fixture.modelPath = variables.tempRoot & "/app/models/" & fixture.parentName & ".cfc";
		fixture.controllerPath = variables.tempRoot & "/app/controllers/" & variables.helpers.pluralize(fixture.parentName) & ".cfc";
		fixture.viewPath = variables.tempRoot & "/app/views/" & lCase(variables.helpers.pluralize(fixture.parentName)) & "/show.cfm";
		var nl = chr(10);
		fixture.modelContent = 'component extends="Model" {' & nl
			& chr(9) & 'function config() {' & nl
			& chr(9) & chr(9) & 'validatesPresenceOf(properties="title");' & nl
			& chr(9) & '}' & nl & '}';
		fixture.showFinder = fixture.parentVar & '=model("' & fixture.parentName & '").findByKey(params.key);';
		fixture.controllerContent = 'component extends="Controller" {' & nl
			& chr(9) & 'function config() {}' & nl
			& chr(9) & 'function show() {' & nl & chr(9) & chr(9) & fixture.showFinder & nl & chr(9) & '}' & nl
			& chr(9) & 'function edit() {' & nl & chr(9) & chr(9) & fixture.showFinder & nl & chr(9) & '}' & nl
			& '}';
		// Construct CFML tags to avoid Lucee's file-level tag-balance scan
		// treating string fixtures as executable markup in this spec.
		fixture.viewContent = chr(60) & 'cfparam name="' & fixture.parentVar & '" default="">' & nl
			& chr(60) & 'cfoutput>' & nl & '<h1>Parent</h1>' & nl
			& '<p>Keep this custom footer.</p>' & nl & chr(60) & '/cfoutput>';
		if (!directoryExists(getDirectoryFromPath(fixture.viewPath))) directoryCreate(getDirectoryFromPath(fixture.viewPath), true);
		fileWrite(fixture.modelPath, charsetDecode(fixture.modelContent, "utf-8"));
		fileWrite(fixture.controllerPath, charsetDecode(fixture.controllerContent, "utf-8"));
		fileWrite(fixture.viewPath, charsetDecode(fixture.viewContent, "utf-8"));
		return fixture;
	}

	private void function $expectWiringFileBytes(required string path, required string content) {
		expect(compare(toBase64(fileReadBinary(arguments.path)), toBase64(charsetDecode(arguments.content, "utf-8")))).toBe(0);
	}

	private void function $expectWiringParentsUnchanged(required struct fixture) {
		$expectWiringFileBytes(arguments.fixture.modelPath, arguments.fixture.modelContent);
		$expectWiringFileBytes(arguments.fixture.controllerPath, arguments.fixture.controllerContent);
		$expectWiringFileBytes(arguments.fixture.viewPath, arguments.fixture.viewContent);
	}

	private void function $expectWiringModification(required struct result, required string path, required string kind) {
		var matches = 0;
		for (var entry in arguments.result.modified) {
			expect(isStruct(entry)).toBeTrue();
			expect(structKeyExists(entry, "type")).toBeTrue();
			expect(structKeyExists(entry, "path")).toBeTrue();
			if (compare(entry.path, arguments.path) == 0) {
				expect(entry.type).toBe(arguments.kind);
				matches++;
			}
		}
		expect(matches).toBe(1);
	}

	private void function $expectNoGeneratedParent(required struct result, required struct fixture) {
		for (var entry in arguments.result.generated) {
			expect(compare(entry.path, arguments.fixture.modelPath)).notToBe(0);
			expect(compare(entry.path, arguments.fixture.controllerPath)).notToBe(0);
			expect(compare(entry.path, arguments.fixture.viewPath)).notToBe(0);
		}
	}

	private void function $expectWiringWarning(required struct result, required string path) {
		var found = false;
		for (var warning in arguments.result.skipped) {
			expect(isSimpleValue(warning)).toBeTrue();
			// Allow full or project-relative paths, but require an actionable file.
			if (findNoCase(listLast(arguments.path, "/"), warning)) found = true;
		}
		expect(found).toBeTrue();
	}

	private void function $expectRelatedChildLink(required string content, required struct fixture, required string propertyName) {
		var links = reMatchNoCase('linkTo\([^)]*\)', arguments.content);
		var found = false;
		for (var link in links) {
			if (reFindNoCase('route\s*=\s*["'']' & arguments.fixture.childVar & '["'']', link)) {
				expect(reFindNoCase('\btext\s*=\s*' & arguments.fixture.childVar & '\.' & arguments.propertyName & '\b', link)).toBeGT(0);
				found = true;
			}
		}
		expect(found).toBeTrue();
	}

}
