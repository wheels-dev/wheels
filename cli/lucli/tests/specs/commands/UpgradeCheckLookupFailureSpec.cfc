/**
 * `wheels upgrade check` without --to= looks up the latest GitHub release.
 * When that lookup fails (offline, GitHub rate limit on unauthenticated CI
 * runners) the command used to print a warning and return "", so it exited
 * 0 without scanning anything — a CI gate on Wheels.UpgradeCheckFailed went
 * green and --strict was bypassed. These specs pin the non-zero exit (the
 * throw) in text and JSON mode, and that an explicit --to= skips the lookup.
 *
 * The GitHub call is stubbed by mocking $latestReleaseResponse on an
 * output-capturing Module, so the specs never touch the network.
 *
 * The lookup must not use makeHttpRequest(): that rides $httpExchange, the
 * raw-socket plain-HTTP transport reserved for the local dev server, which
 * cannot reach https://api.github.com (every lookup failed on 4.1.2-dev).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
	}

	private any function newModule() {
		var m = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
		prepareMock(m);
		return m;
	}

	private any function offlineModule() {
		var m = newModule();
		m.$("$latestReleaseResponse").$throws(
			type = "java.net.UnknownHostException",
			message = "api.github.com"
		);
		return m;
	}

	private any function rateLimitedModule() {
		var m = newModule();
		m.$(
			"$latestReleaseResponse",
			{status: 403, body: '{"message":"API rate limit exceeded for 203.0.113.7.","documentation_url":"https://docs.github.com/rest"}'}
		);
		return m;
	}

	private struct function lastJsonDocument(required string output) {
		var lines = listToArray(arguments.output, chr(10));
		for (var i = arrayLen(lines); i >= 1; i--) {
			if (left(trim(lines[i]), 1) == "{" && isJSON(lines[i])) {
				return deserializeJSON(lines[i]);
			}
		}
		return {};
	}

	function run() {

		describe("wheels upgrade check — latest-release lookup failure", () => {

			beforeEach(() => {
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
			});

			afterEach(() => {
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			it("throws Wheels.UpgradeCheckFailed when offline and no --to is given", () => {
				var m = offlineModule();
				expect(() => m.upgrade(arg1 = "check")).toThrow(type = "Wheels.UpgradeCheckFailed");
				var output = m.capturedOutput();
				expect(output).toInclude("Could not determine the latest Wheels version");
				expect(output).toInclude("--to=<version>");
				// Nothing was scanned: no report headers were printed.
				expect(output).notToInclude("Target version:");
			});

			it("throws when GitHub rate-limits the lookup, naming the reason", () => {
				var m = rateLimitedModule();
				expect(() => m.upgrade(arg1 = "check")).toThrow(
					type = "Wheels.UpgradeCheckFailed",
					regex = "rate limit"
				);
				expect(m.capturedOutput()).toInclude("API rate limit exceeded");
			});

			it("throws under --strict too (strict cannot be bypassed by a failed lookup)", () => {
				var m = offlineModule();
				expect(() => m.upgrade(arg1 = "check", strict = true)).toThrow(type = "Wheels.UpgradeCheckFailed");
			});

			it("JSON mode prints a machine-readable error and still throws", () => {
				var m = offlineModule();
				expect(() => m.upgrade(arg1 = "check", format = "json")).toThrow(type = "Wheels.UpgradeCheckFailed");
				var doc = lastJsonDocument(m.capturedOutput());
				expect(doc).toHaveKey("error");
				expect(doc.error).toInclude("--to=<version>");
				expect(doc).toHaveKey("success");
				expect(doc.success).toBeFalse();
			});

			it("JSON mode with --strict reports strict in the error document and throws", () => {
				var m = rateLimitedModule();
				expect(() => m.upgrade(arg1 = "check", format = "json", strict = true)).toThrow(type = "Wheels.UpgradeCheckFailed");
				var doc = lastJsonDocument(m.capturedOutput());
				expect(doc.success).toBeFalse();
				expect(doc.strict).toBeTrue();
			});

			it("uses the looked-up release when the lookup succeeds", () => {
				var m = newModule();
				m.$("$latestReleaseResponse", {status: 200, body: '{"tag_name":"v3.0.0"}'});
				m.upgrade(arg1 = "check");
				expect(m.$count("$latestReleaseResponse")).toBe(1);
				expect(m.capturedOutput()).toInclude("Target version:  3.0.0");
			});

			it("skips the lookup entirely when --to is given", () => {
				var m = offlineModule();
				m.upgrade(arg1 = "check", to = "3.0.0");
				expect(m.$count("$latestReleaseResponse")).toBe(0);
				expect(m.capturedOutput()).toInclude("Target version:  3.0.0");
			});

			it("never sends the GitHub lookup through the dev-server transport", () => {
				var m = newModule();
				m.$("$latestReleaseResponse", {status: 200, body: '{"tag_name":"v3.0.0"}'});
				m.$("makeHttpRequest").$throws(type = "Spec.WrongTransport", message = "makeHttpRequest must not be used for GitHub");
				m.upgrade(arg1 = "check");
				expect(m.$count("makeHttpRequest")).toBe(0);
				expect(m.capturedOutput()).toInclude("Target version:  3.0.0");
			});

			it("fails with the HTTP status when GitHub answers with an empty body", () => {
				var m = newModule();
				m.$("$latestReleaseResponse", {status: 301, body: ""});
				expect(() => m.upgrade(arg1 = "check")).toThrow(type = "Wheels.UpgradeCheckFailed", regex = "HTTP 301");
			});

			it("reports the HTTP status, not a JSON parse error, for an HTML error page", () => {
				var m = newModule();
				m.$("$latestReleaseResponse", {status: 503, body: "<html><body>Service Unavailable</body></html>"});
				expect(() => m.upgrade(arg1 = "check")).toThrow(type = "Wheels.UpgradeCheckFailed", regex = "HTTP 503");
				var output = m.capturedOutput();
				expect(output).toInclude("HTTP 503");
				expect(output).notToInclude("JSON");
			});

			it("does not accept a tag_name from a non-200 response", () => {
				var m = newModule();
				m.$("$latestReleaseResponse", {status: 500, body: '{"tag_name":"v9.9.9"}'});
				expect(() => m.upgrade(arg1 = "check")).toThrow(type = "Wheels.UpgradeCheckFailed", regex = "HTTP 500");
				expect(m.capturedOutput()).notToInclude("9.9.9");
			});

			it("looks the release up over HTTPS with the cfhttp-based client, not the raw-socket one", () => {
				var source = fileRead(expandPath("/cli/lucli/Module.cfc"));
				var start = find("private struct function $latestReleaseResponse(", source);
				expect(start).toBeGT(0);
				var body = mid(source, start, find(chr(10) & chr(9) & "}", source, start) - start);
				expect(body).toInclude("new services.packages.HttpClient(");
				expect(body).toInclude("https://api.github.com/repos/wheels-dev/wheels/releases/latest");
				expect(body).notToInclude("makeHttpRequest");
				expect(body).notToInclude("$httpExchange");
			});

			it("keeps loopback dev-server calls on $httpExchange", () => {
				var m = newModule();
				m.$("$httpExchange", {statusCode: 200, body: "ok", headers: {}});
				makePublic(m, "makeHttpRequest");
				expect(m.makeHttpRequest("http://127.0.0.1:65530/wheels/cli/status")).toBe("ok");
				expect(m.$count("$httpExchange")).toBe(1);
			});

			it("skips the lookup in JSON mode when --to is given", () => {
				var m = offlineModule();
				m.upgrade(arg1 = "check", to = "3.0.0", format = "json");
				expect(m.$count("$latestReleaseResponse")).toBe(0);
				var doc = lastJsonDocument(m.capturedOutput());
				expect(doc.targetVersion).toBe("3.0.0");
				expect(doc).notToHaveKey("error");
			});

		});

		describe("wheels upgrade check — --offline", () => {

			beforeEach(() => {
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
			});

			afterEach(() => {
				StructDelete(request, "$wheelsOffline");
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			it("refuses the latest-release lookup and steers to --to", () => {
				// Not mocked: the real lookup must stop at the HttpClient gate.
				var m = newModule();
				expect(() => m.upgrade(arg1 = "check", offline = true)).toThrow(type = "Wheels.UpgradeCheckFailed");
				var output = m.capturedOutput();
				expect(output).toInclude("Offline mode is enabled");
				expect(output).toInclude("--to=<version>");
			});

			it("still scans offline when --to is given", () => {
				var m = offlineModule();
				m.upgrade(arg1 = "check", to = "3.0.0", offline = true);
				expect(m.$count("$latestReleaseResponse")).toBe(0);
				expect(m.capturedOutput()).toInclude("Target version:  3.0.0");
			});

			it("resets an offline state left by an earlier call on the reused Module", () => {
				request.$wheelsOffline = true;
				var m = newModule();
				m.$("$latestReleaseResponse", {status: 200, body: '{"tag_name":"v3.0.0"}'});
				m.upgrade(arg1 = "check");
				expect(request.$wheelsOffline).toBeFalse();
			});

		});

	}

}
