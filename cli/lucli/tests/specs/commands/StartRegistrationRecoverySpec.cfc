/**
 * A failed `wheels start` (e.g. a port conflict) leaves a registration folder
 * under <LUCLI_HOME>/servers/<name> holding only LuCLI's config file, with no
 * `.project-path`. The next start must treat that as a leftover and clean it,
 * not refuse with "registered to a different project: <unknown>" (and exit 0).
 * A real registration for another project still refuses, now with a non-zero
 * exit, as does running outside a Wheels project.
 *
 * The registry runs against a temp LUCLI_HOME and the LuCLI launch is mocked:
 * nothing under ~/.wheels is touched and no server starts.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.lucliHome = getTempDirectory() & "start-reg-home-" & createUUID();
		directoryCreate(variables.lucliHome & "/servers", true);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
		if (directoryExists(variables.lucliHome)) directoryDelete(variables.lucliHome, true);
	}

	private any function startModule(required string cwd) {
		var m = new cli.lucli.Module(cwd = arguments.cwd);
		prepareMock(m);
		m.$("out");
		m.$("$resolveLucliHome", variables.lucliHome);
		m.$("executeCommand");
		m.$("$ensureWheelsBundles");
		m.$("$ensureProjectRewriteConfig");
		m.$("$issueStartToken");
		return m;
	}

	private string function regDir(required any m) {
		makePublic(arguments.m, "getService");
		return variables.lucliHome & "/servers/" & arguments.m.getService("serverRegistry").serverNameFor(variables.tempRoot);
	}

	private string function thrownType(required any fn) {
		var state = {type = ""};
		try {
			arguments.fn();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	function run() {

		describe("wheels start after a failed start", () => {

			it("cleans a dead registration that names no project and starts, instead of refusing", () => {
				var m = startModule(variables.tempRoot);
				var dir = regDir(m);
				directoryCreate(dir, true, true);
				fileWrite(dir & "/.config-file", "{}");
				m.__arguments = [];
				expect(thrownType(() => m.start())).toBe("", "the leftover registration blocked the start");
				expect(m.$count("executeCommand")).toBe(1, "LuCLI's server start was not reached");
				expect(directoryExists(dir)).toBeFalse("the leftover registration was not cleaned");
			});

			it("still refuses a stopped registration with no project path that isn't the failed-start shape", () => {
				// e.g. a stopped server from a plain-LuCLI or pre-4.0 project of the same name.
				var m = startModule(variables.tempRoot);
				var dir = regDir(m);
				directoryCreate(dir & "/lucee-server", true, true);
				fileWrite(dir & "/.config-file", "{}");
				m.__arguments = [];
				expect(thrownType(() => m.start())).toBe("Wheels.ServerNameConflict");
				expect(directoryExists(dir & "/lucee-server")).toBeTrue("a registration that isn't a leftover was wiped");
				directoryDelete(dir, true);
			});

			it("still refuses a registration for another project, now with a non-zero exit", () => {
				var m = startModule(variables.tempRoot);
				var dir = regDir(m);
				directoryCreate(dir, true, true);
				fileWrite(dir & "/.project-path", getTempDirectory() & "some-other-project");
				m.__arguments = [];
				expect(thrownType(() => m.start())).toBe("Wheels.ServerNameConflict");
				expect(m.$count("executeCommand")).toBe(0);
				expect(fileExists(dir & "/.project-path")).toBeTrue("another project's registration was removed");
				directoryDelete(dir, true);
			});

			it("exits non-zero outside a Wheels project", () => {
				var empty = getTempDirectory() & "not-a-project-" & createUUID();
				directoryCreate(empty);
				try {
					var m = startModule(empty);
					m.__arguments = [];
					expect(thrownType(() => m.start())).toBe("Wheels.NotAWheelsProject");
				} finally {
					directoryDelete(empty, true);
				}
			});

		});

	}

}
