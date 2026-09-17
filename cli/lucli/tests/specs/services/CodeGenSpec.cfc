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

	function run() {

		describe("CodeGen Service", () => {

			describe("generateTest()", () => {

				it("creates a model spec file", () => {
					var result = codegen.generateTest(type = "model", name = "Gizmo");
					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/tests/specs/models/GizmoSpec.cfc")).toBeTrue();
				});

				it("refuses to overwrite an existing spec without force (##M4)", () => {
					codegen.generateTest(type = "model", name = "Widget", force = true);
					var path = tempRoot & "/tests/specs/models/WidgetSpec.cfc";
					fileWrite(path, "// SENTINEL");
					var result = codegen.generateTest(type = "model", name = "Widget");
					expect(result.success).toBeFalse();
					expect(fileRead(path)).toInclude("SENTINEL");
				});

				it("overwrites an existing spec when force=true", () => {
					codegen.generateTest(type = "model", name = "Doodad");
					var path = tempRoot & "/tests/specs/models/DoodadSpec.cfc";
					fileWrite(path, "// SENTINEL");
					var result = codegen.generateTest(type = "model", name = "Doodad", force = true);
					expect(result.success).toBeTrue();
					expect(find("SENTINEL", fileRead(path))).toBe(0);
				});

				it("S6 PROVE: missing-template fallback mints expect(true).toBeTrue()", () => {
					var result = codegen.generateTest(
						type = "noSuchTemplateType",
						name = "S6FallbackMint",
						force = true
					);
					expect(result.success).toBeTrue();
					expect(result.message).toInclude("inline template");
					var content = fileRead(tempRoot & "/tests/specs/unit/S6FallbackMintSpec.cfc");
					expect(content).toInclude("expect(true).toBeTrue();");
				});

				it("controller spec covers the seven CRUD actions with processRequest", () => {
					codegen.generateTest(type = "controller", name = "Posts", force = true);
					var content = fileRead(tempRoot & "/tests/specs/controllers/PostsControllerSpec.cfc");
					expect(content).toInclude('action = "index"');
					expect(content).toInclude('action = "new"');
					expect(content).toInclude('action = "create"');
					expect(content).toInclude('action = "show"');
					expect(content).toInclude('action = "edit"');
					expect(content).toInclude('action = "update"');
					expect(content).toInclude('action = "delete"');
					expect(content).toInclude("processRequest(");
					expect(content).toInclude("returnAs = ""struct""");
					expect(content).notToInclude("// it(""creates a record""");
					expect(content).notToInclude("{{targetName}}");
					expect(content).notToInclude("{{modelName}}");
				});

				it("controller spec creates per-example data via model().create()", () => {
					codegen.generateTest(
						type = "controller",
						name = "Posts",
						modelName = "Post",
						properties = [
							{name: "title", type: "string"},
							{name: "body", type: "text"},
							{name: "publishedAt", type: "datetime"}
						],
						force = true
					);
					var content = fileRead(tempRoot & "/tests/specs/controllers/PostsControllerSpec.cfc");
					expect(content).toInclude('model("Post").create(properties = {"title": "MyString", "body": "MyText", "publishedAt": Now()})');
					expect(content).notToInclude("{title = ");
					expect(content).notToInclude('"title" = ');
					expect(content).toInclude("beforeCount + 1");
					expect(content).toInclude("beforeCount - 1");
					expect(content).toInclude("expect(result.status).toBe(303)");
					expect(content).toInclude("variables.post.id");
				});

				it("model spec stays thin without properties and adds presence examples when given them", () => {
					codegen.generateTest(type = "model", name = "Bare", force = true);
					var bare = fileRead(tempRoot & "/tests/specs/models/BareSpec.cfc");
					expect(bare).toInclude('model("Bare").new()');
					expect(bare).notToInclude("is invalid without required attributes");

					codegen.generateTest(
						type = "model",
						name = "Post",
						properties = [{name: "title", type: "string"}, {name: "body", type: "text"}],
						force = true
					);
					var rich = fileRead(tempRoot & "/tests/specs/models/PostSpec.cfc");
					expect(rich).toInclude("is invalid without required attributes");
					expect(rich).toInclude("is valid with required attributes");
					expect(rich).toInclude('new(properties = {"title": "MyString", "body": "MyText"})');
				});

				it("sample attributes cover enum, email, integer, and boolean types", () => {
					codegen.generateTest(
						type = "controller",
						name = "Tickets",
						modelName = "Ticket",
						properties = [
							{name: "status", type: "enum", values: "open,pending,closed"},
							{name: "email", type: "email"},
							{name: "count", type: "integer"},
							{name: "active", type: "boolean"}
						],
						force = true
					);
					var content = fileRead(tempRoot & "/tests/specs/controllers/TicketsControllerSpec.cfc");
					expect(content).toInclude('"status": "open"');
					expect(content).toInclude('"email": "user@example.com"');
					expect(content).toInclude('"count": 1');
					expect(content).toInclude('"active": true');
					expect(content).notToInclude("{status = ");
					expect(content).notToInclude('"status" = ');
				});

				it("api spec asserts 201/204 and count deltas with created record keys", () => {
					var result = codegen.generateTest(
						type = "api",
						name = "Widgets",
						modelName = "Widget",
						properties = [{name: "value", type: "string"}],
						force = true
					);
					expect(result.success).toBeTrue();
					var content = fileRead(tempRoot & "/tests/specs/controllers/ApiWidgetsControllerSpec.cfc");
					expect(content).toInclude('params={route: "apiWidgets", format: "json"}');
					expect(content).toInclude('route: "apiWidget"');
					expect(content).toInclude("returnAs=""struct""");
					expect(content).toInclude("expect(result.status).toBe(201)");
					expect(content).toInclude("expect(result.status).toBe(204)");
					expect(content).toInclude("variables.widget.id");
					expect(content).toInclude('"value": "MyString"');
					expect(content).notToInclude("processRequest(route=");
				});

			});

			describe("generateModel()", () => {

				it("creates a model CFC with PascalCase name", () => {
					var result = codegen.generateModel(name = "Article", properties = []);
					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/app/models/Article.cfc")).toBeTrue();
				});

				it("model extends Model", () => {
					codegen.generateModel(name = "Review", properties = [], force = true);
					var content = fileRead(tempRoot & "/app/models/Review.cfc");
					expect(content).toInclude('extends="Model"');
				});

				it("includes properties in model config", () => {
					var props = [
						{name: "title", type: "string"},
						{name: "price", type: "decimal"}
					];
					codegen.generateModel(
						name = "Product",
						properties = props,
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/Product.cfc");
					expect(content).toInclude("config()");
				});

				it("emits validatesPresenceOf combining all properties (##2219)", () => {
					codegen.generateModel(
						name = "Foo",
						properties = [
							{name: "bar", type: "string"},
							{name: "baz", type: "integer"}
						],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/Foo.cfc");
					expect(content).toInclude('validatesPresenceOf("bar,baz")');
				});

				it("emits validatesFormatOf for email-typed properties (##2219)", () => {
					codegen.generateModel(
						name = "Subscriber",
						properties = [
							{name: "name", type: "string"},
							{name: "email", type: "email"}
						],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/Subscriber.cfc");
					expect(content).toInclude('validatesPresenceOf("name,email")');
					expect(content).toInclude('validatesFormatOf(property="email", type="email")');
				});

				it("emits validatesFormatOf for url-typed properties (##2219)", () => {
					codegen.generateModel(
						name = "Link",
						properties = [{name: "website", type: "url"}],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/Link.cfc");
					expect(content).toInclude('validatesFormatOf(property="website", type="URL")');
				});

				it("skips validations when no properties given (##2219)", () => {
					codegen.generateModel(name = "Empty", properties = [], force = true);
					var content = fileRead(tempRoot & "/app/models/Empty.cfc");
					expect(content).notToInclude("validatesPresenceOf");
					expect(content).notToInclude("validatesFormatOf");
					expect(content).notToInclude("validatesLengthOf");
				});

				it("emits validatesLengthOf for a string property with a brace limit", () => {
					codegen.generateModel(
						name = "SizedTitle",
						properties = [{name: "title", type: "string", limit: "50"}],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/SizedTitle.cfc");
					expect(content).toInclude('validatesPresenceOf("title")');
					expect(content).toInclude('validatesLengthOf(property="title", maximum=50, allowBlank=true)');
				});

				it("does not invent a length validation for a bare string", () => {
					codegen.generateModel(
						name = "BareTitle",
						properties = [{name: "title", type: "string"}],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/BareTitle.cfc");
					expect(content).toInclude('validatesPresenceOf("title")');
					expect(content).notToInclude("validatesLengthOf");
				});

				it("emits length validation for varchar / text / binary limits", () => {
					codegen.generateModel(
						name = "SizedMisc",
						properties = [
							{name: "sku", type: "varchar", limit: "80"},
							{name: "body", type: "text", limit: "1000"},
							{name: "blob", type: "binary", limit: "4096"}
						],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/SizedMisc.cfc");
					expect(content).toInclude('validatesPresenceOf("sku,body,blob")');
					expect(content).toInclude('validatesLengthOf(property="sku", maximum=80, allowBlank=true)');
					expect(content).toInclude('validatesLengthOf(property="body", maximum=1000, allowBlank=true)');
					expect(content).toInclude('validatesLengthOf(property="blob", maximum=4096, allowBlank=true)');
				});

				it("skips length validation for integer limits and decimal precision", () => {
					codegen.generateModel(
						name = "NumericSized",
						properties = [
							{name: "count", type: "integer", limit: "8"},
							{name: "price", type: "decimal", precision: "10", scale: "2"}
						],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/NumericSized.cfc");
					expect(content).toInclude('validatesPresenceOf("count,price")');
					expect(content).notToInclude("validatesLengthOf");
				});

				it("keeps email format validation alongside a sibling string limit", () => {
					codegen.generateModel(
						name = "MixedValidations",
						properties = [
							{name: "title", type: "string", limit: "50"},
							{name: "email", type: "email"}
						],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/MixedValidations.cfc");
					expect(content).toInclude('validatesPresenceOf("title,email")');
					expect(content).toInclude('validatesFormatOf(property="email", type="email")');
					expect(content).toInclude('validatesLengthOf(property="title", maximum=50, allowBlank=true)');
					expect(content).toInclude(chr(9) & chr(9) & "validatesLengthOf");
					expect(content).notToInclude(chr(10) & "validatesLengthOf");
				});

				it("emits enum() for enum-typed properties (##M2)", () => {
					codegen.generateModel(
						name = "Ticket",
						properties = [{name: "status", type: "enum", values: "open,pending,closed"}],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/Ticket.cfc");
					expect(content).toInclude('enum(property="status", values="open,pending,closed")');
				});

				it("leaves no stray enums placeholder when there are no enum properties (##M2)", () => {
					codegen.generateModel(name = "NoEnum", properties = [{name: "title", type: "string"}], force = true);
					var content = fileRead(tempRoot & "/app/models/NoEnum.cfc");
					expect(content).notToInclude("{" & "{enums}}");
					expect(content).notToInclude("enum(");
				});

				it("produces no orphan whitespace-only lines (##2329)", () => {
					codegen.generateModel(
						name = "Layout",
						properties = [{name: "title", type: "string"}],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/Layout.cfc");
					var lines = listToArray(content, chr(10), true);
					var whitespaceOnly = [];
					for (var i = 1; i <= arrayLen(lines); i++) {
						if (reFind("^[[:space:]]+$", lines[i])) {
							arrayAppend(whitespaceOnly, "line " & i & ": '" & lines[i] & "'");
						}
					}
					expect(arrayLen(whitespaceOnly)).toBe(0);
				});

				it("produces no consecutive blank-line runs (##2329)", () => {
					codegen.generateModel(
						name = "Spacer",
						properties = [{name: "name", type: "string"}],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/Spacer.cfc");
					// 3+ consecutive newlines = 2+ consecutive blank lines
					expect(content).notToInclude(chr(10) & chr(10) & chr(10));
				});

				it("indents validations at 2 tabs, not 4 (##2329)", () => {
					codegen.generateModel(
						name = "Indent",
						properties = [{name: "title", type: "string"}],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/Indent.cfc");
					// 2-tab indent is correct
					expect(content).toInclude(chr(9) & chr(9) & "validatesPresenceOf");
					// 4-tab indent is the bug shape — must not be present
					expect(content).notToInclude(chr(9) & chr(9) & chr(9) & chr(9) & "validatesPresenceOf");
				});

				it("indents multi-line validations consistently at 2 tabs (##2329)", () => {
					codegen.generateModel(
						name = "MultiVal",
						properties = [
							{name: "name", type: "string"},
							{name: "email", type: "email"}
						],
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/MultiVal.cfc");
					// Both lines must be at the same 2-tab indent
					expect(content).toInclude(chr(9) & chr(9) & "validatesPresenceOf");
					expect(content).toInclude(chr(9) & chr(9) & "validatesFormatOf");
					// And neither line should be at column 0 (subsequent-line bug)
					expect(content).notToInclude(chr(10) & "validatesFormatOf");
				});

			});

			describe("generateController()", () => {

				it("creates a controller CFC in app/controllers/", () => {
					var result = codegen.generateController(
						name = "Articles",
						actions = ["index", "show"]
					);
					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/app/controllers/Articles.cfc")).toBeTrue();
				});

				it("controller extends Controller", () => {
					codegen.generateController(name = "Reviews", actions = [], force = true);
					var content = fileRead(tempRoot & "/app/controllers/Reviews.cfc");
					expect(content).toInclude('extends="Controller"');
				});

				it("splits a comma-joined action token into separate actions (##3112)", () => {
					var result = codegen.generateController(
						name = "Authors",
						actions = ["index,show"],
						force = true
					);
					var content = fileRead(tempRoot & "/app/controllers/Authors.cfc");
					// The bug: one element "index,show" emitted as `function index,show()`
					expect(content).notToInclude("index,show");
					expect(content).toInclude("function index()");
					expect(content).toInclude("function show()");
				});

				it("returns the normalized action list so callers render correct views (##3112)", () => {
					var result = codegen.generateController(
						name = "Editors",
						actions = ["index, show ,create"],
						force = true
					);
					expect(result.actions).toBe(["index", "show", "create"]);
				});

				it("de-duplicates and trims actions from comma tokens (##3112)", () => {
					var result = codegen.generateController(
						name = "Curators",
						actions = ["index", "show,index"],
						force = true
					);
					expect(result.actions).toBe(["index", "show"]);
				});

				it("returns an empty action list when no actions are passed so callers write no views", () => {
					var result = codegen.generateController(
						name = "Stubs",
						actions = [],
						force = true
					);
					var content = fileRead(tempRoot & "/app/controllers/Stubs.cfc");
					// The controller body still gets the default index() stub...
					expect(content).toInclude("function index()");
					// ...but result.actions stays empty so the caller writes no view
					// files, preserving the documented "no actions => empty controller
					// with no view files" behavior (PR ##3131 review).
					expect(result.actions).toBeEmpty();
				});

				it("S2 PROVE: packagePath from listFirst is unvalidated so ../X writes outside app/controllers/", () => {
					// Current hole: listFirst("../S2Escape","/") is ".." and is
					// joined as packagePath without validateName. Destination
					// becomes app/controllers/../S2Escape.cfc → app/S2Escape.cfc.
					var result = codegen.generateController(
						name = "../S2Escape",
						actions = [],
						force = true
					);
					var escapedPath = tempRoot & "/app/S2Escape.cfc";
					var controllersPath = tempRoot & "/app/controllers/S2Escape.cfc";
					expect(result.success).toBeTrue();
					expect(fileExists(escapedPath)).toBeTrue();
					expect(fileExists(controllersPath)).toBeFalse();
					if (fileExists(escapedPath)) {
						fileDelete(escapedPath);
					}
				});

			});

			describe("generatePolicy()", () => {

				it("creates the policy and the base Policy.cfc stub on first run", () => {
					var result = codegen.generatePolicy(name = "Gadget");
					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/app/policies/GadgetPolicy.cfc")).toBeTrue();
					expect(fileExists(tempRoot & "/app/policies/Policy.cfc")).toBeTrue();
					expect(result.baseCreated).toBeTrue();
				});

				it("policy extends Policy and declares every standard action denying", () => {
					codegen.generatePolicy(name = "Widget", force = true);
					var content = fileRead(tempRoot & "/app/policies/WidgetPolicy.cfc");
					expect(content).toInclude('extends="Policy"');
					for (var actionName in ["index", "show", "new", "create", "edit", "update", "delete"]) {
						expect(content).toInclude("function #actionName#(");
					}
					expect(content).toInclude("return false;");
				});

				it("base stub extends wheels.Policy", () => {
					codegen.generatePolicy(name = "Sprocket", force = true);
					var content = fileRead(tempRoot & "/app/policies/Policy.cfc");
					expect(content).toInclude('extends="wheels.Policy"');
				});

				it("normalizes a name already carrying the Policy suffix", () => {
					var result = codegen.generatePolicy(name = "ArticlePolicy", force = true);
					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/app/policies/ArticlePolicy.cfc")).toBeTrue();
					expect(fileExists(tempRoot & "/app/policies/ArticlePolicyPolicy.cfc")).toBeFalse();
				});

				it("refuses to overwrite an existing policy without force", () => {
					codegen.generatePolicy(name = "Doohickey", force = true);
					var path = tempRoot & "/app/policies/DoohickeyPolicy.cfc";
					fileWrite(path, "// SENTINEL");
					var result = codegen.generatePolicy(name = "Doohickey");
					expect(result.success).toBeFalse();
					expect(fileRead(path)).toInclude("SENTINEL");
				});

				it("never overwrites an existing base Policy.cfc stub", () => {
					codegen.generatePolicy(name = "Flange", force = true);
					var basePath = tempRoot & "/app/policies/Policy.cfc";
					fileWrite(basePath, "// BASE SENTINEL");
					var result = codegen.generatePolicy(name = "Grommet", force = true);
					expect(result.success).toBeTrue();
					expect(result.baseCreated).toBeFalse();
					expect(fileRead(basePath)).toInclude("BASE SENTINEL");
				});

			});

			describe("validateName()", () => {

				it("rejects empty name", () => {
					var result = codegen.validateName("", "model");
					expect(result.valid).toBeFalse();
				});

				it("accepts valid PascalCase name", () => {
					var result = codegen.validateName("UserProfile", "model");
					expect(result.valid).toBeTrue();
				});

				it("S2 PROVE: validateName rejects ../X but generateController never consults it", () => {
					var result = codegen.validateName("../X", "controller");
					expect(result.valid).toBeFalse();
				});

			});

		});

	}

}
