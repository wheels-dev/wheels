/**
 * The connection challenge (#3769) end to end, against the real LuCLI Lucee
 * server these specs run in: its Tomcat keep-alive, its servlet addresses,
 * and the framework's /wheels/cli?command=cliChallenge answer.
 *
 * The spec gives that server a start token in its own catalina.base (as
 * `wheels start` does), then talks to it through the CLI transport with the
 * server recorded under ANOTHER process's pid: only a valid challenge can
 * get a request through. The token is removed afterwards. Skips when the
 * suite is not running inside a LuCLI server registration.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		variables.skipReason = "";
		var base = createObject("java", "java.lang.System").getProperty("catalina.base");
		if (isNull(base) || !len(base) || !fileExists(base & "/server.pid")) {
			variables.skipReason = "Not running inside a LuCLI server registration; skipping";
			return;
		}
		var baseFile = createObject("java", "java.io.File").init(base);
		variables.serverName = baseFile.getName();
		variables.lucliHome = baseFile.getParentFile().getParent();
		variables.registry = new cli.lucli.services.ServerRegistry(lucliHome = variables.lucliHome);
		variables.port = getPageContext().getRequest().getLocalPort();
		variables.hadToken = fileExists(base & "/wheels-cli.token");
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private struct function exchangeAs(required any pid, required string useToken) {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		makePublic(m, "$recordVerifiedServer");
		m.$recordVerifiedServer({
			port: variables.port,
			pid: arguments.pid,
			hosts: ["127.0.0.1"],
			token: arguments.useToken,
			challengeRequired: false
		});
		var state = {result: {}, type: "", message: ""};
		try {
			// This server is the one running the suite: a short read bounds a
			// stall to 15 s instead of $httpExchange's 120 s default (#4232).
			state.result = m.$httpExchange(requestUrl = "http://127.0.0.1:#variables.port#/wheels/cli?command=routes&format=json", readTimeout = 15000);
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		return state;
	}

	function run() {

		describe("connection challenge against the live server (##3769)", () => {

			it("a started server's token proves the connection; a wrong token is refused", () => {
				if (len(variables.skipReason)) { debug(variables.skipReason); return; }
				if (variables.hadToken) { debug("The server already has a start token; not touching it"); return; }
				var other = createObject("java", "java.lang.ProcessBuilder").init(["sleep", "60"]).start();
				try {
					if (!variables.registry.writeStartToken(variables.serverName)) {
						debug("The registration dir is not private enough for a token here; skipping");
						return;
					}
					var token = variables.registry.readStartToken(variables.serverName);
					expect(len(token)).toBe(64);

					var good = exchangeAs(other.pid(), token);
					expect(good.type).toBe("", good.message);
					expect(good.result.statusCode).toBe(200);

					var bad = exchangeAs(other.pid(), new cli.lucli.services.ServerChallenge().newSecret());
					expect(bad.type).toBe("Wheels.ServerNotOwned");
					expect(bad.message).toInclude("wrong proof");
				} finally {
					variables.registry.deleteStartToken(variables.serverName);
					other.destroy();
				}
			});

			it("without a token file the server answers the generic 'unavailable'", () => {
				if (len(variables.skipReason)) { debug(variables.skipReason); return; }
				if (variables.hadToken) { debug("The server already has a start token; not touching it"); return; }
				var nonce = new cli.lucli.services.ServerChallenge().newSecret();
				var body = testHelper.httpGet("http://127.0.0.1:#variables.port#/wheels/cli?command=cliChallenge&v=1&nonce=#nonce#");
				expect(isJSON(body)).toBeTrue(body);
				var answer = deserializeJSON(body);
				expect(answer.unavailable).toBeTrue();
				expect(structKeyExists(answer, "mac")).toBeFalse();
			});

		});

	}

}
