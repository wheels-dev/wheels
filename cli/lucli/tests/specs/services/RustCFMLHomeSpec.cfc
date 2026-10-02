/**
 * The RustCFML engine keeps its binaries and per-project state under the LuCLI
 * home. Under a launcher that passes -Dlucli.home, it read only $LUCLI_HOME and
 * fell back to ~/.wheels, so `wheels engines rustcfml status` looked in the
 * wrong tree and reported no server while one was up (#3913). The system
 * property outranks the env var, as in Module.$resolveLucliHome() (#3733).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("RustCFMLEngine home resolution", () => {
			beforeEach(() => {
				variables.sys = createObject("java", "java.lang.System");
				var prior = sys.getProperty("lucli.home");
				variables.priorHome = isNull(prior) ? {set = false} : {set = true, value = prior};
				variables.isolatedHome = getTempDirectory() & "rust-home-" & createUUID();
			});

			afterEach(() => {
				if (priorHome.set) {
					sys.setProperty("lucli.home", priorHome.value);
				} else {
					sys.clearProperty("lucli.home");
				}
			});

			it("keeps state under -Dlucli.home when the property is set", () => {
				sys.setProperty("lucli.home", isolatedHome);
				var engine = new cli.lucli.services.rustcfml.RustCFMLEngine();
				expect(engine.$statePath("/tmp/some-project")).toInclude(isolatedHome & "/rustcfml/servers/");
			});
		});
	}

}
