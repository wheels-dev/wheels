/**
 * `wheels browser setup` launches the browser once before it reports ready.
 * Downloading the binaries doesn't prove they run: on a bare Linux host the
 * browser can be missing OS libraries, and setup used to say "ready" anyway.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.mod = new cli.lucli.Module(cwd = getTempDirectory());
		variables.source = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {

		describe("wheels browser setup launch probe", () => {

			it("only reports ready after the launch probe passes", () => {
				var probeAt = find("$browserLaunchProbe(classpath, browserName)", source);
				var readyAt = find("Browser testing ready.", source);
				expect(probeAt).toBeGT(0);
				expect(readyAt).toBeGT(probeAt);
			});

			it("prints Playwright's install-deps command when host libraries are missing", () => {
				var output = "Host system is missing dependencies to run browsers. Please install them with the following command: sudo npx playwright install-deps";
				var remedy = mod.$browserLaunchRemedy(output, "/home/u/.wheels/browser/lib/a.jar:/home/u/.wheels/browser/lib/b.jar", "chromium");
				expect(remedy).toInclude("missing libraries");
				expect(remedy).toInclude('sudo java -cp "/home/u/.wheels/browser/lib/a.jar:/home/u/.wheels/browser/lib/b.jar" com.microsoft.playwright.CLI install-deps chromium');
				expect(remedy).toInclude("wheels browser setup again");
			});

			it("points at the output and --force for any other failure", () => {
				var remedy = mod.$browserLaunchRemedy("Executable doesn't exist at /x/chrome", "a.jar", "chromium");
				expect(remedy).toInclude("didn't start");
				expect(remedy).toInclude("wheels browser setup --force");
				expect(remedy).notToInclude("install-deps");
			});
		});
	}
}
