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
	 *
	 * `routes`, when given, maps a request path (e.g. "/docs.zip", query
	 * string ignored) to a raw binary response for that path; any other path
	 * gets the fixed status / rawResponse. Build responses with
	 * binaryResponse(). A route whose value is the string "HOLD" reads the
	 * request and never answers: it holds the connection until the client
	 * gives up, the stub stops, or 30 s pass (so a spec can't wedge the run),
	 * standing in for a server that accepts and then stalls.
	 */
	public any function init(
		required numeric statusCode,
		any rawResponse = "",
		string bindAddress = "",
		struct routes = {}
	) {
		variables.statusCode = arguments.statusCode;
		variables.rawResponse = arguments.rawResponse;
		variables.routes = arguments.routes;
		// One address, exclusively (issue 3804): a wildcard bind can be shadowed
		// on macOS and BSD by another socket on 127.0.0.1:<same port>, which then
		// takes the connection (a wrong answer, or a silent one the client waits
		// on; #4232). The CLI dials 127.0.0.1, never localhost ($serverHost), so
		// the default is the loopback address, the same as ChallengeStubServer.
		variables.serverSocket = len(arguments.bindAddress)
			? new TestSockets().exclusiveListener(arguments.bindAddress)
			: new TestSockets().exclusiveLoopbackListener();
		variables.threadName = "stub-http-" & createUUID();
		// Raw request heads (request line + headers), in arrival order, so
		// specs can assert what the CLI actually put on the wire. A Java
		// queue crosses into the thread by reference and is thread-safe.
		variables.requestHeads = createObject("java", "java.util.concurrent.ConcurrentLinkedQueue").init();

		// Thread attributes are passed unquoted so the ServerSocket arrives as
		// the live object, not a string render. Unscoped assignments inside a
		// thread body are thread-local (`var` is reserved for functions).
		thread name="#variables.threadName#" srv=variables.serverSocket code=variables.statusCode heads=variables.requestHeads raw=variables.rawResponse routes=variables.routes {
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
						// Longer than the CLI's 3 s peer-identity check, which
						// runs on an open connection before the request is
						// written: a shorter timeout closed it first (#4232).
						sock.setSoTimeout(javacast("int", 10000));
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
						// "GET /path?query HTTP/1.1" -> "/path"
						reqPath = listFirst(listGetAt(listFirst(head, chr(13) & chr(10)) & " /", 2, " "), "?");
						if (structKeyExists(attributes.routes, reqPath) && !isBinary(attributes.routes[reqPath]) && attributes.routes[reqPath] == "HOLD") {
							// "HOLD": answer nothing; wait for the client to close.
							holdUntil = getTickCount() + 30000;
							sock.setSoTimeout(javacast("int", 250));
							while (!attributes.srv.isClosed() && getTickCount() < holdUntil) {
								try {
									if (inStream.read() == -1) break;
								} catch (any readErr) {
									if (!findNoCase("timed out", readErr.message)) break;
								}
							}
						} else {
							outStream = sock.getOutputStream();
							outStream.write(structKeyExists(attributes.routes, reqPath) ? attributes.routes[reqPath] : responseBytes);
							outStream.flush();
						}
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

	/**
	 * A complete HTTP/1.1 response (status line, Content-Length, body) as
	 * bytes, for `routes` / `rawResponse`. `body` may be a string or binary.
	 */
	public binary function binaryResponse(required numeric statusCode, required any body) {
		var bodyBytes = isBinary(arguments.body) ? arguments.body : charsetDecode(arguments.body, "utf-8");
		var crlf = chr(13) & chr(10);
		var headBytes = charsetDecode(
			"HTTP/1.1 " & arguments.statusCode & " Stub" & crlf
				& "Content-Type: application/octet-stream" & crlf
				& "Content-Length: " & len(bodyBytes) & crlf
				& "Connection: close" & crlf & crlf,
			"ISO-8859-1"
		);
		var buffer = createObject("java", "java.io.ByteArrayOutputStream").init();
		buffer.write(headBytes);
		buffer.write(bodyBytes);
		return buffer.toByteArray();
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
