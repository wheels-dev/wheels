/**
 * `wheels start` changes nothing when it has nothing to start (#4411), and takes the environment
 * profile from `--env` / `-e` as it does from `--environment` (#4412).
 *
 * - A dry run, or a start while the project's server is already running, leaves lucee.json, the
 *   project and the server registry alone.
 * - `-p N` / `-p=N` is `--port=N`: the shutdown port is moved off it.
 * - LuCLI takes `--env` / `-e` as its own root option, so the value never reaches the module's
 *   arguments; `wheels start` forwards it to LuCLI's server start as `--environment=<name>`.
 *
 * The registry runs against a temp LUCLI_HOME and the LuCLI launch is mocked: nothing under
 * ~/.wheels is touched and no server starts.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("wheels start with nothing to start", () => {

			beforeEach(() => {
				setUpProject();
			});

			afterEach(() => {
				tearDownProject();
			});

			it("leaves lucee.json alone when the server is already running", () => {
				var held = createObject("java", "java.net.ServerSocket").init(variables.shutdownPort);
				try {
					register(variables.serverName, variables.project, variables.httpPort);
					var m = moduleFor();
					m.start();
					expect(fileRead(variables.project & "/lucee.json")).toBe(variables.config, "lucee.json changed");
					expect(m.$count("executeCommand")).toBe(0);
					expect(printed(m)).toInclude("is already running");
				} finally {
					held.close();
				}
			});

			it("leaves lucee.json and the project alone on a dry run with --port", () => {
				var m = moduleFor();
				m.start(arg1 = "--dry-run", arg2 = "--port=#variables.httpPort + 10#");
				expect(fileRead(variables.project & "/lucee.json")).toBe(variables.config, "lucee.json changed");
				expect(m.$count("executeCommand")).toBe(1, "LuCLI's server start --dry-run was not reached");
				var forwarded = m.$callLog().executeCommand[1][2];
				expect(ArrayFind(forwarded, "--dry-run")).toBeGT(0);
				expect(ArrayFind(forwarded, "--port=#variables.httpPort + 10#")).toBeGT(0, "the port wasn't passed to LuCLI's dry run: " & ArrayToList(forwarded, " "));
				expect(m.$count("$ensureWheelsBundles")).toBe(0);
				expect(m.$count("$ensureProjectRewriteConfig")).toBe(0);
				expect(m.$count("$issueStartToken")).toBe(0);
			});

			it("leaves lucee.json alone on a dry run whose shutdown port is taken", () => {
				var held = createObject("java", "java.net.ServerSocket").init(variables.shutdownPort);
				try {
					var m = moduleFor();
					m.start(arg1 = "--dry-run");
					expect(fileRead(variables.project & "/lucee.json")).toBe(variables.config, "lucee.json changed");
				} finally {
					held.close();
				}
			});

		});

		describe("wheels start -p", () => {

			beforeEach(() => {
				setUpProject();
			});

			afterEach(() => {
				tearDownProject();
			});

			it("treats -p N as --port=N and moves the shutdown port off it", () => {
				var port = variables.shutdownPort;
				var m = moduleFor();
				m.start(arg1 = "-p", arg2 = "#port#");
				var written = DeserializeJSON(fileRead(variables.project & "/lucee.json"));
				expect(written.port).toBe(port);
				expect(written.shutdownPort).notToBe(port);
				var forwarded = ArrayToList(m.$callLog().executeCommand[1][2], " ");
				expect(forwarded).notToInclude("-p");
			});

			it("treats -p=N the same way", () => {
				var port = variables.shutdownPort;
				var m = moduleFor();
				m.start(p = "#port#");
				var written = DeserializeJSON(fileRead(variables.project & "/lucee.json"));
				expect(written.port).toBe(port);
				expect(written.shutdownPort).notToBe(port);
				expect(ArrayToList(m.$callLog().executeCommand[1][2], " ")).notToInclude("--p=");
			});

		});

		describe("wheels start --env", () => {

			beforeEach(() => {
				setUpProject();
			});

			afterEach(() => {
				tearDownProject();
			});

			it("forwards the environment LuCLI took from --env / -e as --environment", () => {
				var m = moduleFor();
				m.$("$lucliRootEnvironment", "prod");
				m.start(arg1 = "--dry-run");
				var forwarded = m.$callLog().executeCommand[1][2];
				expect(ArrayFind(forwarded, "--environment=prod")).toBeGT(0, "forwarded: " & ArrayToList(forwarded, " "));
			});

			it("lets an explicit --environment win and doesn't add a second one", () => {
				var m = moduleFor();
				m.$("$lucliRootEnvironment", "prod");
				m.start(arg1 = "--dry-run", arg2 = "--environment=staging");
				var forwarded = ArrayToList(m.$callLog().executeCommand[1][2], " ");
				expect(forwarded).toInclude("--environment=staging");
				expect(forwarded).notToInclude("--environment=prod");
			});

			it("reads --env / -e back from a command line", () => {
				var m = new cli.lucli.Module(cwd = variables.project);
				expect(m.$environmentFromArgv(["-cp", "x.jar", "org.lucee.lucli.LuCLI", "start", "--env=prod"])).toBe("prod");
				expect(m.$environmentFromArgv(["start", "--env", "staging", "--dry-run"])).toBe("staging");
				expect(m.$environmentFromArgv(["start", "-e", "qa"])).toBe("qa");
				expect(m.$environmentFromArgv(["start", "-e=dev"])).toBe("dev");
				expect(m.$environmentFromArgv(["start", "--environment=prod", "--dry-run"])).toBe("");
				expect(m.$environmentFromArgv(["start", "--env"])).toBe("");
			});

			it("adds nothing when no environment was given", () => {
				var m = moduleFor();
				m.$("$lucliRootEnvironment", "");
				m.start(arg1 = "--dry-run");
				expect(ArrayToList(m.$callLog().executeCommand[1][2], " ")).notToInclude("--environment");
			});

		});

	}

	private void function setUpProject() {
		variables.base = getTempDirectory() & "startfx-" & createUUID();
		variables.home = variables.base & "/home";
		variables.project = variables.base & "/app";
		directoryCreate(variables.home & "/servers", true, true);
		directoryCreate(variables.project & "/config", true, true);
		fileWrite(variables.project & "/config/settings.cfm", "<cfscript></cfscript>");
		variables.serverName = "startfx" & Left(Replace(createUUID(), "-", "", "all"), 8);
		variables.httpPort = freePort();
		variables.shutdownPort = freePort();
		variables.config = '{#Chr(10)#  "name": "#variables.serverName#",#Chr(10)#  "port": #variables.httpPort#,#Chr(10)#  "shutdownPort": #variables.shutdownPort##Chr(10)#}#Chr(10)#';
		fileWrite(variables.project & "/lucee.json", variables.config);
	}

	private void function tearDownProject() {
		if (directoryExists(variables.base)) {
			directoryDelete(variables.base, true);
		}
	}

	private numeric function freePort() {
		var probe = createObject("java", "java.net.ServerSocket").init(0);
		var port = probe.getLocalPort();
		probe.close();
		return port;
	}

	// A registration as LuCLI writes it: server.pid is "<pid>:<port>", with this JVM's pid, which is
	// alive for the whole spec.
	private void function register(required string name, required string projectPath, required numeric port) {
		var dir = variables.home & "/servers/" & arguments.name;
		directoryCreate(dir, true, true);
		fileWrite(dir & "/server.pid", createObject("java", "java.lang.ProcessHandle").current().pid() & ":" & arguments.port);
		fileWrite(dir & "/.project-path", arguments.projectPath);
	}

	private any function moduleFor() {
		var m = new cli.lucli.Module(cwd = variables.project);
		prepareMock(m);
		m.$("out");
		m.$("$resolveLucliHome", variables.home);
		m.$("$refuseOtherEngine");
		m.$("executeCommand");
		m.$("$ensureWheelsBundles");
		m.$("$ensureProjectRewriteConfig");
		m.$("$issueStartToken");
		return m;
	}

	private string function printed(required any m) {
		var said = "";
		for (var call in arguments.m.$callLog().out) {
			said &= call[1] & Chr(10);
		}
		return said;
	}

}
