/**
 * `wheels version` names the LuCLI runtime it runs on. The runtime sets
 * neither the lucli.version system property nor LUCLI_VERSION, so the module
 * also reads lucli/version.properties from the runtime jar on the launcher's
 * classpath. Inside the test server that jar is not on the classpath, so the
 * specs pin the contract (a version string or "", never an error) rather
 * than a value; the channel smoke checks the value on real installs.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("wheels version — LuCLI runtime detection", () => {

			it("reads the runtime version resource without throwing", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				prepareMock(m);
				makePublic(m, "$readLucliVersionResource");
				var v = m.$readLucliVersionResource();
				expect(IsSimpleValue(v)).toBeTrue();
				expect(v == "" || reFind("^\d+\.\d+\.\d+(\.\d+)?$", v) > 0).toBeTrue("unexpected version text: '#v#'");
			});

			it("prints the LuCLI line whenever a runtime version is detected", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				prepareMock(m);
				m.$("$detectLucliVersion", "0.6.2.1");
				var banner = m.version();
				expect(banner).toInclude("LuCLI 0.6.2.1");
				expect(listFirst(banner, chr(10))).toInclude("Wheels ");
			});

		});

	}

}
