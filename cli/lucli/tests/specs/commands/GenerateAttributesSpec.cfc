/**
 * Exercise the public generate() handoff, not just parseGeneratorArgs().
 * MCP advertises an attributes string; losing it used to report success
 * while writing a model and migration with none of the requested fields.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("generate attributes through MCP and CLI dispatch", () => {
			beforeEach(() => {
				variables.tempRoot = getTempDirectory() & "wheels-generate-attributes-" & createUUID();
				for (var dir in ["vendor/wheels", "app/models", "app/controllers", "app/views", "app/migrator/migrations", "config", "tests/specs"]) {
					directoryCreate(variables.tempRoot & "/" & dir, true, true);
				}
				fileWrite(variables.tempRoot & "/config/routes.cfm", 'mapper().wildcard().end();');
				variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
			});

			afterEach(() => {
				structDelete(request, "$wheelsGenerateDryRun");
				structDelete(request, "$wheelsDryRunPaths");
				if (directoryExists(variables.tempRoot)) directoryDelete(variables.tempRoot, true);
			});

			it("writes the advertised MCP scaffold attributes into model, migration, form and specs", () => {
				var payload = deserializeJSON('{"type":"scaffold","name":"Tag","attributes":"name:string{30} slug:string"}');
				mod.generate(argumentCollection = payload);
				$expectTagFields();
			});

			it("does not depend on the order of named MCP parameters", () => {
				var payload = structNew("ordered");
				payload["attributes"] = "name:string{30} slug:string";
				payload["name"] = "Tag";
				payload["type"] = "scaffold";
				mod.generate(argumentCollection = payload);
				$expectTagFields();
			});

			it("preserves ordinary positional CLI attributes and global-index gaps", () => {
				mod.generate(arg1="scaffold", arg2="Tag", force=true, arg4="name:string{30}", arg5="slug:string");
				$expectTagFields();
			});

			it("accepts positional type with named artifact and attributes", () => {
				mod.generate(arg1="scaffold", name="Tag", attributes="name:string{30} slug:string");
				$expectTagFields();
			});

			it("preserves raw argv delegation through the g alias", () => {
				mod.__arguments = ["scaffold", "Tag", "name:string{30}", "slug:string"];
				mod.g();
				$expectTagFields();
			});

			it("accepts comma-delimited named attributes", () => {
				mod.generate(type="scaffold", name="Tag", attributes="name:string{30},slug:string");
				$expectTagFields();
			});

			it("keeps decimal precision and enum values inside their property tokens", () => {
				mod.generate(type="scaffold", name="Product", attributes="name:string{30},price:decimal{10,2},status:enum:draft,published slug:string");
				var modelSource = $source("app/models/Product.cfc");
				expect(modelSource).toInclude('validatesPresenceOf("name,price,status,slug")');
				expect(modelSource).toInclude('values="draft,published"');
				var migration = $migration("products");
				expect(reFindNoCase("precision\s*=\s*['""]10['""]", migration)).toBeGT(0);
				expect(reFindNoCase("scale\s*=\s*['""]2['""]", migration)).toBeGT(0);
			});

			it("applies named attributes to model generation as well as scaffolds", () => {
				mod.generate(type="model", name="Tag", attributes="name:string{30} slug:string");
				expect($source("app/models/Tag.cfc")).toInclude('validatesPresenceOf("name,slug")');
				expect($source("app/models/Tag.cfc")).toInclude("maximum=30");
			});

			it("keeps named-argument dry runs write-free regardless of key order", () => {
				var payload = structNew("ordered");
				payload["attributes"] = "name:string{30} slug:string";
				payload["dry-run"] = true;
				payload["name"] = "Tag";
				payload["type"] = "scaffold";
				mod.generate(argumentCollection = payload);
				expect(fileExists(variables.tempRoot & "/app/models/Tag.cfc")).toBeFalse();
				expect(arrayLen(directoryList(variables.tempRoot & "/app/migrator/migrations", false, "name"))).toBe(0);
				expect(fileRead(variables.tempRoot & "/config/routes.cfm")).toBe('mapper().wildcard().end();');
			});
		});
	}

	private void function $expectTagFields() {
		var modelSource = $source("app/models/Tag.cfc");
		expect(modelSource).toInclude('validatesPresenceOf("name,slug")');
		expect(modelSource).toInclude("maximum=30");
		var migration = $migration("tags");
		expect(reFindNoCase("columnNames\s*=\s*['""]name['""]", migration)).toBeGT(0);
		expect(reFindNoCase("columnNames\s*=\s*['""]slug['""]", migration)).toBeGT(0);
		var formSource = $source("app/views/tags/_form.cfm");
		expect(reFindNoCase("property\s*=\s*['""]name['""]", formSource)).toBeGT(0);
		expect(reFindNoCase("property\s*=\s*['""]slug['""]", formSource)).toBeGT(0);
		expect($source("tests/specs/controllers/TagsControllerSpec.cfc")).toInclude('"slug":');
	}

	private string function $migration(required string tableName) {
		var paths = directoryList(variables.tempRoot & "/app/migrator/migrations", false, "path", "*create_" & arguments.tableName & "_table.cfc");
		expect(arrayLen(paths)).toBe(1);
		return $stripComments(fileRead(paths[1]));
	}

	private string function $source(required string relativePath) {
		return $stripComments(fileRead(variables.tempRoot & "/" & arguments.relativePath));
	}

	private string function $stripComments(required string source) {
		var result = reReplace(arguments.source, "<!---[\s\S]*?--->", "", "all");
		result = reReplace(result, "/\*[\s\S]*?\*/", "", "all");
		return reReplace(result, "//[^\r\n]*", "", "all");
	}
}
