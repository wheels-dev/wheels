/**
 * Fixed-choice parameters reject values outside their set and advertise
 * them as a JSON Schema enum, from one ArgSpec `choices` declaration (#2963).
 *
 * dev1-qa's end-to-end MCP runs found invalid values falling back silently:
 * routes format=bogus printed the text table, seed mode=bogus generated
 * rows, test reporter=bogus used simple, analyze target=bogus analyzed
 * everything, and destroy type=bogus printed an error but exited 0.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		// A closed port: anything that got past argument validation fails
		// with Wheels.ServerNotRunning instead of doing real work.
		fileWrite(tempRoot & "/.env", "PORT=1" & chr(10));
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("MCP schemas advertise every fixed-choice parameter as an enum", () => {

			it("carries an enum on each fixed-choice property", () => {
				var specs = mod.mcpToolSpecs();
				var expected = {
					"analyze": "target",
					"create": "type",
					"db": "subcommand",
					"destroy": "type",
					"generate": "type",
					"migrate": "action",
					"packages": "subcommand",
					"routes": "format",
					"seed": "mode",
					"test": "reporter",
					"upgrade": "subcommand"
				};
				for (var tool in expected) {
					var prop = specs[tool].properties[expected[tool]];
					expect(prop).toHaveKey("enum", "#tool#.#expected[tool]# should advertise an enum");
					expect(arrayLen(prop.enum)).toBeGT(0);
				}
				expect(specs.upgrade.properties.format).toHaveKey("enum");
				// test db: the core runner only recognizes these (runner.cfm);
				// anything else silently fell back to the default datasource.
				expect(specs.test.properties.db.enum).toBe(["sqlite", "h2", "mysql", "postgres", "sqlserver", "sqlserver_cicd", "oracle", "cockroachdb"]);
			});

			it("lists only generator types that generate actually dispatches (no drift)", () => {
				var startIdx = reFindNoCase("function \$generateDispatch\s*\(", variables.moduleSource);
				expect(startIdx).toBeGT(0);
				var body = mid(variables.moduleSource, startIdx, 4000);
				for (var generatorType in mod.mcpToolSpecs().generate.properties.type.enum) {
					expect(body).toInclude('case "#generatorType#":', "generate advertises `#generatorType#` but does not dispatch it");
				}
			});

		});

		describe("commands reject values outside the choices (CLI and MCP)", () => {

			it("routes rejects an unknown format instead of printing the text table", () => {
				expect(() => mod.routes(format = "bogus")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("seed rejects an unknown mode instead of generating rows", () => {
				expect(() => mod.seed(mode = "bogus")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("test rejects an unknown reporter instead of using simple", () => {
				expect(() => mod.test(reporter = "bogus")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("test rejects a core db the runner does not recognize instead of using the default", () => {
				expect(() => mod.test(core = true, db = "qa-sentinel")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("analyze rejects an unknown target, by token or by name", () => {
				expect(() => mod.analyze(arg1 = "bogus")).toThrow(type = "Wheels.InvalidArguments");
				expect(() => mod.analyze(target = "bogus")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("db, packages, upgrade and migrate reject an unknown verb", () => {
				expect(() => mod.db(subcommand = "bogus")).toThrow(type = "Wheels.InvalidArguments");
				expect(() => mod.packages(subcommand = "bogus")).toThrow(type = "Wheels.InvalidArguments");
				expect(() => mod.upgrade(subcommand = "bogus")).toThrow(type = "Wheels.InvalidArguments");
				expect(() => mod.migrate(action = "bogus")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("still accepts a valid verb (it proceeds to the server step)", () => {
				expect(() => mod.db(subcommand = "STATUS")).toThrow(type = "Wheels.ServerNotRunning");
			});

		});

		describe("destroy — an unknown type exits non-zero", () => {

			it("rejects a named unknown type", () => {
				expect(() => mod.destroy(type = "bogus", name = "User")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("rejects an unknown type in the typed two-token form", () => {
				// Neither token is a valid type, so the legacy reorder reads
				// `bogus Widget` as <name> <type> and "widget" is not a type.
				expect(() => mod.destroy(arg1 = "bogus", arg2 = "Widget")).toThrow(type = "Wheels.InvalidArguments");
			});

		});

		describe("-h still asks for help where a choice-checked verb would reject it", () => {

			it("packages -h prints help", () => {
				expect(mod.packages(arg1 = "-h")).toInclude("wheels packages add");
				expect(mod.packages(arg1 = "list", arg2 = "-h")).toInclude("wheels packages add");
			});

			it("upgrade -h does not throw an invalid-verb error", () => {
				expect(() => mod.upgrade(arg1 = "-h")).notToThrow();
			});

		});

		describe("an explicit false boolean behaves like an omitted one (##2963)", () => {

			it("upgrade apply with strict=false is not refused as a check-only flag", () => {
				// The temp project's vendor/wheels is an empty stub, so apply
				// stops at the framework sniff — the point is it gets past the
				// flag refusal.
				var state = {message: ""};
				try {
					mod.upgrade(subcommand = "apply", strict = false);
				} catch (any e) {
					state.message = e.message;
				}
				expect(state.message).notToInclude("--strict");
			});

			it("packages with help=false runs the verb (in-process callers)", () => {
				expect(() => mod.packages(subcommand = "registry", target = "bogus", help = false)).toThrow(regex = "Unknown wheels packages registry verb");
			});

		});

		describe("$throwIfBridgeRefused — migrate refusals exit non-zero", () => {

			it("throws MigrationError when the bridge answered success:false", () => {
				expect(() => mod.$throwIfBridgeRefused({success: false, message: "table missing"}, "Diff failed")).toThrow(type = "MigrationError", regex = "Diff failed");
			});

			it("throws when the bridge sent no JSON document", () => {
				expect(() => mod.$throwIfBridgeRefused({}, "Rename refused")).toThrow(type = "MigrationError");
			});

			it("does nothing on success", () => {
				expect(() => mod.$throwIfBridgeRefused({success: true}, "unused")).notToThrow();
			});

			it("is what migrate diff and rename-system-tables call on a refusal", () => {
				// Both paths need a live server, so the call sites are pinned
				// source-level (the house pattern for server-dependent paths).
				for (var fnName in ["runMigrationDiff", "runRenameSystemTables"]) {
					var startIdx = reFindNoCase("private string function #fnName#\s*\(", variables.moduleSource);
					expect(startIdx).toBeGT(0);
					expect(mid(variables.moduleSource, startIdx, 3000)).toInclude("$throwIfBridgeRefused(parsed,");
				}
			});

		});

	}

}
