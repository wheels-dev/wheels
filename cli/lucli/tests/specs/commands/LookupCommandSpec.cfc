/**
 * `wheels lookup <query>` and the `lookup` MCP tool: offline docs/API lookup.
 *
 * The command reads cli/lucli/data/docs-index.json, which the release and
 * snapshot builds generate (tools/build/scripts/build-docs-index.mjs) and a
 * source checkout doesn't have. These specs point it at a fixture index.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		variables.fixture = GetDirectoryFromPath(GetCurrentTemplatePath()) & "../../_fixtures/docs-index/docs-index.json";
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function lookupModule(string indexPath = variables.fixture, string cliVersion = "4.2.0") {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$("out");
		m.$("$docsIndexPath", arguments.indexPath);
		m.$("$displayVersion", arguments.cliVersion);
		return m;
	}

	private string function printed(required any m) {
		var said = "";
		for (var call in arguments.m.$callLog().out) {
			said &= call[1] & chr(10);
		}
		return said;
	}

	private struct function thrown(required any fn) {
		var state = {type: "", message: ""};
		try {
			arguments.fn();
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		return state;
	}

	function run() {

		describe("wheels lookup", () => {

			it("prints the full API entry for a function name: signature, parameters, example, link", () => {
				var m = lookupModule();
				m.lookup(arg1 = "findAll");
				var said = printed(m);
				expect(said).toInclude("findAll(where, order)");
				expect(said).toInclude("returns any");
				expect(said).toInclude("Available in: model");
				expect(said).toInclude("Maps to the WHERE clause");
				expect(said).toInclude("findAll(where=""active=1""");
				expect(said).toInclude("https://api.wheels.dev/v4-2-0/model-class/findall/");
			});

			it("prints ranked results with their link and id for a phrase", () => {
				var m = lookupModule();
				m.lookup(arg1 = "nested resources");
				var said = printed(m);
				expect(said).toInclude("Routing › Nested resources");
				expect(said).toInclude("https://guides.wheels.dev/v4-2-0/basics/routing/##nested-resources");
				expect(said).toInclude("id: guides:basics/routing##nested-resources");
			});

			it("takes the query from a named key, as an MCP tools/call sends it", () => {
				var m = lookupModule();
				m.lookup(query = "findAll", kind = "api");
				expect(printed(m)).toInclude("findAll(where, order)");
			});

			it("prints JSON with --format=json", () => {
				var m = lookupModule();
				m.lookup(arg1 = "findAll", format = "json");
				var parsed = DeserializeJSON(printed(m));
				expect(parsed.mode).toBe("exact");
				expect(parsed.entries[1].id).toBe("api:model.findAll");
				expect(parsed.index.apiSource).toBe("v4.2.0.json");
			});

			it("says so, and exits 0, when nothing matches", () => {
				var m = lookupModule();
				m.lookup(arg1 = "zzqx nothingmatches");
				expect(printed(m)).toInclude("No matches for ""zzqx nothingmatches""");
			});

			it("notes when the index is for another framework version than this CLI", () => {
				var m = lookupModule(cliVersion = "4.3.0");
				m.lookup(arg1 = "findAll");
				expect(printed(m)).toInclude("This docs index is for Wheels 4.2.0; this CLI is 4.3.0.");
				var same = lookupModule(cliVersion = "4.2.0-snapshot.12");
				same.lookup(arg1 = "findAll");
				expect(printed(same)).notToInclude("This docs index is for");
			});

			it("refuses with the build command when the index isn't there, in a self-contained message", () => {
				var m = lookupModule(indexPath = variables.fixture & ".missing");
				var state = thrown(() => m.lookup(arg1 = "findAll"));
				expect(state.type).toBe("Wheels.DocsIndexMissing");
				expect(state.message).toInclude("node tools/build/scripts/build-docs-index.mjs");
			});

			it("refuses a missing query, with the usage in the message", () => {
				var state = thrown(() => lookupModule().lookup());
				expect(state.type).toBe("Wheels.InvalidArguments");
				expect(state.message).toInclude("wheels lookup <query>");
			});

			it("reads the index the CLI module ships, under data/", () => {
				expect(mod.$docsIndexPath()).toMatch("[\\/]data[\\/]docs-index\.json$");
			});

		});

		describe("lookup over MCP", () => {

			it("advertises query (required), kind, limit and format", () => {
				var schema = mod.mcpToolSpecs().lookup;
				expect(schema.required).toInclude("query");
				expect(schema.properties.kind["enum"]).toBe(["all", "api", "guides"]);
				expect(schema.properties.limit.type).toBe("number");
				expect(schema.properties).toHaveKey("format");
			});

			it("is not hidden from MCP", () => {
				expect(ArrayFindNoCase(mod.mcpHiddenTools(), "lookup")).toBe(0);
			});

		});

	}

}
