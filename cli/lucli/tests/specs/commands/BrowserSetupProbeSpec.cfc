/**
 * `wheels browser setup` launches the browser once before it reports ready.
 * Downloading the binaries doesn't prove they run: on a bare Linux host the
 * browser can be missing OS libraries, and setup used to say "ready" anyway.
 *
 * The probe's decisions are driven through ModuleBrowserProbe (a stubbed
 * process result); the process runner itself is checked with real commands.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.mod = new cli.lucli.Module(cwd = getTempDirectory());
		variables.posix = !findNoCase("windows", createObject("java", "java.lang.System").getProperty("os.name"));
	}

	private any function probeModule() {
		return new cli.lucli.tests._fixtures.commands.ModuleBrowserProbe(cwd = getTempDirectory());
	}

	function run() {

		describe("wheels browser setup: finishing after the install", () => {

			it("throws BrowserSetupFailed, prints the remedy and never says ready when the launch fails", () => {
				var m = probeModule();
				m.setProcessResult(exitCode = 1, output = "Host system is missing dependencies to run browsers.");
				expect(() => m.$browserFinishSetup("a.jar:b.jar", "chromium")).toThrow(type = "Wheels.BrowserSetupFailed");
				var printed = m.capturedOutput();
				expect(printed).toInclude("Browser launch FAILED");
				expect(printed).toInclude("install-deps chromium");
				expect(printed).notToInclude("Browser testing ready.");
			});

			it("says ready when the launch works", () => {
				var m = probeModule();
				m.setProcessResult(exitCode = 0, writeShot = true);
				m.$browserFinishSetup("a.jar", "chromium");
				expect(m.capturedOutput()).toInclude("Browser launch OK");
				expect(m.capturedOutput()).toInclude("Browser testing ready.");
			});
		});

		describe("wheels browser setup: the launch probe", () => {

			it("is not ready after a timeout, even when a screenshot was written first, and removes it", () => {
				var m = probeModule();
				m.setProcessResult(exitCode = -1, timedOut = true, writeShot = true);
				var probe = m.$browserLaunchProbe("a.jar", "chromium", 5);
				expect(probe.ok).toBeFalse();
				expect(probe.timedOut).toBeTrue();
				expect(fileExists(m.lastShot())).toBeFalse();
				expect(() => m.$browserFinishSetup("a.jar", "chromium")).toThrow(type = "Wheels.BrowserSetupFailed");
				expect(m.capturedOutput()).toInclude("didn't finish starting within");
			});

			it("is not ready when the run exits 0 without a screenshot", () => {
				var m = probeModule();
				m.setProcessResult(exitCode = 0, writeShot = false);
				expect(m.$browserLaunchProbe("a.jar", "chromium").ok).toBeFalse();
			});

			it("is not ready on a non-zero exit, and removes the screenshot", () => {
				var m = probeModule();
				m.setProcessResult(exitCode = 1, writeShot = true);
				expect(m.$browserLaunchProbe("a.jar", "chromium").ok).toBeFalse();
				expect(fileExists(m.lastShot())).toBeFalse();
			});

			it("is ready on exit 0 with a screenshot, and removes it", () => {
				var m = probeModule();
				m.setProcessResult(exitCode = 0, writeShot = true);
				expect(m.$browserLaunchProbe("a.jar", "chromium").ok).toBeTrue();
				expect(fileExists(m.lastShot())).toBeFalse();
			});
		});

		describe("wheels browser setup: the process runner", () => {

			it("kills a process tree that outlives the timeout", () => {
				if (!posix) skip("POSIX shell and sleep only");
				// A per-run duration makes the child's command line unique, so
				// the pgrep below can only find this test's process.
				var marker = "41." & randRange(100000, 999999);
				var started = getTickCount();
				var run = mod.$browserRunProcess(["sh", "-c", "sleep #marker#; echo done"], 1);
				expect(run.timedOut).toBeTrue();
				expect(getTickCount() - started).toBeLT(15000);
				expect(run.output).notToInclude("done");
				// The shell's child is gone too.
				expect(mod.$browserRunProcess(["pgrep", "-f", "sleep #marker#"], 5).exitCode).toBe(1);
			});

			it("returns the exit code and stdout and stderr together", () => {
				if (!posix) skip("POSIX shell only");
				var run = mod.$browserRunProcess(["sh", "-c", "echo out; echo err 1>&2; exit 3"], 10);
				expect(run.timedOut).toBeFalse();
				expect(run.exitCode).toBe(3);
				expect(run.output).toInclude("out");
				expect(run.output).toInclude("err");
			});

			it("passes an argument with spaces as one argument", () => {
				if (!posix) skip("POSIX printf only");
				expect(mod.$browserRunProcess(["printf", "%s", "a path/with spaces.png"], 10).output).toBe("a path/with spaces.png");
			});
		});

		describe("wheels browser setup: the classpath", () => {

			it("joins the jars with the platform's path separator", () => {
				var sep = createObject("java", "java.io.File").pathSeparator;
				var cp = mod.$browserClasspath("/b", {classpath: [{filename: "one.jar"}, {filename: "two.jar"}]});
				expect(cp).toBe("/b/lib/one.jar" & sep & "/b/lib/two.jar");
			});
		});

		describe("wheels browser setup: the remedy", () => {

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
