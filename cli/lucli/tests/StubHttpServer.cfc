/**
 * Minimal fixed-status HTTP stub server for CLI specs (#3059).
 *
 * Binds a wildcard java.net.ServerSocket on an ephemeral port and answers
 * every connection with a fixed status line and an empty body, from a
 * background thread. Used by ReloadCommandSpec to stand in for a Wheels dev
 * server whose `?reload=true` endpoint 500s (the #3053 Adobe regression),
 * serves the page normally (wrong reload password -> 200), or
 * restarts-then-redirects (successful reload -> 302).
 *
 * Built on raw sockets (java.base) instead of com.sun.net.httpserver — the
 * jdk.httpserver module is not reachable from Lucee's OSGi classloader, so
 * createDynamicProxy over HttpHandler dies with NoClassDefFoundError.
 *
 * Callers MUST stop() the stub (in `finally`) — the accept loop runs until
 * the ServerSocket is closed, and the engine waits on spawned threads at
 * request end, so a leaked stub would hang the whole test request.
 */
component {

	public any function init(required numeric statusCode) {
		variables.statusCode = arguments.statusCode;
		// Port 0 + no bind address = ephemeral port on the wildcard address,
		// covering both stacks so the CLI's `http://localhost:<port>/...`
		// connect succeeds whether localhost resolves to 127.0.0.1 or ::1
		// (same dual-stack concern as PortProbeSpec).
		variables.serverSocket = createObject("java", "java.net.ServerSocket").init(javacast("int", 0));
		variables.threadName = "stub-http-" & createUUID();

		// Thread attributes are passed unquoted so the ServerSocket arrives as
		// the live object, not a string render. Unscoped assignments inside a
		// thread body are thread-local (`var` is reserved for functions).
		thread name="#variables.threadName#" srv=variables.serverSocket code=variables.statusCode {
			crlf = chr(13) & chr(10);
			response = "HTTP/1.1 " & attributes.code & " Stub" & crlf
				& "Content-Length: 0" & crlf
				& "Connection: close" & crlf & crlf;
			responseBytes = response.getBytes("ISO-8859-1");
			try {
				while (true) {
					sock = attributes.srv.accept();
					try {
						// Never let a silent client (e.g. the isPortOpen()
						// connect-probe, which sends nothing) wedge the loop.
						sock.setSoTimeout(javacast("int", 2000));
						// Drain the request headers (until CRLFCRLF or EOF)
						// before responding, so the client never sees a reset
						// while its request is still in flight.
						tail = "";
						inStream = sock.getInputStream();
						while (true) {
							byteRead = inStream.read();
							if (byteRead == -1) break;
							tail = right(tail & chr(byteRead), 4);
							if (tail == crlf & crlf) break;
						}
						outStream = sock.getOutputStream();
						outStream.write(responseBytes);
						outStream.flush();
					} catch (any inner) {
						// Per-connection failure (probe disconnects, read
						// timeout) — keep serving until the socket closes.
					}
					try {
						sock.close();
					} catch (any closeErr) {
					}
				}
			} catch (any e) {
				// ServerSocket closed by stop() — accept() throws, loop exits.
			}
		}

		return this;
	}

	public numeric function getPort() {
		return variables.serverSocket.getLocalPort();
	}

	public void function stop() {
		try {
			variables.serverSocket.close();
		} catch (any e) {
		}
		try {
			threadJoin(variables.threadName, 5000);
		} catch (any e) {
		}
	}

}
