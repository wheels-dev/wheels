/**
 * Process-level singleton that owns the Playwright instance + Browser
 * for browser-driven tests. Not instantiated per-spec; the BrowserTest
 * base class uses the application-scoped instance.
 *
 * Responsibilities (split by stage):
 *   1. JAR path resolution (this task)
 *   2. Playwright lazy init + Browser acquisition (next task)
 *   3. Release/shutdown
 *
 * Not responsible for: DSL, lifecycle hooks, artifact dumping.
 */
component {

    variables.$manifest = "";
    variables.$playwright = "";        // Java Playwright instance (lazy)
    variables.$browsers = {};           // cache: engine => Java Browser instance
    variables.$state = "uninitialized"; // uninitialized | ready | shut-down

    public BrowserLauncher function init() {
        variables.$manifest = $loadManifest();
        return this;
    }

    /**
     * Accessor for the loaded manifest. Preferred over poking `variables.$manifest`
     * from tests/callers since the variables scope isn't externally accessible.
     */
    public struct function getManifest() {
        return variables.$manifest;
    }

    /**
     * Accessor for the URLClassLoader that hosts the Playwright JARs after
     * $loadJars(). Null until $loadJars() runs. Exposed primarily for tests.
     */
    public any function getClassLoader() {
        if (!structKeyExists(variables, "$classLoader")) {
            return javaCast("null", "");
        }
        return variables.$classLoader;
    }

    /**
     * Accessor for the current lifecycle state: "uninitialized" | "ready" | "shut-down".
     */
    public string function getState() {
        return variables.$state;
    }

    /**
     * Reads vendor/wheels/browser-manifest.json.
     */
    public struct function $loadManifest() {
        var manifestPath = expandPath("/wheels/browser-manifest.json");
        if (!fileExists(manifestPath)) {
            throw(
                type="Wheels.BrowserManifestMissing",
                message="Expected vendor/wheels/browser-manifest.json to exist."
            );
        }
        return deserializeJSON(fileRead(manifestPath));
    }

    /**
     * Resolves the install directory based on env var or home dir fallback.
     * Pure function — passed-in args make it unit-testable.
     */
    public string function $resolveInstallDir(
        required string envVar,
        required string homeDir
    ) {
        if (len(trim(arguments.envVar)) > 0) {
            return arguments.envVar;
        }
        var home = arguments.homeDir;
        if (right(home, 1) == "/") {
            home = left(home, len(home) - 1);
        }
        return home & "/.wheels/browser";
    }

    /**
     * Default entry point — reads env var + home dir from the runtime.
     */
    public string function resolveInstallDir() {
        var envVar = "";
        if (
            StructKeyExists(server, "system")
            && StructKeyExists(server.system, "environment")
            && StructKeyExists(server.system.environment, "WHEELS_BROWSER_HOME")
        ) {
            envVar = server.system.environment["WHEELS_BROWSER_HOME"];
        }
        return $resolveInstallDir(envVar=envVar, homeDir=getUserHome());
    }

    public string function $jarPath(
        required string installDir,
        required string version
    ) {
        return arguments.installDir & "/lib/playwright-" & arguments.version & ".jar";
    }

    public boolean function $verifyInstall(required string jarPath) {
        if (!fileExists(arguments.jarPath)) {
            throw(
                type="Wheels.BrowserNotInstalled",
                message="Playwright JAR not found at " & arguments.jarPath
                    & ". Run `wheels browser:install` to set up browser testing."
            );
        }
        return true;
    }

    /**
     * Returns the path to the user's home directory. Override-friendly for tests.
     */
    public string function getUserHome() {
        return createObject("java", "java.lang.System").getProperty("user.home");
    }

    /**
     * Returns an array of filesystem paths — one per entry in the manifest's
     * `classpath` array. Used to build the Playwright runtime classpath
     * (client + driver + driver-bundle + transitive deps = 7 JARs).
     */
    public array function $classpathJarPaths(required string installDir) {
        var paths = [];
        for (var entry in variables.$manifest.classpath) {
            arrayAppend(paths, arguments.installDir & "/lib/" & entry.filename);
        }
        return paths;
    }

    /**
     * Dynamically loads the Playwright runtime JARs into a URLClassLoader so
     * classloader lookups (`loadClass(...)`) can resolve Playwright classes.
     * The servlet's default classpath doesn't include them.
     *
     * Takes an array because Playwright needs seven JARs on the classpath to
     * boot (client + driver + driver-bundle + gson + Java-WebSocket + slf4j).
     * Lucee-specific; Adobe CF support deferred.
     *
     * Must be called before any acquireBrowser() call. Idempotent: subsequent
     * calls after the first are no-ops.
     */
    public void function $loadJars(required array jarPaths) {
        if (variables.$state != "uninitialized") {
            return;
        }

        var urls = [];
        for (var jarPath in arguments.jarPaths) {
            var jarFile = createObject("java", "java.io.File").init(jarPath);
            arrayAppend(urls, jarFile.toURI().toURL());
        }

        var parentLoader = createObject("java", "java.lang.Thread")
            .currentThread()
            .getContextClassLoader();
        var classLoader = createObject("java", "java.net.URLClassLoader")
            .init(urls, parentLoader);

        variables.$classLoader = classLoader;
        variables.$state = "ready";
    }

    /**
     * Returns the Browser for the given engine, creating and caching it on first call.
     *
     * @engine One of: chromium, firefox, webkit
     */
    public any function acquireBrowser(string engine = "chromium") {
        if (variables.$state != "ready") {
            throw(
                type="Wheels.BrowserLauncherNotReady",
                message="Call $loadJars() first. State: " & variables.$state
            );
        }

        if (structKeyExists(variables.$browsers, arguments.engine)) {
            return variables.$browsers[arguments.engine];
        }

        if (!isObject(variables.$playwright)) {
            // Resolve Playwright classes through our URLClassLoader (the servlet's
            // default classpath doesn't include these JARs). We call Playwright.create()
            // via reflection to avoid Lucee's createObject("java", ...) path, which
            // would try to resolve the URLClassLoader as an OSGi bundle.
            //
            // Lucee's CFML-to-Java bridge mishandles getMethod's Class<?>... varargs
            // with no args, so locate the zero-arg create() method by iterating
            // getDeclaredMethods().
            var playwrightClass = variables.$classLoader.loadClass("com.microsoft.playwright.Playwright");
            var createMethod = $findZeroArgMethod(klass=playwrightClass, name="create");
            variables.$playwright = createMethod.invoke(javaCast("null", ""), javaCast("Object[]", []));
        }

        var browserType = $getBrowserType(engine=arguments.engine);
        var launchOptionsClass = variables.$classLoader.loadClass("com.microsoft.playwright.BrowserType$LaunchOptions");
        var launchOptions = launchOptionsClass.getDeclaredConstructor().newInstance();
        launchOptions.setHeadless(javaCast("boolean", true));

        var browser = browserType.launch(launchOptions);
        variables.$browsers[arguments.engine] = browser;
        return browser;
    }

    /**
     * Finds the zero-argument method with the given name on the given class.
     * Workaround for Lucee's Java-varargs bridge which can't reliably express
     * an empty `Class<?>[]` to `Class.getMethod(String, Class<?>...)`.
     */
    private any function $findZeroArgMethod(required any klass, required string name) {
        var methods = arguments.klass.getMethods();
        for (var i = 1; i <= arrayLen(methods); i++) {
            if (methods[i].getName() == arguments.name && arrayLen(methods[i].getParameterTypes()) == 0) {
                return methods[i];
            }
        }
        throw(
            type="Wheels.BrowserLauncherReflectionError",
            message="No zero-arg method named '" & arguments.name & "' on class " & arguments.klass.getName()
        );
    }

    private any function $getBrowserType(required string engine) {
        switch (arguments.engine) {
            case "chromium":
                return variables.$playwright.chromium();
            case "firefox":
                return variables.$playwright.firefox();
            case "webkit":
                return variables.$playwright.webkit();
            default:
                throw(
                    type="Wheels.BrowserEngineInvalid",
                    message="Unknown engine: " & arguments.engine
                        & ". Valid: chromium, firefox, webkit."
                );
        }
    }

    /**
     * Closes all acquired browsers and the Playwright instance. Call once per
     * test run (not per spec CFC).
     */
    public void function release() {
        for (var engine in variables.$browsers) {
            try {
                variables.$browsers[engine].close();
            } catch (any e) {
                // best-effort cleanup
            }
        }
        variables.$browsers = {};

        if (isObject(variables.$playwright)) {
            try {
                variables.$playwright.close();
            } catch (any e) {
            }
            variables.$playwright = "";
        }

        variables.$state = "shut-down";
    }
}
