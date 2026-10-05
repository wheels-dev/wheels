/**
 * `wheels new` must not hand out a port another project already pins in its
 * lucee.json, even when that project isn't running: a listener probe can't
 * see a stopped app, but the app starts on its pinned ports. Projects come
 * from the server registry and from the folders next to the new app.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("wheels new avoids ports other projects pin", () => {

			beforeEach(() => {
				variables.base = getTempDirectory() & "newpins-" & createUUID();
				variables.parent = variables.base & "/apps";
				variables.home = variables.base & "/home";
				directoryCreate(variables.parent, true, true);
				directoryCreate(variables.home & "/servers", true, true);
				variables.port = freePort();
			});

			afterEach(() => {
				if (directoryExists(variables.base)) {
					directoryDelete(variables.base, true);
				}
			});

			it("skips a shutdown port pinned by a stopped sibling project", () => {
				pinProject(parent & "/sibling", port + 10, port + 1);
				var m = moduleWithHome();
				var context = contextFor(m, parent & "/newapp");
				expect(context.shutdownPort).notToBe(port + 1);
				expect(context.shutdownPort).toBeGT(port + 1);
				expect(printed(m)).toInclude("Shutdown port #port + 1# is pinned by ");
				expect(printed(m)).toInclude("sibling");
			});

			it("skips a shutdown port pinned by a registered project elsewhere", () => {
				var elsewhere = base & "/elsewhere/registered";
				pinProject(elsewhere, port + 1, port + 20);
				directoryCreate(home & "/servers/registered", true, true);
				fileWrite(home & "/servers/registered/.project-path", elsewhere);
				var m = moduleWithHome();
				var context = contextFor(m, parent & "/newapp");
				expect(context.shutdownPort).toBeGT(port + 1);
				expect(printed(m)).toInclude("registered");
			});

			it("warns when the HTTP port itself is pinned by another project", () => {
				pinProject(parent & "/sibling", port, port + 30);
				var m = moduleWithHome();
				var context = contextFor(m, parent & "/newapp");
				expect(context.port).toBe(port);
				expect(printed(m)).toInclude("Port #port# is also pinned by ");
			});

			it("ignores the new app's own folder", () => {
				pinProject(parent & "/newapp", port + 40, port + 1);
				var m = moduleWithHome();
				var context = contextFor(m, parent & "/newapp");
				var said = printed(m);
				// The app's own lucee.json is never reported as another project's pin.
				expect(said).notToInclude("pinned by");
				// Normally it keeps port + 1. Another process may hold port + 1 while
				// the CLI probes it and let go before any check here could see it
				// (a re-probe afterwards raced), so judge by the reason the CLI gives
				// for moving it: a live listener ("in use"), never the pin.
				if (context.shutdownPort != port + 1) {
					expect(context.shutdownPort).toBeGT(port + 1);
					expect(said).toInclude("Shutdown port #port + 1# is in use");
				}
			});

			it("moves only for a live listener when port + 1 is briefly busy (the race)", () => {
				pinProject(parent & "/newapp", port + 40, port + 1);
				var m = moduleWithHome();
				// Held only while the context is built, released before any assertion:
				// the window that made the old re-probe-afterwards check flaky.
				var holder = createObject("java", "java.net.ServerSocket").init(port + 1);
				var context = {};
				try {
					context = contextFor(m, parent & "/newapp");
				} finally {
					holder.close();
				}
				var said = printed(m);
				expect(context.shutdownPort).toBeGT(port + 1);
				expect(said).toInclude("Shutdown port #port + 1# is in use");
				expect(said).notToInclude("pinned by");
			});

		});

	}

	private void function pinProject(required string dir, required numeric httpPort, required numeric shutdownPort) {
		directoryCreate(arguments.dir, true, true);
		fileWrite(arguments.dir & "/lucee.json", serializeJSON({port: arguments.httpPort, shutdownPort: arguments.shutdownPort}));
	}

	private any function moduleWithHome() {
		var m = new cli.lucli.Module(cwd = parent);
		prepareMock(m);
		m.$("out");
		m.$(method = "$resolveLucliHome", returns = home);
		makePublic(m, "$newTemplateContext");
		return m;
	}

	private struct function contextFor(required any m, required string targetDir) {
		return arguments.m.$newTemplateContext("newapp", {
			port: port,
			datasource: "newapp",
			reloadPassword: "r",
			luceeAdminPassword: "a",
			openBrowser: false,
			noSQLite: true
		}, arguments.targetDir);
	}

	private string function printed(required any m) {
		var said = "";
		for (var call in arguments.m.$callLog().out) {
			said &= call[1] & chr(10);
		}
		return said;
	}

	// An ephemeral port with room above it, released before use.
	private numeric function freePort() {
		var socket = createObject("java", "java.net.ServerSocket").init(0);
		var p = socket.getLocalPort();
		socket.close();
		return p > 65400 ? 50000 : p;
	}

}
