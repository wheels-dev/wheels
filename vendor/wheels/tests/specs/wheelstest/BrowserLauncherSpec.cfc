component extends="wheels.WheelsTest" {

    function beforeAll() {
        variables.launcher = new wheels.wheelstest.BrowserLauncher();
    }

    function run() {
        describe("BrowserLauncher path discovery", () => {

            it("resolveInstallDir() returns WHEELS_BROWSER_HOME env var when set", () => {
                var stubbed = variables.launcher.$resolveInstallDir(
                    envVar="/tmp/custom-browser-home",
                    homeDir="/Users/someone"
                );
                expect(stubbed).toBe("/tmp/custom-browser-home");
            });

            it("resolveInstallDir() falls back to ~/.wheels/browser when env var empty", () => {
                var resolved = variables.launcher.$resolveInstallDir(
                    envVar="",
                    homeDir="/Users/someone"
                );
                expect(resolved).toBe("/Users/someone/.wheels/browser");
            });

            it("resolveInstallDir() handles home dir with trailing slash", () => {
                var resolved = variables.launcher.$resolveInstallDir(
                    envVar="",
                    homeDir="/Users/someone/"
                );
                expect(resolved).toBe("/Users/someone/.wheels/browser");
            });

            it("jarPath() returns installDir + /lib/playwright-VERSION.jar", () => {
                var p = variables.launcher.$jarPath(
                    installDir="/tmp/browser",
                    version="1.45.0"
                );
                expect(p).toBe("/tmp/browser/lib/playwright-1.45.0.jar");
            });

            it("verifyInstall() throws when JAR missing", () => {
                expect(() => {
                    variables.launcher.$verifyInstall(jarPath="/does/not/exist.jar");
                }).toThrow(type="Wheels.BrowserNotInstalled");
            });

            it("verifyInstall() returns true when JAR exists", () => {
                var tmpJar = getTempDirectory() & "dummy-" & createUUID() & ".jar";
                fileWrite(tmpJar, "");
                try {
                    expect(variables.launcher.$verifyInstall(jarPath=tmpJar)).toBeTrue();
                } finally {
                    fileDelete(tmpJar);
                }
            });

            it("classpathJarPaths() returns one path per manifest classpath entry", () => {
                var paths = variables.launcher.$classpathJarPaths(installDir="/tmp/browser");
                var expectedCount = arrayLen(variables.launcher.getManifest().classpath);
                expect(arrayLen(paths)).toBe(expectedCount);
                for (var p in paths) {
                    expect(p).toInclude("/tmp/browser/lib/");
                    expect(p).toEndWith(".jar");
                }
            });

            it("acquireBrowser() throws BrowserLauncherNotReady before $loadJars()", () => {
                var l = new wheels.wheelstest.BrowserLauncher();
                expect(() => {
                    l.acquireBrowser(engine="chromium");
                }).toThrow(type="Wheels.BrowserLauncherNotReady");
            });

            it("$loadJars() transitions state uninitialized -> ready -> shut-down", () => {
                // Integration: requires Playwright install (~/.wheels/browser/lib/)
                var l = new wheels.wheelstest.BrowserLauncher();
                var paths = l.$classpathJarPaths(installDir=l.resolveInstallDir());
                var allPresent = true;
                for (var p in paths) {
                    if (!fileExists(p)) {
                        allPresent = false;
                        break;
                    }
                }
                if (!allPresent) {
                    debug("Skipping: Playwright JARs not installed. Run tools/install-playwright.sh");
                    return;
                }
                expect(l.getState()).toBe("uninitialized");
                l.$loadJars(jarPaths=paths);
                expect(l.getState()).toBe("ready");
                l.release();
                expect(l.getState()).toBe("shut-down");
            });

            it("resolves com.microsoft.playwright.Playwright class through the URLClassLoader", () => {
                // Integration: requires Playwright install
                var l = new wheels.wheelstest.BrowserLauncher();
                var paths = l.$classpathJarPaths(installDir=l.resolveInstallDir());
                for (var p in paths) {
                    if (!fileExists(p)) return;
                }
                l.$loadJars(jarPaths=paths);
                var klass = l.getClassLoader().loadClass("com.microsoft.playwright.Playwright");
                expect(klass).notToBeNull();
                expect(klass.getName()).toBe("com.microsoft.playwright.Playwright");
                l.release();
            });

            it("acquireBrowser('chromium') launches a real headless browser", () => {
                // Full end-to-end integration. Slow (~2-3s): starts a node driver
                // process and a Chromium instance.
                var l = new wheels.wheelstest.BrowserLauncher();
                var paths = l.$classpathJarPaths(installDir=l.resolveInstallDir());
                for (var p in paths) {
                    if (!fileExists(p)) return;
                }
                l.$loadJars(jarPaths=paths);
                try {
                    var browser = l.acquireBrowser(engine="chromium");
                    expect(browser).notToBeNull();
                    expect(isObject(browser)).toBeTrue();
                    // Smoke: the Browser should report it's connected
                    expect(browser.isConnected()).toBeTrue();
                } finally {
                    l.release();
                }
            });

            it("acquireBrowser() returns the same Browser across calls (singleton per engine)", () => {
                var l = new wheels.wheelstest.BrowserLauncher();
                var paths = l.$classpathJarPaths(installDir=l.resolveInstallDir());
                for (var p in paths) {
                    if (!fileExists(p)) return;
                }
                l.$loadJars(jarPaths=paths);
                try {
                    var b1 = l.acquireBrowser(engine="chromium");
                    var b2 = l.acquireBrowser(engine="chromium");
                    expect(b1).toBe(b2);
                } finally {
                    l.release();
                }
            });

            it("$loadJars() is idempotent — second call after ready stays ready", () => {
                var l = new wheels.wheelstest.BrowserLauncher();
                var paths = l.$classpathJarPaths(installDir=l.resolveInstallDir());
                for (var p in paths) {
                    if (!fileExists(p)) return;
                }
                l.$loadJars(jarPaths=paths);
                expect(l.getState()).toBe("ready");
                l.$loadJars(jarPaths=paths);  // should be no-op
                expect(l.getState()).toBe("ready");
                l.release();
            });

            it("acquireBrowser() throws BrowserLauncherNotReady after release()", () => {
                var l = new wheels.wheelstest.BrowserLauncher();
                var paths = l.$classpathJarPaths(installDir=l.resolveInstallDir());
                for (var p in paths) {
                    if (!fileExists(p)) return;
                }
                l.$loadJars(jarPaths=paths);
                l.release();
                expect(l.getState()).toBe("shut-down");
                expect(() => l.acquireBrowser(engine="chromium"))
                    .toThrow(type="Wheels.BrowserLauncherNotReady");
            });

            it("acquireBrowser() throws BrowserEngineInvalid for unknown engine", () => {
                var l = new wheels.wheelstest.BrowserLauncher();
                var paths = l.$classpathJarPaths(installDir=l.resolveInstallDir());
                for (var p in paths) {
                    if (!fileExists(p)) return;
                }
                l.$loadJars(jarPaths=paths);
                try {
                    expect(() => l.acquireBrowser(engine="opera"))
                        .toThrow(type="Wheels.BrowserEngineInvalid");
                } finally {
                    l.release();
                }
            });

            it("$findZeroArgMethod throws BrowserLauncherReflectionError when method missing", () => {
                // Pure reflection helper — testable on any Java class without
                // needing Playwright JARs loaded. Use String which has no
                // 'thisDoesNotExist' method.
                var l = new wheels.wheelstest.BrowserLauncher();
                var stringClass = createObject("java", "java.lang.String").getClass();
                expect(() => l.$findZeroArgMethod(klass=stringClass, name="thisDoesNotExistOnString"))
                    .toThrow(type="Wheels.BrowserLauncherReflectionError");
            });
        });
    }
}
