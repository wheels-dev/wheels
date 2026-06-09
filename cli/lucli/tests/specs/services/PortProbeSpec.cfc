/**
 * Coverage for cli.lucli.services.PortProbe — the cross-address-family
 * port-in-use probe `wheels start` uses to warn before booting on top of a
 * port that is already taken.
 *
 * Regression intent: LuCLI's bind-based port check was IPv4-blind on a
 * dual-stack JVM (a wildcard ServerSocket binds IPv6 and never conflicts with
 * an IPv4-only listener), so a port held by python http.server / Django
 * runserver / a 127.0.0.1-bound service was reported "available". PortProbe
 * uses a connect probe against both loopback families so an IPv4-only listener
 * is correctly seen as in-use.
 *
 * Tests bind real loopback sockets on OS-assigned ephemeral ports, so they are
 * hermetic and never collide with a developer's running servers.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.probe = new cli.lucli.services.PortProbe();
	}

	function run() {
		describe("PortProbe.portInUse", () => {

			it("reports a port held by an IPv4-only (127.0.0.1) listener as in use", () => {
				var server = createObject("java", "java.net.ServerSocket").init();
				try {
					server.setReuseAddress(false);
					server.bind(
						createObject("java", "java.net.InetSocketAddress").init(
							createObject("java", "java.net.InetAddress").getByName("127.0.0.1"),
							javaCast("int", 0)
						)
					);
					var port = server.getLocalPort();
					expect(probe.portInUse(port)).toBeTrue();
				} finally {
					server.close();
				}
			});

			it("reports a free port (nothing listening) as not in use", () => {
				// Bind then immediately release to obtain a port we know is free.
				var server = createObject("java", "java.net.ServerSocket").init();
				server.bind(
					createObject("java", "java.net.InetSocketAddress").init(
						createObject("java", "java.net.InetAddress").getByName("127.0.0.1"),
						javaCast("int", 0)
					)
				);
				var port = server.getLocalPort();
				server.close();

				expect(probe.portInUse(port)).toBeFalse();
			});

		});
	}

}
