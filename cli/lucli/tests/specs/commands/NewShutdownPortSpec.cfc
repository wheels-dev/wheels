/**
 * `wheels new --port=N` wrote shutdownPort = N + 1 into lucee.json without
 * checking it. Sibling apps are usually created with adjacent ports, so N + 1
 * was often another running app's port. The template context now takes the
 * first free port above N.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("wheels new shutdown port", () => {

			it("uses port + 1 when it is free", () => {
				// Bind an ephemeral port and release it, so port + 1 is very
				// likely free; skip if something else grabbed it meanwhile.
				var probe = createObject("java", "java.net.ServerSocket").init(0);
				var port = probe.getLocalPort();
				probe.close();
				if (new cli.lucli.services.PortProbe().portInUse(port + 1)) {
					skip("port #port + 1# is in use on this machine");
				}
				var context = contextFor(port);
				expect(context.port).toBe(port);
				expect(context.shutdownPort).toBe(port + 1);
			});

			it("skips port + 1 when another process is listening on it", () => {
				var held = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var busy = held.getLocalPort();
					var m = moduleWithOut();
					var context = contextFor(busy - 1, m);
					expect(context.port).toBe(busy - 1);
					// Assert only on the port the CLI chose. It comes from the ephemeral range, so another
					// process can bind it after the choice; probing it again here would race.
					expect(context.shutdownPort).toBeGT(busy);
					var said = "";
					for (var call in m.$callLog().out) {
						said &= call[1] & chr(10);
					}
					expect(said).toInclude("Shutdown port #busy# is in use; using #context.shutdownPort#.");
				} finally {
					held.close();
				}
			});

		});

	}

	private any function moduleWithOut() {
		var m = new cli.lucli.Module(cwd = expandPath("/"));
		prepareMock(m);
		m.$("out");
		makePublic(m, "$newTemplateContext");
		return m;
	}

	private struct function contextFor(required numeric port, any m) {
		var mod = isNull(arguments.m) ? moduleWithOut() : arguments.m;
		return mod.$newTemplateContext("portapp", {
			port: arguments.port,
			datasource: "portapp",
			reloadPassword: "r",
			luceeAdminPassword: "a",
			openBrowser: false,
			noSQLite: true
		});
	}

}
