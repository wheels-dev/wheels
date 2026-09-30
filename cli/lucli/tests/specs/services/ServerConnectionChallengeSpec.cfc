/**
 * The connection challenge on the CLI transport (#3769).
 *
 * With a per-start token, $httpExchange() proves each connection by the
 * challenge before writing anything on it: a right answer needs no OS
 * introspection, a wrong one fails closed, and "can't answer" falls back to
 * exactly the OS peer check the CLI used before. Every negative case checks
 * the secret (a stand-in reload-password header) never reached the stub.
 *
 * Stubs run in this JVM, so "the server pid" is this JVM's pid; passing
 * another live process's pid makes the OS peer check fail, which is how
 * these tell "proven by the challenge" from "proven by introspection".
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		variables.selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
		variables.token = new cli.lucli.services.ServerChallenge().newSecret();
		variables.secretHeader = {"X-Wheels-Reload-Password": "must-not-leak"};
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function freshModule() {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		makePublic(m, "$recordVerifiedServer");
		return m;
	}

	/** A separate OS process that stays alive: {process, pid}. */
	private struct function otherProcess() {
		var proc = createObject("java", "java.lang.ProcessBuilder").init(["sleep", "60"]).start();
		return {process: proc, pid: proc.pid()};
	}

	/**
	 * Exchange through a verified server served by `stub`, recorded with
	 * `pid` and the start token. Returns {result, type, message}.
	 */
	private struct function exchange(required any stub, required any pid, string host = "127.0.0.1", string useToken = variables.token) {
		var m = freshModule();
		m.$recordVerifiedServer({
			port: arguments.stub.getPort(),
			pid: arguments.pid,
			hosts: [arguments.host],
			token: arguments.useToken,
			challengeRequired: false
		});
		var hostPart = find(":", arguments.host) ? "[" & arguments.host & "]" : arguments.host;
		var state = {result: {}, type: "", message: ""};
		try {
			state.result = m.$httpExchange(
				requestUrl = "http://#hostPart#:#arguments.stub.getPort()#/?reload=true",
				headers = variables.secretHeader
			);
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		return state;
	}

	/** True when any request head the stub received carries the secret. */
	private boolean function secretSent(required any stub) {
		for (var head in arguments.stub.requests()) {
			if (findNoCase("must-not-leak", head)) return true;
		}
		return false;
	}

	function run() {

		describe("connection challenge on the CLI transport (##3769)", () => {

			it("the stub's loopback port can't be shadowed by another 127.0.0.1 bind (##3834)", () => {
				// On macOS/BSD a SO_REUSEADDR socket may bind 127.0.0.1:<port> over a
				// wildcard listener and take its loopback connections, so the peer
				// check rightly answers "not this pid" (the ##3804 family).
				var stub = new cli.lucli.tests.ChallengeStubServer("unavailable", variables.token);
				var shadow = createObject("java", "java.net.ServerSocket").init();
				var state = {bound: false};
				try {
					shadow.setReuseAddress(true);
					try {
						shadow.bind(createObject("java", "java.net.InetSocketAddress").init("127.0.0.1", javacast("int", stub.getPort())));
						state.bound = true;
					} catch (any e) {
					}
					expect(state.bound).toBeFalse("another socket bound 127.0.0.1 on the stub's port");
				} finally {
					try { shadow.close(); } catch (any e) {}
					stub.stop();
				}
			});

			it("a right answer proves the connection without OS introspection", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("valid", variables.token);
				var other = otherProcess();
				try {
					// pid is another process, so the OS peer check alone would refuse.
					var state = exchange(stub, other.pid);
					expect(state.type).toBe("");
					expect(state.result.statusCode).toBe(200);
					var heads = stub.requests();
					expect(arrayLen(heads)).toBe(2);
					expect(heads[1]).toInclude("command=cliChallenge");
					expect(findNoCase("must-not-leak", heads[1])).toBe(0, "the challenge carried the secret");
					expect(heads[2]).toInclude("must-not-leak");
					expect(stub.connectionCount()).toBe(1, "the request did not follow on the proven connection");
				} finally {
					other.process.destroy();
					stub.stop();
				}
			});

			it("accepts the framework's uppercase-hex MAC", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("upper", variables.token);
				var other = otherProcess();
				try {
					var state = exchange(stub, other.pid);
					expect(state.type).toBe("");
					expect(state.result.statusCode).toBe(200);
				} finally {
					other.process.destroy();
					stub.stop();
				}
			});

			it("a wrong answer fails closed, even where the OS peer check would pass", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("wrong", variables.token);
				try {
					var state = exchange(stub, variables.selfPid);
					expect(state.type).toBe("Wheels.ServerNotOwned");
					expect(state.message).toInclude("wrong proof");
					expect(arrayLen(stub.requests())).toBe(1);
					expect(secretSent(stub)).toBeFalse();
				} finally {
					stub.stop();
				}
			});

			it("rejects a relay: the right token over another connection's tuple", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("relay", variables.token);
				try {
					var state = exchange(stub, variables.selfPid);
					expect(state.type).toBe("Wheels.ServerNotOwned");
					expect(state.message).toInclude("wrong proof");
					expect(secretSent(stub)).toBeFalse();
				} finally {
					stub.stop();
				}
			});

			it("'unavailable' falls back to the OS peer check, which passes for the server's own pid", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("unavailable", variables.token);
				try {
					var state = exchange(stub, variables.selfPid);
					expect(state.type).toBe("");
					expect(state.result.statusCode).toBe(200);
					expect(stub.connectionCount()).toBe(1);
				} finally {
					stub.stop();
				}
			});

			it("'unavailable' gains a squatter nothing: the OS peer check still refuses it", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("unavailable", variables.token);
				var other = otherProcess();
				try {
					var state = exchange(stub, other.pid);
					expect(state.type).toBe("Wheels.ServerNotOwned");
					expect(state.message).toInclude("sent nothing");
					expect(arrayLen(stub.requests())).toBe(1, "anything beyond the challenge was sent");
					expect(secretSent(stub)).toBeFalse();
				} finally {
					other.process.destroy();
					stub.stop();
				}
			});

			it("an older framework (no challenge, connection closed) is proven the old way on a fresh connection", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("close", variables.token);
				try {
					var state = exchange(stub, variables.selfPid);
					expect(state.type).toBe("");
					expect(state.result.statusCode).toBe(200);
					expect(stub.connectionCount()).toBe(2);
					var heads = stub.requests();
					expect(heads[1]).toInclude("command=cliChallenge");
					expect(findNoCase("cliChallenge", heads[2])).toBe(0, "challenged again on the retry");
				} finally {
					stub.stop();
				}
			});

			it("an older framework behind a squatter's pid is still refused", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("close", variables.token);
				var other = otherProcess();
				try {
					var state = exchange(stub, other.pid);
					expect(state.type).toBe("Wheels.ServerNotOwned");
					expect(secretSent(stub)).toBeFalse();
				} finally {
					other.process.destroy();
					stub.stop();
				}
			});

			it("without a token there is no challenge: the OS peer check runs as before", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("valid", variables.token);
				try {
					var state = exchange(stub, variables.selfPid, "127.0.0.1", "");
					expect(state.result.statusCode).toBe(200);
					var heads = stub.requests();
					expect(arrayLen(heads)).toBe(1);
					expect(findNoCase("cliChallenge", heads[1])).toBe(0);
				} finally {
					stub.stop();
				}
			});

			it("proves an IPv6 loopback connection (the tuple is compared as raw bytes)", () => {
				var stub = "";
				try {
					stub = new cli.lucli.tests.ChallengeStubServer("valid", variables.token, "::1");
				} catch (any e) {
					debug("No IPv6 loopback here; skipping");
					return;
				}
				var other = otherProcess();
				try {
					var state = exchange(stub, other.pid, "::1");
					expect(state.type).toBe("");
					expect(state.result.statusCode).toBe(200);
				} finally {
					other.process.destroy();
					stub.stop();
				}
			});

			it("a server the OS can't see (challengeRequired) that can't answer is refused", () => {
				var stub = new cli.lucli.tests.ChallengeStubServer("unavailable", variables.token);
				var other = otherProcess();
				try {
					var m = freshModule();
					m.$recordVerifiedServer({
						port: stub.getPort(),
						pid: other.pid,
						hosts: ["127.0.0.1"],
						token: variables.token,
						challengeRequired: true
					});
					var state = {type: ""};
					try {
						m.$httpExchange(requestUrl = "http://127.0.0.1:#stub.getPort()#/", headers = variables.secretHeader);
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("Wheels.ServerNotOwned");
					expect(secretSent(stub)).toBeFalse();
				} finally {
					other.process.destroy();
					stub.stop();
				}
			});

		});

	}

}
