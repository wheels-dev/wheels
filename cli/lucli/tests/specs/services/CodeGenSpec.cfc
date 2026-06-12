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

			});

		});

	}

}
