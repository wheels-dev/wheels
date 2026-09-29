/**
 * cli.lucli.tests.TestSockets: the listener ownership specs use must be this
 * process's alone. While it holds 127.0.0.1:<port>, a second socket, even one
 * with SO_REUSEADDR, must not be able to bind the same address and port.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("TestSockets.exclusiveLoopbackListener", () => {

			it("holds 127.0.0.1:<port> exclusively", () => {
				var listener = new cli.lucli.tests.TestSockets().exclusiveLoopbackListener();
				var state = {bound = false};
				var shadow = createObject("java", "java.net.ServerSocket").init();
				try {
					shadow.setReuseAddress(true);
					try {
						shadow.bind(createObject("java", "java.net.InetSocketAddress").init("127.0.0.1", javacast("int", listener.getLocalPort())));
						state.bound = true;
					} catch (any e) {
						state.bound = false;
					}
				} finally {
					try { shadow.close(); } catch (any e) {}
					listener.close();
				}
				expect(state.bound).toBeFalse("another socket bound 127.0.0.1:#listener.getLocalPort()# while the listener held it");
			});

		});

	}

}
