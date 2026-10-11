/**
 * `wheels deploy` argument handling (4417):
 *
 * - Space-form values (`--release v8`, `--service myapp2`) arrive from LuCLI as `flag="true"` plus a
 *   positional after a gap; they are bound to their flag instead of becoming the subcommand or being
 *   dropped. When several can't be told apart, the command asks for `--flag=value`.
 * - An unknown `--role` fails and names the roles deploy.yml defines.
 * - `deploy config` prints `ssh.port` as a whole number.
 * - `rollback` without a version and `exec` without a command throw their typed errors.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(variables.tempRoot & "/vendor/wheels", true, true);
		variables.minimal = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
		variables.withSsh = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/with-ssh.yml");
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function deployModule() {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		makePublic(m, "$deployArgv");
		return m;
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

		describe("wheels deploy space-form values", () => {

			it("binds --release v8 to --release instead of reading v8 as the subcommand", () => {
				var argv = deployModule().$deployArgv({"dry-run": "true", "release": "true", "arg3": "v8"});
				expect(ArrayFind(argv, "--release=v8")).toBeGT(0, ArrayToList(argv, " "));
				expect(ArrayFind(argv, "v8")).toBe(0);
			});

			it("binds --service myapp2 after a subcommand and a boolean flag", () => {
				var argv = deployModule().$deployArgv({"arg1": "init", "force": "true", "service": "true", "arg4": "myapp2"});
				expect(ArrayFind(argv, "--service=myapp2")).toBeGT(0, ArrayToList(argv, " "));
				expect(argv[1]).toBe("init");
			});

			it("asks for --flag=value when several space-form values can't be told apart", () => {
				var m = deployModule();
				expect(thrownType(() => m.$deployArgv({
					"arg1": "app", "arg2": "boot", "release": "true", "arg4": "abc1", "role": "true", "arg6": "web"
				}))).toBe("Wheels.InvalidArguments");
			});

			it("leaves --flag=value alone", () => {
				var argv = deployModule().$deployArgv({"dry-run": "true", "release": "v9"});
				expect(ArrayFind(argv, "--release=v9")).toBeGT(0);
			});

		});

		describe("wheels deploy --role", () => {

			it("fails on a role deploy.yml doesn't define, and names the ones it does", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				m.__arguments = ["app", "boot", "--dry-run", "--release=abc1", "--role=nope", "--configPath=#variables.minimal#"];
				var state = {type = "", message = ""};
				try {
					m.deploy();
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
				}
				expect(state.type).toBe("DeployAppCli.UnknownRole");
				expect(state.message).toInclude("nope");
				expect(state.message).toInclude("web");
			});

		});

		describe("wheels deploy config", () => {

			it("prints the default ssh.port as a whole number", () => {
				// No ssh: block, so the port is the default (the case `deploy init` produces).
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				m.__arguments = ["config", "--configPath=#variables.minimal#"];
				var out = m.deploy();
				expect(out).notToInclude("22.0");
				expect(out).notToInclude("80.0");
				expect(reFind("port:\s*22\b", out)).toBeGT(0, out);
			});

			it("prints a configured ssh.port as a whole number", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				m.__arguments = ["config", "--configPath=#variables.withSsh#"];
				var out = m.deploy();
				expect(out).toInclude("2222");
				expect(out).notToInclude("2222.0");
			});

		});

		describe("wheels deploy typed errors", () => {

			it("rollback without a version throws DeployMainCli.MissingVersion", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				m.__arguments = ["rollback", "--dry-run", "--configPath=#variables.minimal#"];
				expect(thrownType(() => m.deploy())).toBe("DeployMainCli.MissingVersion");
			});

			it("exec without a command throws DeployServerCli.MissingCommand", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				m.__arguments = ["exec", "--dry-run", "--configPath=#variables.minimal#"];
				expect(thrownType(() => m.deploy())).toBe("DeployServerCli.MissingCommand");
			});

			it("server exec without a command throws DeployServerCli.MissingCommand", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				m.__arguments = ["server", "exec", "--dry-run", "--configPath=#variables.minimal#"];
				expect(thrownType(() => m.deploy())).toBe("DeployServerCli.MissingCommand");
			});

		});

	}

}
