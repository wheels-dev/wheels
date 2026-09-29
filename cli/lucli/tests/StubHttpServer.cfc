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

	/**
	 * `rawResponse` (binary), when given, is written verbatim instead of the
	 * fixed status line, then the connection closes: specs use it to send
	 * truncated, chunked or interim (1xx) responses.
	 */
	public any function init(required numeric statusCode, any rawResponse = "", string bindAddress = "") {
		variables.statusCode = arguments.statusCode;
		variables.rawResponse = arguments.rawResponse;
		if (len(arguments.bindAddress)) {
			// One address, exclusively (issue 3804): see TestSockets for why a
			// wildcard bind can be shadowed on macOS and BSD.
			variables.serverSocket = new TestSockets().exclusiveListener(arguments.bindAddress);
		} else {
			// Port 0 + no bind address = ephemeral port on the wildcard address,
			// covering both stacks so the CLI's `http://localhost:<port>/...`
			// connect succeeds whether localhost resolves to 127.0.0.1 or ::1
			// (same dual-stack concern as PortProbeSpec).
			variables.serverSocket = createObject("java", "java.net.ServerSocket").init(javacast("int", 0));
		}
		variables.threadName = "stub-http-" & createUUID();
		// Raw request heads (request line + headers), in arrival order, so
		// specs can assert what the CLI actually put on the wire. A Java
		// queue crosses into the thread by reference and is thread-safe.
		variables.requestHeads = createObject("java", "java.util.concurrent.ConcurrentLinkedQueue").init();

		// Thread attributes are passed unquoted so the ServerSocket arrives as
		// the live object, not a string render. Unscoped assignments inside a
		// thread body are thread-local (`var` is reserved for functions).
		thread name="#variables.threadName#" srv=variables.serverSocket code=variables.statusCode heads=variables.requestHeads raw=variables.rawResponse {
			crlf = chr(13) & chr(10);
			response = "HTTP/1.1 " & attributes.code & " Stub" & crlf
				& "Content-Length: 0" & crlf
				& "Connection: close" & crlf & crlf;
			responseBytes = isBinary(attributes.raw) ? attributes.raw : response.getBytes("ISO-8859-1");
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
						head = "";
						inStream = sock.getInputStream();
						while (true) {
							byteRead = inStream.read();
							if (byteRead == -1) break;
							head &= chr(byteRead);
							tail = right(tail & chr(byteRead), 4);
							if (tail == crlf & crlf) break;
						}
						if (len(head)) {
							attributes.heads.add(head);
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

	/**
	 * Raw heads of the HTTP requests received so far (connect-only probes
	 * that send nothing are not recorded).
	 */
	public array function requests() {
		var heads = [];
		for (var head in variables.requestHeads.toArray()) {
			arrayAppend(heads, head);
		}
		return heads;
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
