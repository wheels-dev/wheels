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
