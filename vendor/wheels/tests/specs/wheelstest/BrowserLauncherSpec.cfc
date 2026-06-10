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
                    debug("Skipping: Playwright JARs not installed. Run `wheels browser setup`");
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

            it("acquireBrowser() evicts a dead cached Browser and relaunches", () => {
                // A mid-run browser crash must not poison the cache for the
                // application lifetime. Simulate the crash by closing the
                // browser out-of-band (bypassing release()).
                var l = new wheels.wheelstest.BrowserLauncher();
                var paths = l.$classpathJarPaths(installDir=l.resolveInstallDir());
                for (var p in paths) {
                    if (!fileExists(p)) return;
                }
                l.$loadJars(jarPaths=paths);
                try {
                    var b1 = l.acquireBrowser(engine="chromium");
                    b1.close();
                    expect(b1.isConnected()).toBeFalse();
                    var b2 = l.acquireBrowser(engine="chromium");
                    expect(b2.isConnected()).toBeTrue();
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

        describe("$findSetter", () => {

            it("finds a one-arg setter by name on a JDK class", () => {
                // java.util.Date has setTime(long) — one-arg setter
                var klass = createObject("java", "java.util.Date").getClass();
                var method = launcher.$findSetter(klass=klass, name="setTime");
                expect(method.getName()).toBe("setTime");
                expect(arrayLen(method.getParameterTypes())).toBe(1);
            });

            it("throws BrowserOptionError for nonexistent setter", () => {
                var klass = createObject("java", "java.util.Date").getClass();
                expect(() => {
                    launcher.$findSetter(klass=klass, name="setNonexistent");
                }).toThrow("Wheels.BrowserOptionError");
            });

        });

        describe("$castForParam", () => {

            it("casts numeric to java.lang.Double for double param type", () => {
                var paramType = createObject("java", "java.lang.Double").TYPE;
                var result = launcher.$castForParam(value=5000, paramType=paramType);
                expect(result.getClass().getName()).toBe("java.lang.Double");
            });

            it("casts numeric to java.lang.Integer for int param type", () => {
                var paramType = createObject("java", "java.lang.Integer").TYPE;
                var result = launcher.$castForParam(value=42, paramType=paramType);
                expect(result.getClass().getName()).toBe("java.lang.Integer");
            });

            it("passes Java objects through unchanged", () => {
                var obj = createObject("java", "java.util.Date").init();
                var paramType = createObject("java", "java.util.Date").getClass();
                var result = launcher.$castForParam(value=obj, paramType=paramType);
                expect(result).toBe(obj);
            });

        });

        describe("$buildOption", () => {
            var skipOptionTests = false;
            var optLauncher = "";

            beforeEach(() => {
                optLauncher = new wheels.wheelstest.BrowserLauncher();
                var paths = optLauncher.$classpathJarPaths(installDir=optLauncher.resolveInstallDir());
                for (var p in paths) {
                    if (!fileExists(p)) {
                        skipOptionTests = true;
                        return;
                    }
                }
                optLauncher.$loadJars(jarPaths=paths);
            });

            afterEach(() => {
                if (isObject(optLauncher) && optLauncher.getState() == "ready") {
                    optLauncher.release();
                }
            });

            it("throws BrowserOptionError when classloader not initialized", () => {
                var freshLauncher = new wheels.wheelstest.BrowserLauncher();
                expect(() => {
                    freshLauncher.$buildOption(className="java.util.Date");
                }).toThrow("Wheels.BrowserOptionError");
            });

            it("builds a zero-arg Playwright option with setters", () => {
                if (skipOptionTests) return;
                var opts = optLauncher.$buildOption(
                    className="com.microsoft.playwright.Locator$WaitForOptions",
                    setterMap={setTimeout: 5000}
                );
                expect(isObject(opts)).toBeTrue();
            });

            it("builds an option with constructor args", () => {
                if (skipOptionTests) return;
                var viewport = optLauncher.$buildOption(
                    className="com.microsoft.playwright.options.ViewportSize",
                    constructorArgs=[375, 667]
                );
                expect(isObject(viewport)).toBeTrue();
                expect(viewport.width).toBe(375);
                expect(viewport.height).toBe(667);
            });

            it("verifies setter side-effect is observable via public field", () => {
                if (skipOptionTests) return;
                var opts = optLauncher.$buildOption(
                    className="com.microsoft.playwright.Locator$WaitForOptions",
                    setterMap={setTimeout: 5000}
                );
                expect(isObject(opts)).toBeTrue();
                expect(opts.timeout).toBe(5000);
            });

            it("passes nested Java objects through setters", () => {
                if (skipOptionTests) return;
                var viewport = optLauncher.$buildOption(
                    className="com.microsoft.playwright.options.ViewportSize",
                    constructorArgs=[375, 667]
                );
                var contextOpts = optLauncher.$buildOption(
                    className="com.microsoft.playwright.Browser$NewContextOptions",
                    setterMap={setViewportSize: viewport}
                );
                expect(isObject(contextOpts)).toBeTrue();
            });

        });
    }
}
