/**
 * `wheels upgrade check` without --to= looks up the latest GitHub release.
 * When that lookup fails (offline, GitHub rate limit on unauthenticated CI
 * runners) the command used to print a warning and return "", so it exited
 * 0 without scanning anything — a CI gate on Wheels.UpgradeCheckFailed went
 * green and --strict was bypassed. These specs pin the non-zero exit (the
 * throw) in text and JSON mode, and that an explicit --to= skips the lookup.
 *
 * The GitHub call is stubbed by mocking makeHttpRequest on an
 * output-capturing Module, so the specs never touch the network.
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
		m.$("makeHttpRequest").$throws(
			type = "java.net.UnknownHostException",
			message = "api.github.com"
		);
		return m;
	}

	private any function rateLimitedModule() {
		var m = newModule();
		m.$(
			"makeHttpRequest",
			'{"message":"API rate limit exceeded for 203.0.113.7.","documentation_url":"https://docs.github.com/rest"}'
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
				m.$("makeHttpRequest", '{"tag_name":"v3.0.0"}');
				m.upgrade(arg1 = "check");
				expect(m.$count("makeHttpRequest")).toBe(1);
				expect(m.capturedOutput()).toInclude("Target version:  3.0.0");
			});

			it("skips the lookup entirely when --to is given", () => {
				var m = offlineModule();
				m.upgrade(arg1 = "check", to = "3.0.0");
				expect(m.$count("makeHttpRequest")).toBe(0);
				expect(m.capturedOutput()).toInclude("Target version:  3.0.0");
			});

			it("skips the lookup in JSON mode when --to is given", () => {
				var m = offlineModule();
				m.upgrade(arg1 = "check", to = "3.0.0", format = "json");
				expect(m.$count("makeHttpRequest")).toBe(0);
				var doc = lastJsonDocument(m.capturedOutput());
				expect(doc.targetVersion).toBe("3.0.0");
				expect(doc).notToHaveKey("error");
			});

		});

	}

}
