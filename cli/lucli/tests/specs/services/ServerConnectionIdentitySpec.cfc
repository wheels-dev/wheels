/**
 * The CLI only talks to this project's server over a connection that
 * server's own process accepted (GHSA-x3cm-2j3q-jgg4).
 *
 * - $httpExchange() checks, on the connection it is about to use, that the
 *   verified server pid holds the peer socket, and only then writes. Anything
 *   else accepting the connection (another app on the same port, including one
 *   owned by another OS user) receives nothing.
 * - Requests go to the address the server binds, never "localhost".
 * - A RustCFML state entry is only trusted when its pid is this project's
 *   RustCFML process, not merely a live pid that owns the port.
 *
 * The stub servers run inside this JVM, so "the server pid" is this JVM's pid.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		variables.selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function freshModule() {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		makePublic(m, "$recordVerifiedServer");
		makePublic(m, "$serverOrigin");
		makePublic(m, "makeHttpRequestWithStatus");
		return m;
	}

	/** Status line + Content-Length + UTF-8 body, as bytes. */
	private any function rawBytes(required string statusLine, string extraHeaders = "", string body = "") {
		var crlf = chr(13) & chr(10);
		var bodyBytes = charsetDecode(arguments.body, "utf-8");
		return charsetDecode(
			arguments.statusLine & crlf & arguments.extraHeaders & "Content-Length: " & len(bodyBytes) & crlf & crlf & arguments.body,
			"utf-8"
		);
	}

	/**
	 * One request to a stub that answers `raw`, bound to 127.0.0.1 alone so no
	 * other loopback listener can take the connection (issue 3804). The stub
	 * records the request before it answers, so if it saw none, whatever
	 * answered was something else: that fails loudly instead of letting a
	 * stranger's response pass or fail the spec's own assertion.
	 */
	private struct function exchangeRaw(required any raw) {
		var stub = new cli.lucli.tests.StubHttpServer(200, arguments.raw, "127.0.0.1");
		try {
			return freshModule().makeHttpRequestWithStatus(requestUrl = "http://127.0.0.1:#stub.getPort()#/", followRedirects = false);
		} finally {
			var received = arrayLen(stub.requests());
			stub.stop();
			if (received != 1) {
				throw(
					type = "StubHttpServer.NotReached",
					message = "The stub on 127.0.0.1:#stub.getPort()# received #received# request(s), not 1: something else answered."
				);
			}
		}
	}

	/** A separate OS process that stays alive: {process, pid}. */
	private struct function otherProcess() {
		var proc = createObject("java", "java.lang.ProcessBuilder").init(["sleep", "60"]).start();
		return {process: proc, pid: proc.pid()};
	}

	function run() {

		describe("StubHttpServer loopback binding (issue 3804)", () => {

			it("holds its 127.0.0.1 port exclusively, so no other listener can answer there", () => {
				var stub = new cli.lucli.tests.StubHttpServer(200, "", "127.0.0.1");
				var state = {bound = false};
				var shadow = createObject("java", "java.net.ServerSocket").init();
				try {
					shadow.setReuseAddress(true);
					try {
						shadow.bind(createObject("java", "java.net.InetSocketAddress").init("127.0.0.1", javacast("int", stub.getPort())));
						state.bound = true;
					} catch (any e) {
						state.bound = false;
					}
				} finally {
					try { shadow.close(); } catch (any e) {}
					stub.stop();
				}
				expect(state.bound).toBeFalse("another socket bound 127.0.0.1:#stub.getPort()# while the stub held it");
			});

		});

		describe("peer-identity check on every request to a verified server", () => {

			it("sends the request when the verified server's pid accepted the connection", () => {
				var stub = new cli.lucli.tests.StubHttpServer(200);
				try {
					var m = freshModule();
					m.$recordVerifiedServer({port: stub.getPort(), pid: variables.selfPid, hosts: ["127.0.0.1"]});
					var result = m.makeHttpRequestWithStatus(requestUrl = "http://127.0.0.1:#stub.getPort()#/probe");
					expect(result.statusCode).toBe(200);
					expect(arrayLen(stub.requests())).toBe(1);
				} finally {
					stub.stop();
				}
			});

			it("sends NOTHING when a different process accepted the connection", () => {
				// The registry says the server is `other.pid`, but what accepts
				// the connection is this JVM's stub: a squatter, as far as the
				// CLI can tell. Not one byte may reach it.
				var stub = new cli.lucli.tests.StubHttpServer(200);
				var other = otherProcess();
				try {
					var m = freshModule();
					m.$recordVerifiedServer({port: stub.getPort(), pid: other.pid, hosts: ["127.0.0.1"]});
					var state = {type: "", message: ""};
					try {
						m.$httpExchange(
							requestUrl = "http://127.0.0.1:#stub.getPort()#/?reload=true",
							headers = {"X-Wheels-Reload-Password": "must-not-leak"}
						);
					} catch (any e) {
						state.type = e.type;
						state.message = e.message;
					}
					expect(state.type).toBe("Wheels.ServerNotOwned");
					expect(state.message).toInclude("sent nothing");
					expect(arrayLen(stub.requests())).toBe(0, "the squatter received a request");
				} finally {
					other.process.destroy();
					stub.stop();
				}
			});

			it("does not peer-check (or refuse) an unverified read-only server", () => {
				var stub = new cli.lucli.tests.StubHttpServer(200);
				try {
					var m = freshModule();
					var result = m.makeHttpRequestWithStatus(requestUrl = "http://127.0.0.1:#stub.getPort()#/");
					expect(result.statusCode).toBe(200);
				} finally {
					stub.stop();
				}
			});

			it("surfaces the raw 302 when followRedirects is false", () => {
				var stub = new cli.lucli.tests.StubHttpServer(302);
				try {
					var m = freshModule();
					var raw = m.makeHttpRequestWithStatus(requestUrl = "http://127.0.0.1:#stub.getPort()#/", followRedirects = false);
					expect(raw.statusCode).toBe(302);
				} finally {
					stub.stop();
				}
			});

		});

		describe("raw-socket transport reads HTTP responses strictly (rev1-r2 round 3 probes)", () => {

			it("reads a Content-Length body, including UTF-8", () => {
				var r = exchangeRaw(rawBytes("HTTP/1.1 200 OK", "", "café 😀"));
				expect(r.statusCode).toBe(200);
				expect(r.body).toBe("café 😀");
			});

			it("reads a chunked body with chunk extensions and trailers", () => {
				var crlf = chr(13) & chr(10);
				var r = exchangeRaw(charsetDecode("HTTP/1.1 200 OK" & crlf & "Transfer-Encoding: chunked" & crlf & crlf
					& "3;x=y" & crlf & "abc" & crlf & "2" & crlf & "de" & crlf & "0" & crlf & "X-End: yes" & crlf & crlf, "utf-8"));
				expect(r.body).toBe("abcde");
			});

			it("reads a close-delimited body when there is no Content-Length or chunking", () => {
				var crlf = chr(13) & chr(10);
				var r = exchangeRaw(charsetDecode("HTTP/1.1 200 OK" & crlf & crlf & "close body", "utf-8"));
				expect(r.body).toBe("close body");
			});

			it("returns a 500 with its body", () => {
				var r = exchangeRaw(rawBytes("HTTP/1.1 500 Error", "", "oops"));
				expect(r.statusCode).toBe(500);
				expect(r.body).toBe("oops");
			});

			it("FAILS on EOF before Content-Length bytes arrive (a cut-off report is not a success)", () => {
				var crlf = chr(13) & chr(10);
				expect(() => exchangeRaw(charsetDecode("HTTP/1.1 200 OK" & crlf & "Content-Length: 100" & crlf & crlf & '{"success":true}', "utf-8")))
					.toThrow(type = "Wheels.HttpResponseTruncated");
			});

			it("FAILS on a chunk cut off mid-data", () => {
				var crlf = chr(13) & chr(10);
				expect(() => exchangeRaw(charsetDecode("HTTP/1.1 200 OK" & crlf & "Transfer-Encoding: chunked" & crlf & crlf & "f" & crlf & '{"success":tr', "utf-8")))
					.toThrow(type = "Wheels.HttpResponseTruncated");
			});

			it("FAILS on a complete chunk with no terminating 0-chunk", () => {
				var crlf = chr(13) & chr(10);
				expect(() => exchangeRaw(charsetDecode("HTTP/1.1 200 OK" & crlf & "Transfer-Encoding: chunked" & crlf & crlf & "10" & crlf & '{"success":true}' & crlf, "utf-8")))
					.toThrow(type = "Wheels.HttpResponseTruncated");
			});

			it("FAILS on a malformed chunk size", () => {
				var crlf = chr(13) & chr(10);
				expect(() => exchangeRaw(charsetDecode("HTTP/1.1 200 OK" & crlf & "Transfer-Encoding: chunked" & crlf & crlf & "zz" & crlf & "abc" & crlf & "0" & crlf & crlf, "utf-8")))
					.toThrow(type = "Wheels.HttpResponseInvalid");
			});

			it("FAILS on a non-numeric Content-Length", () => {
				var crlf = chr(13) & chr(10);
				expect(() => exchangeRaw(charsetDecode("HTTP/1.1 200 OK" & crlf & "Content-Length: ten" & crlf & crlf & "0123456789", "utf-8")))
					.toThrow(type = "Wheels.HttpResponseInvalid");
			});

			it("FAILS clearly when the server closes without sending anything", () => {
				expect(() => exchangeRaw(charsetDecode("", "utf-8"))).toThrow(type = "Wheels.HttpNoResponse");
			});

			it("FAILS on a garbage status line", () => {
				var crlf = chr(13) & chr(10);
				expect(() => exchangeRaw(charsetDecode("hello there" & crlf & crlf, "utf-8"))).toThrow(type = "Wheels.HttpResponseInvalid");
			});

			it("skips 100 Continue and returns the final response", () => {
				var crlf = chr(13) & chr(10);
				var r = exchangeRaw(charsetDecode("HTTP/1.1 100 Continue" & crlf & crlf & "HTTP/1.1 200 OK" & crlf & "Content-Length: 2" & crlf & crlf & "ok", "utf-8"));
				expect(r.statusCode).toBe(200);
				expect(r.body).toBe("ok");
			});

			it("skips 102 and 103 interim responses too", () => {
				var crlf = chr(13) & chr(10);
				var r = exchangeRaw(charsetDecode("HTTP/1.1 102 Processing" & crlf & crlf & "HTTP/1.1 103 Early Hints" & crlf & "Link: </a.css>" & crlf & crlf
					& "HTTP/1.1 201 Created" & crlf & "Content-Length: 4" & crlf & crlf & "made", "utf-8"));
				expect(r.statusCode).toBe(201);
				expect(r.body).toBe("made");
			});

		});

		describe("ServerRegistry.peerHeldBy", () => {

			it("tells this JVM's accepted socket from another pid's", () => {
				var registry = new cli.lucli.services.ServerRegistry(lucliHome = getTempDirectory());
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				var clientSock = createObject("java", "java.net.Socket").init("127.0.0.1", javaCast("int", listener.getLocalPort()));
				var accepted = listener.accept();
				try {
					expect(registry.peerHeldBy(variables.selfPid, listener.getLocalPort(), clientSock.getLocalPort())).toBe("yes");
					expect(registry.peerHeldBy(1, listener.getLocalPort(), clientSock.getLocalPort())).toBe("no");
				} finally {
					accepted.close();
					clientSock.close();
					listener.close();
				}
			});

		});

		describe("requests go to the address the server binds, never localhost", () => {

			it("defaults to 127.0.0.1 for a server not verified as this project's", () => {
				expect(freshModule().$serverOrigin(8190)).toBe("http://127.0.0.1:8190");
			});

			it("uses the verified server's bound address, bracketing IPv6", () => {
				var m = freshModule();
				m.$recordVerifiedServer({port: 8190, pid: variables.selfPid, hosts: ["::1"]});
				expect(m.$serverOrigin(8190)).toBe("http://[::1]:8190");
			});

			it("reads the bound addresses from the listener itself", () => {
				var registry = new cli.lucli.services.ServerRegistry(lucliHome = getTempDirectory());
				var loopback = createObject("java", "java.net.InetAddress").getByName("127.0.0.1");
				var listener = createObject("java", "java.net.ServerSocket").init(0, 5, loopback);
				try {
					expect(registry.boundHosts(variables.selfPid, listener.getLocalPort())).toBe(["127.0.0.1"]);
				} finally {
					listener.close();
				}
			});

			it("decodes Linux /proc addresses, keeping specific non-loopback ones", () => {
				var registry = new cli.lucli.services.ServerRegistry(lucliHome = getTempDirectory());
				expect(registry.$procHexAddress("0100007F")).toBe("127.0.0.1");
				expect(registry.$procHexAddress("00000000")).toBe("0.0.0.0");
				expect(registry.$procHexAddress("0501A8C0")).toBe("192.168.1.5");
				expect(registry.$procHexAddress("00000000000000000000000000000000")).toBe("::");
				expect(registry.$procHexAddress("00000000000000000000000001000000")).toBe("::1");
				expect(registry.$procHexAddress("0000000000000000FFFF00000501A8C0")).toBe("192.168.1.5");
				expect(registry.$procHexAddress("B80D0120000000000000000001000000")).toBe("2001:db8:0:0:0:0:0:1");
				expect(registry.$procHexAddress("zz")).toBe("");
			});

			it("Module builds no dev-server URL from localhost", () => {
				var src = fileRead(expandPath("/cli/lucli/Module.cfc"));
				var hits = [];
				var pos = 1;
				while (true) {
					var m = reFind("""http://localhost:##", src, pos, true);
					if (m.pos[1] == 0) break;
					arrayAppend(hits, mid(src, m.pos[1], 60));
					pos = m.pos[1] + 1;
				}
				expect(hits).toBeEmpty();
			});

		});

		describe("RustCFML ownership needs this project's RustCFML process, not just a live pid", () => {

			it("accepts a managed binary serving this project's public directory", () => {
				var engine = new cli.lucli.services.rustcfml.RustCFMLEngine();
				prepareMock(engine);
				var bin = engine.$binDir() & "/rustcfml-v0";
				engine.$("$processInfo", {command: bin, commandLine: bin & " --serve " & engine.$servePath(variables.tempRoot) & " --port 8513"});
				expect(engine.isProjectServerProcess(123, variables.tempRoot)).toBeTrue();
			});

			it("refuses a reused pid running some other program", () => {
				var engine = new cli.lucli.services.rustcfml.RustCFMLEngine();
				prepareMock(engine);
				engine.$("$processInfo", {command: "/usr/bin/python3", commandLine: "/usr/bin/python3 -m http.server 8513"});
				expect(engine.isProjectServerProcess(123, variables.tempRoot)).toBeFalse();
			});

			it("refuses a RustCFML process serving a different project", () => {
				var engine = new cli.lucli.services.rustcfml.RustCFMLEngine();
				prepareMock(engine);
				var bin = engine.$binDir() & "/rustcfml-v0";
				engine.$("$processInfo", {command: bin, commandLine: bin & " --serve /some/other/project/public --port 8513"});
				expect(engine.isProjectServerProcess(123, variables.tempRoot)).toBeFalse();
			});

			it("refuses when the OS does not expose the process", () => {
				var engine = new cli.lucli.services.rustcfml.RustCFMLEngine();
				prepareMock(engine);
				engine.$("$processInfo", {command: "", commandLine: ""});
				expect(engine.isProjectServerProcess(123, variables.tempRoot)).toBeFalse();
			});

			it("a live, reused pid owning the recorded port is NOT this project's server", () => {
				// rev1-r2's repro: RustCFML state names a pid/port that belong to
				// an unrelated live listener. It used to pass on "alive + owns
				// the port" alone.
				var engine = new cli.lucli.services.rustcfml.RustCFMLEngine();
				var statePath = engine.$statePath(variables.tempRoot);
				directoryCreate(getDirectoryFromPath(statePath), true, true);
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				try {
					fileWrite(statePath, serializeJSON({pid: variables.selfPid, port: listener.getLocalPort(), binary: "/x", projectRoot: variables.tempRoot}));
					var m = new cli.lucli.Module(cwd = variables.tempRoot);
					prepareMock(m);
					makePublic(m, "$verifyOwnServer");
					var verdict = m.$verifyOwnServer();
					expect(verdict.port).toBe(0);
					expect(verdict.reason).toBe("pid-not-server");
				} finally {
					listener.close();
					if (fileExists(statePath)) fileDelete(statePath);
				}
			});

		});

	}

}
