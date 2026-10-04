/**
 * Two things every second app on a machine ran into:
 *
 * - `wheels new` gave every app port 8080, so the second app's `wheels start`
 *   collided with the first. Without --port it now takes the first port from
 *   8080 that is free and not pinned in another project's lucee.json.
 * - On that collision `wheels start` warned and went on, and LuCLI then
 *   failed with "Use: lucli server stop <name>", a binary a Wheels install
 *   doesn't have. It now stops first, names the Wheels server holding the
 *   port, and suggests `wheels stop` or a free --port.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("wheels start with its HTTP port taken", () => {

			beforeEach(() => {
				setUpDirs();
			});

			afterEach(() => {
				tearDownDirs();
			});

			it("names the registered Wheels server holding the port and how to stop it", () => {
				var held = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var port = held.getLocalPort();
					register("other-app", variables.base & "/elsewhere/other-app", port);
					var m = moduleFor(variables.parent & "/this-app");
					var thrown = refuse(m, port);
					expect(thrown).toBe("Wheels.PortInUse");
					var said = printed(m);
					expect(said).toInclude("Port #port# (configured in lucee.json) is in use by the Wheels server 'other-app'.");
					expect(said).toInclude("cd #variables.base#/elsewhere/other-app && wheels stop");
					expect(said).toInclude("wheels start --port=");
					expect(said).notToInclude("lucli");
				} finally {
					held.close();
				}
			});

			it("says another process when no registered server records the port", () => {
				var held = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var port = held.getLocalPort();
					var m = moduleFor(variables.parent & "/this-app");
					expect(refuse(m, port)).toBe("Wheels.PortInUse");
					var said = printed(m);
					expect(said).toInclude("is in use by another process.");
					expect(said).toInclude("wheels start --port=");
				} finally {
					held.close();
				}
			});

		});

		describe("ServerRegistry.registrationOnPort", () => {

			beforeEach(() => {
				setUpDirs();
			});

			afterEach(() => {
				tearDownDirs();
			});

			it("returns the live registration whose server.pid records the port", () => {
				register("live", "/apps/live", 61234);
				var found = new cli.lucli.services.ServerRegistry(lucliHome = variables.home).registrationOnPort(61234);
				expect(found.name).toBe("live");
				expect(found.projectPath).toBe("/apps/live");
			});

			it("ignores a registration on another port or with a dead pid", () => {
				register("live", "/apps/live", 61234);
				register("dead", "/apps/dead", 61235, "2147483646");
				var registry = new cli.lucli.services.ServerRegistry(lucliHome = variables.home);
				expect(registry.registrationOnPort(61236).name).toBe("");
				expect(registry.registrationOnPort(61235).name).toBe("");
			});

		});

		describe("wheels new without --port", () => {

			beforeEach(() => {
				setUpDirs();
			});

			afterEach(() => {
				tearDownDirs();
			});

			it("skips 8080 and 8081 when other projects pin them", () => {
				directoryCreate(variables.parent & "/first", true, true);
				fileWrite(variables.parent & "/first/lucee.json", serializeJSON({port: 8080, shutdownPort: 8081}));
				var m = moduleFor(variables.parent & "/second");
				makePublic(m, "$defaultNewPort");
				var port = m.$defaultNewPort(variables.parent & "/second");
				expect(port).toBeGT(8081);
				expect(printed(m)).toInclude("Port 8080 is pinned by ");
			});

			it("leaves the port to scaffoldNewApp only when --port wasn't given", () => {
				var m = moduleFor(variables.parent);
				m.$(method = "scaffoldNewApp", returns = "");
				m.new(arg1 = "portless");
				expect(m.$callLog().scaffoldNewApp[1][2].port).toBe(0);
				m.new(arg1 = "pinned", port = 3000);
				expect(m.$callLog().scaffoldNewApp[2][2].port).toBe(3000);
			});

		});

	}

	private void function setUpDirs() {
		variables.base = getTempDirectory() & "startport-" & createUUID();
		variables.parent = variables.base & "/apps";
		variables.home = variables.base & "/home";
		directoryCreate(variables.parent, true, true);
		directoryCreate(variables.home & "/servers", true, true);
	}

	private void function tearDownDirs() {
		if (directoryExists(variables.base)) {
			directoryDelete(variables.base, true);
		}
	}

	// A registration as LuCLI writes it: server.pid is "<pid>:<port>". The pid
	// defaults to this JVM's, which is alive for the whole spec.
	private void function register(required string name, required string projectPath, required numeric port, string pid = "") {
		var dir = variables.home & "/servers/" & arguments.name;
		directoryCreate(dir, true, true);
		var livePid = len(arguments.pid) ? arguments.pid : createObject("java", "java.lang.ProcessHandle").current().pid();
		fileWrite(dir & "/server.pid", livePid & ":" & arguments.port);
		fileWrite(dir & "/.project-path", arguments.projectPath);
	}

	private any function moduleFor(required string projectDir) {
		directoryCreate(arguments.projectDir, true, true);
		var m = new cli.lucli.Module(cwd = arguments.projectDir);
		prepareMock(m);
		m.$("out");
		m.$(method = "$resolveLucliHome", returns = variables.home);
		makePublic(m, "$refuseTakenHttpPort");
		return m;
	}

	private string function refuse(required any m, required numeric port) {
		var state = {type: ""};
		try {
			arguments.m.$refuseTakenHttpPort(arguments.port);
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	private string function printed(required any m) {
		var said = "";
		for (var call in arguments.m.$callLog().out) {
			said &= call[1] & chr(10);
		}
		return said;
	}

}
