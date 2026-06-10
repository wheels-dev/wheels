/**
 * Reliable, cross-address-family "is this port already taken?" probe for
 * `wheels start`.
 *
 * Why this exists: LuCLI's own port check (LuceeServerConfig.isPortAvailable)
 * was IPv4-blind on a dual-stack JVM. `new ServerSocket(port)` binds the IPv6
 * wildcard, which does NOT conflict with a listener bound to the IPv4 family —
 * so a port already held by an IPv4-only process (python http.server, Django
 * runserver on 8000, Postgres/Redis on 127.0.0.1, ...) was reported "available"
 * and `wheels start` booted on top of it, producing a split-stack collision
 * (IPv4-loopback clients hit the other process, `localhost`->::1 hits Lucee).
 *
 * That root cause is fixed upstream in LuCLI, but `wheels start` also probes
 * here so the collision is caught even on LuCLI binaries that predate the fix
 * (defense in depth). We detect a listener by CONNECTing to both loopback
 * families (127.0.0.1 and ::1): a successful connect means something is actively
 * accepting on that port, and connect — unlike a bind probe — is not fooled by
 * sockets in TIME_WAIT, so it does not flag a port a server just released.
 *
 * Dependency-free leaf service (like Helpers): instantiated directly so it is
 * trivially unit-testable. See ServerRegistry for the sibling pattern.
 */
component {

	/**
	 * True if a process is actively LISTENing on `port` on either loopback
	 * address family (IPv4 127.0.0.1 or IPv6 ::1).
	 */
	public boolean function portInUse(required numeric port) {
		return $isListening("127.0.0.1", arguments.port)
			|| $isListening("::1", arguments.port);
	}

	/**
	 * True if a TCP connection to host:port succeeds within timeoutMs — i.e.
	 * something is accepting connections there. Connection refused, timeout, or
	 * an unresolvable/unreachable host all mean "nothing listening here" and
	 * return false. Loopback connects resolve essentially instantly (immediate
	 * accept or RST), so the timeout only bounds pathological cases.
	 */
	private boolean function $isListening(
		required string host,
		required numeric port,
		numeric timeoutMs = 200
	) {
		var socket = createObject("java", "java.net.Socket").init();
		try {
			var address = createObject("java", "java.net.InetSocketAddress").init(
				createObject("java", "java.net.InetAddress").getByName(arguments.host),
				javaCast("int", arguments.port)
			);
			socket.connect(address, javaCast("int", arguments.timeoutMs));
			return true;
		} catch (any e) {
			return false;
		} finally {
			try { socket.close(); } catch (any e) {}
		}
	}

}
