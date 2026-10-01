/**
 * 4.1.2 rule: a command that fails exits non-zero, and over MCP returns
 * isError. Each case below printed an error (or usage) and then returned ""
 * (exit 0, MCP success). They now throw, and the thrown error carries the
 * message so it is printed once.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		// No server: server-dependent paths must fail fast, not find a dev server on 8080.
		fileWrite(tempRoot & "/.env", "PORT=1" & chr(10) & "WHEELS_SERVER_FALLBACK=false" & chr(10));
		variables.emptyDir = getTempDirectory() & "silent-fail-empty-" & createUUID();
		directoryCreate(variables.emptyDir);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
		if (directoryExists(variables.emptyDir)) directoryDelete(variables.emptyDir, true);
	}

	private any function cli(string cwd = variables.tempRoot) {
		var m = new cli.lucli.Module(cwd = arguments.cwd);
		prepareMock(m);
		m.$("out");
		return m;
	}

	/** Runs `command` with argv `args` and returns the thrown type ("" when it returned). */
	private string function failure(required any m, required string command, required array args) {
		var state = {type = ""};
		arguments.m.__arguments = arguments.args;
		try {
			invoke(arguments.m, arguments.command);
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	/** The thrown message ("" when it returned). */
	private string function failureMessage(required any m, required string command, required array args) {
		var state = {message = ""};
		arguments.m.__arguments = arguments.args;
		try {
			invoke(arguments.m, arguments.command);
		} catch (any e) {
			state.message = e.message;
		}
		return state.message;
	}

	function run() {

		describe("failure messages are self-contained (an MCP client gets only the message, not the printed output)", () => {

			it("usage refusals carry the usage line, bare generate lists the types, doctor lists its issues", () => {
				expect(failureMessage(cli(), "generate", ["model"])).toInclude("Usage: wheels generate model <Name>");
				expect(failureMessage(cli(), "destroy", [])).toInclude("Usage: wheels destroy <type> <name>");
				expect(failureMessage(cli(), "db", [])).toInclude("Usage: wheels db <command>");
				var bare = failureMessage(cli(), "generate", []);
				expect(bare).toInclude("scaffold");
				expect(bare).toInclude("migration");
				var doctor = failureMessage(cli(variables.emptyDir), "doctor", []);
				expect(doctor).toInclude("status CRITICAL");
				expect(doctor).toInclude("Missing required");
				expect(failureMessage(cli(), "upgrade", [])).toInclude("wheels upgrade apply");
			});

		});

		describe("generator refusals and usage errors exit non-zero", () => {

			it("refuses an existing model, an invalid name, a missing name and a bare generate", () => {
				expect(failure(cli(), "generate", ["model", "Silentprobe"])).toBe("");
				expect(failure(cli(), "generate", ["model", "Silentprobe"])).toBe("Wheels.Generate.Refused");
				expect(failure(cli(), "generate", ["model", 'Bad"Name'])).toBe("Wheels.Generate.InvalidName");
				expect(failure(cli(), "generate", ["model"])).toBe("Wheels.InvalidArguments");
				expect(failure(cli(), "generate", [])).toBe("Wheels.InvalidArguments");
			});

			it("refuses an unknown test type and an existing route", () => {
				expect(failure(cli(), "generate", ["test", "widget", "Silentprobe"])).toBe("Wheels.InvalidArguments");
				// Tag names built with Chr(60): a literal cf tag in a string breaks Lucee's tag scanner.
				fileWrite(tempRoot & "/config/routes.cfm", Chr(60) & "cfscript>mapper().resources(""silentprobes"")" & chr(10) & "// CLI-Appends-Here" & chr(10) & ".end();" & Chr(60) & "/cfscript>");
				expect(failure(cli(), "generate", ["route", "silentprobes"])).toBe("Wheels.Generate.Refused");
			});

		});

		describe("other commands with missing arguments exit non-zero", () => {

			it("create, destroy, db and upgrade with no arguments, and migrate pretend without a version", () => {
				expect(failure(cli(), "create", [])).toBe("Wheels.InvalidArguments");
				expect(failure(cli(), "destroy", [])).toBe("Wheels.InvalidArguments");
				expect(failure(cli(), "db", [])).toBe("Wheels.InvalidArguments");
				expect(failure(cli(), "upgrade", [])).toBe("Wheels.InvalidArguments");
				expect(failure(cli(), "migrate", ["pretend"])).toBe("Wheels.InvalidArguments");
			});

		});

		describe("health and analysis commands", () => {

			it("doctor with status CRITICAL exits non-zero", () => {
				expect(failure(cli(variables.emptyDir), "doctor", [])).toBe("Wheels.DoctorCritical");
			});

			it("analyze outside a Wheels project exits non-zero", () => {
				expect(failure(cli(variables.emptyDir), "analyze", [])).toBe("Wheels.InvalidArguments");
			});

		});

		describe("destroy", () => {

			it("of a name that was never generated exits non-zero and writes no migration", () => {
				var migrations = tempRoot & "/app/migrator/migrations";
				var before = directoryExists(migrations) ? arrayLen(directoryList(migrations, false, "name")) : 0;
				expect(failure(cli(), "destroy", ["Neverthere", "--force"])).toBe("Wheels.NothingToDestroy");
				expect(failure(cli(), "destroy", ["model", "Neverthere", "--force"])).toBe("Wheels.NothingToDestroy");
				var after = directoryExists(migrations) ? arrayLen(directoryList(migrations, false, "name")) : 0;
				expect(after).toBe(before, "a migration was written for something that does not exist");
			});

			it("only counts a route that matches the resource name exactly", () => {
				var routes = tempRoot & "/config/routes.cfm";
				var saved = fileRead(routes);
				try {
					// A different resource whose name merely contains this one's.
					fileWrite(routes, Chr(60) & "cfscript>mapper().resources(""ghostlyprobes"")" & chr(10) & ".end();" & Chr(60) & "/cfscript>");
					expect(failure(cli(), "destroy", ["Ghostlyprobe", "--force"])).toBe("");
					fileWrite(routes, Chr(60) & "cfscript>mapper().resources(""ghostlyprobess"")" & chr(10) & ".end();" & Chr(60) & "/cfscript>");
					expect(failure(cli(), "destroy", ["Ghostlyprobe", "--force"])).toBe("Wheels.NothingToDestroy");
				} finally {
					fileWrite(routes, saved);
				}
			});

			it("of a model that exists still works", () => {
				expect(failure(cli(), "generate", ["model", "Destroyprobe"])).toBe("");
				expect(failure(cli(), "destroy", ["model", "Destroyprobe", "--force"])).toBe("");
				expect(fileExists(tempRoot & "/app/models/Destroyprobe.cfc")).toBeFalse();
			});

		});

		describe("docs", () => {

			it("an unknown action and status outside a project exit non-zero", () => {
				expect(failure(cli(), "docs", ["bogus"])).toBe("Wheels.InvalidArguments");
				expect(failure(cli(variables.emptyDir), "docs", ["status"])).toBe("Wheels.DocsStatusFailed");
			});

		});

		describe("deploy", () => {

			it("a servers list with no hosts is a configuration error", () => {
				var validator = new cli.lucli.services.deploy.config.Validator();
				for (var empty in [[], {web = []}, {web = {hosts = []}}]) {
					var state = {type = ""};
					try {
						validator.$validateServers(empty, "config/deploy.yml");
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("DeployConfigError", "accepted servers: #serializeJSON(empty)#");
				}
				expect(validator.$serverHostCount({web = ["10.0.0.1"], jobs = {hosts = ["10.0.0.2", "10.0.0.3"]}})).toBe(3);
			});

		});

		describe("wheels start --engine=rustcfml on a busy port", () => {

			it("refuses before starting anything when the port is already in use", () => {
				var engine = new cli.lucli.services.rustcfml.RustCFMLEngine();
				prepareMock(engine);
				engine.$("$portInUse", true);
				engine.$("install", "/should/not/be/called");
				var state = {type = ""};
				try {
					engine.start(variables.tempRoot, 8933);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.RustCFML.PortInUse");
				expect(engine.$count("install")).toBe(0, "the binary was fetched or started despite the busy port");
			});

			it("reports a server that exits right after starting, with its log, and records no state", () => {
				var src = fileRead(expandPath("/cli/lucli/services/rustcfml/RustCFMLEngine.cfc"));
				expect(src).toInclude("Wheels.RustCFML.StartFailed");
				expect(Find("Wheels.RustCFML.StartFailed", src)).toBeLT(Find("$writeState(arguments.projectRoot, state);", src));
			});

		});

	}

}
