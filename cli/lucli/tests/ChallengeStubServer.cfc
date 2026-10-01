/**
 * An HTTP stub that answers the dev-server connection challenge (#3769) in a
 * chosen way, then serves the request that follows on the same connection.
 *
 * Modes, for `/wheels/cli?command=cliChallenge` requests:
 *   valid        the right MAC for this connection (lowercase hex)
 *   upper        the right MAC in uppercase hex (what CFML Hmac() returns)
 *   wrong        a MAC made with another token
 *   relay        the MAC a real server would give a relay: right token, but
 *                over a different client port (the relay's own connection)
 *   unavailable  {"v":1,"unavailable":true}, keeping the connection open
 *   close        a 404 with Connection: close (a framework without the
 *                challenge), then the connection closes
 * Any other request gets `200 ok`, Connection: close.
 *
 * Listens on 127.0.0.1 (or `bindAddress`) only, without SO_REUSEADDR, so no
 * other socket can share its port (see TestSockets).
 *
 * Runs in this JVM, so the "server pid" is this JVM's pid. Callers MUST
 * stop() it in `finally` (see StubHttpServer).
 */
component {

	public any function init(required string mode, required string token, string bindAddress = "") {
		// An exact bind without SO_REUSEADDR: a wildcard listener lets another
		// socket bind 127.0.0.1:<same port> on macOS/BSD and take the loopback
		// connection, which the peer check then (rightly) refuses (#3834).
		var sockets = new cli.lucli.tests.TestSockets();
		variables.serverSocket = len(arguments.bindAddress)
			? sockets.exclusiveListener(arguments.bindAddress)
			: sockets.exclusiveLoopbackListener();
		variables.threadName = "stub-challenge-" & createUUID();
		variables.requestHeads = createObject("java", "java.util.concurrent.ConcurrentLinkedQueue").init();
		variables.connections = createObject("java", "java.util.concurrent.atomic.AtomicInteger").init(0);

		thread name="#variables.threadName#" srv=variables.serverSocket heads=variables.requestHeads conns=variables.connections mode=arguments.mode token=arguments.token {
			crlf = chr(13) & chr(10);
			challenge = new cli.lucli.services.ServerChallenge();
			try {
				while (true) {
					sock = attributes.srv.accept();
					attributes.conns.incrementAndGet();
					try {
						sock.setSoTimeout(javacast("int", 3000));
						inStream = sock.getInputStream();
						outStream = sock.getOutputStream();
						keepServing = true;
						while (keepServing) {
							head = "";
							tail = "";
							while (true) {
								byteRead = inStream.read();
								if (byteRead == -1) break;
								head &= chr(byteRead);
								tail = right(tail & chr(byteRead), 4);
								if (tail == crlf & crlf) break;
							}
							if (!len(head)) break;
							attributes.heads.add(head);
							found = reFind("command=cliChallenge&v=1&nonce=([0-9a-f]{64})", head, 1, true);
							if (found.pos[1] == 0) {
								outStream.write(charsetDecode("HTTP/1.1 200 OK" & crlf & "Content-Length: 2" & crlf & "Connection: close" & crlf & crlf & "ok", "utf-8"));
								outStream.flush();
								keepServing = false;
								continue;
							}
							if (attributes.mode == "close") {
								outStream.write(charsetDecode("HTTP/1.1 404 Not Found" & crlf & "Content-Length: 0" & crlf & "Connection: close" & crlf & crlf, "utf-8"));
								outStream.flush();
								keepServing = false;
								continue;
							}
							nonceValue = mid(head, found.pos[2], found.len[2]);
							serverAddr = challenge.canonicalAddress(sock.getLocalAddress());
							clientAddr = challenge.canonicalAddress(sock.getInetAddress());
							clientPort = sock.getPort();
							key = attributes.token;
							if (attributes.mode == "relay") clientPort = clientPort + 1;
							if (attributes.mode == "wrong") key = repeatString("f", 64);
							macValue = challenge.mac(key, challenge.message(nonceValue, serverAddr, sock.getLocalPort(), clientAddr, clientPort));
							if (attributes.mode == "upper") macValue = uCase(macValue);
							body = attributes.mode == "unavailable" ? '{"v":1,"unavailable":true}' : '{"v":1,"mac":"' & macValue & '"}';
							bodyBytes = charsetDecode(body, "utf-8");
							outStream.write(charsetDecode("HTTP/1.1 200 OK" & crlf & "Content-Type: application/json" & crlf & "Content-Length: " & len(bodyBytes) & crlf & crlf, "utf-8"));
							outStream.write(bodyBytes);
							outStream.flush();
						}
					} catch (any inner) {
						// Per-connection failure (timeout, client close): keep serving.
					}
					try {
						sock.close();
					} catch (any closeErr) {
					}
				}
			} catch (any e) {
				// ServerSocket closed by stop().
			}
		}

		return this;
	}

	/** Raw request heads received so far, in arrival order. */
	public array function requests() {
		var heads = [];
		for (var head in variables.requestHeads.toArray()) {
			arrayAppend(heads, head);
		}
		return heads;
	}

	/** Connections accepted so far. */
	public numeric function connectionCount() {
		return variables.connections.get();
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
