/**
 * The generated JSON API controller (#3881). It used to:
 * - 500 on a body without the record wrapper, or one that isn't valid JSON;
 * - 500 on a key that can't exist (`/api/products/abc`);
 * - return the list in query-column format ({"COLUMNS": [...], "DATA": [...]});
 * - upper-case its top-level keys on Lucee but not on RustCFML.
 * Live behaviour is checked end to end in the PR; this pins the generated code.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new cli.lucli.services.Helpers();
		variables.templates = new cli.lucli.services.Templates(helpers = variables.helpers, projectRoot = variables.tempRoot, moduleRoot = variables.moduleRoot);
		variables.codegen = new cli.lucli.services.CodeGen(templateService = variables.templates, helpers = variables.helpers, projectRoot = variables.tempRoot);
		variables.scaffold = new cli.lucli.services.Scaffold(codeGenService = variables.codegen, helpers = variables.helpers, projectRoot = variables.tempRoot, moduleRoot = variables.moduleRoot);
		var result = variables.scaffold.generateApiResource(name = "Gizmo", properties = [{name: "label", type: "string"}], force = true);
		variables.content = fileRead(variables.tempRoot & "/app/controllers/api/Gizmos.cfc");
		variables.generatedOk = result.success;
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {
		describe("generated API controller", () => {

			it("is generated", () => {
				expect(variables.generatedOk).toBeTrue();
			});

			it("returns the list as an array of records, not query columns", () => {
				// returnAs="objects": a JSON array of records shaped like show's.
				// returnAs="structs" is a struct keyed by row number today, which
				// serializes as {"1": {...}}, not an array.
				expect(variables.content).toInclude('findAll(returnAs="objects")');
				expect(variables.content).notToInclude('returnAs="structs"');
			});

			it("quotes its top-level keys so their case is the same on every engine", () => {
				expect(variables.content).toInclude('"gizmos"=local.gizmos');
				expect(variables.content).toInclude('"gizmo"=local.gizmo');
				expect(variables.content).toInclude('"error"="Record not found"');
				expect(reFind("\{\s*error\s*=", variables.content)).toBe(0, "an unquoted error= key is upper-cased on Lucee");
				expect(reFind("\{\s*gizmos?\s*=", variables.content)).toBe(0, "an unquoted record key is upper-cased on Lucee");
			});

			it("answers 400 when the body has no record wrapper or isn't JSON", () => {
				expect(variables.content).toInclude('StructKeyExists(params, "gizmo") && IsStruct(params.gizmo)');
				expect(variables.content).toInclude("status=400");
			});

			it("answers 404 for a key that can't exist, rethrowing anything else", () => {
				expect(variables.content).toInclude('e.type != "Wheels.InvalidValue"');
				expect(variables.content).toInclude("rethrow;");
			});

			it("looks a record up in one place, so include= injection still reaches it", () => {
				var occurrences = (len(variables.content) - len(replace(variables.content, ".findByKey(", "", "all"))) / len(".findByKey(");
				expect(occurrences).toBe(1);
			});
		});
	}

}
