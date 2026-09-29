/**
 * Listening sockets for CLI specs that need the OS to see THIS process, and
 * only this process, listening on a port.
 *
 * A wildcard `new ServerSocket(0)` is not enough on macOS/BSD: another
 * process whose socket sets SO_REUSEADDR (Java's default) may bind the more
 * specific 127.0.0.1:<same port>, even pick it as its own ephemeral port. Then
 * two processes listen there, the ownership check (ServerRegistry
 * .listenerOwnedBy) rightly answers "no", and a spec expecting this JVM's
 * server fails for no reason in the code (#3804 and its ServerDetectionSpec
 * sibling). An exact 127.0.0.1 bind without SO_REUSEADDR leaves no room.
 */
component {

	/** A ServerSocket on 127.0.0.1:<ephemeral>, bound without SO_REUSEADDR. */
	public any function exclusiveLoopbackListener() {
		return exclusiveListener("127.0.0.1");
	}

	/** A ServerSocket on `address`:<ephemeral>, bound without SO_REUSEADDR. */
	public any function exclusiveListener(required string address) {
		var listener = createObject("java", "java.net.ServerSocket").init();
		listener.setReuseAddress(false);
		listener.bind(createObject("java", "java.net.InetSocketAddress").init(arguments.address, javacast("int", 0)));
		return listener;
	}

}
