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

        // PARENT = PlatformClassLoader (not SystemClassLoader / TCCL).
        // If AppClassLoader is the parent, URLClassLoader fails to resolve
        // cross-JAR superclass references (e.g. driver-bundle's DriverJar extends
        // driver.jar's Driver) with a NoClassDefFoundError at defineClass time.
        // PlatformClassLoader only exposes the JDK stdlib, so our JARs form a
        // clean self-contained layer.
        var parentLoader = createObject("java", "java.lang.ClassLoader")
            .getPlatformClassLoader();
        var classLoader = createObject("java", "java.net.URLClassLoader")
            .init(urls, parentLoader);

        variables.$classLoader = classLoader;
        variables.$state = "ready";
    }

    /**
     * Swap the current thread's context classloader to our URLClassLoader,
     * returning the previous one. Callers MUST restore via $restoreTCCL in a
     * finally block so we don't leak our classloader to unrelated threads.
     *
     * Playwright uses `Thread.currentThread().getContextClassLoader()` inside
     * `DriverJar.getDriverResourceURI()` to locate `driver/<platform>/` resources
     * in the driver-bundle JAR. Default TCCL is the AppClassLoader — which
     * doesn't have our JARs — so the lookup returns null and Playwright's init
     * fails with an NPE. Swap TCCL for the duration of any call that reaches
     * into Playwright's runtime code.
     */
    private any function $pushTCCL() {
        var thread = createObject("java", "java.lang.Thread").currentThread();
        var previous = thread.getContextClassLoader();
        thread.setContextClassLoader(variables.$classLoader);
        return previous;
    }

    private void function $popTCCL(required any previousLoader) {
        createObject("java", "java.lang.Thread").currentThread()
            .setContextClassLoader(arguments.previousLoader);
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

        // Swap TCCL to our URLClassLoader for the duration of Playwright calls —
        // Playwright's DriverJar uses TCCL to find bundled driver resources, and
        // default TCCL (AppClassLoader) doesn't have driver-bundle.jar.
        var previousTCCL = $pushTCCL();
        var browser = "";
        try {
            if (!isObject(variables.$playwright)) {
                // Playwright.create() via reflection: Lucee's varargs bridge can't
                // pass an empty Class<?>[] to getMethod(String, Class<?>...) cleanly,
                // so locate the zero-arg overload by iterating getMethods().
                var playwrightClass = variables.$classLoader.loadClass("com.microsoft.playwright.Playwright");
                var createMethod = $findZeroArgMethod(klass=playwrightClass, name="create");
                variables.$playwright = createMethod.invoke(javaCast("null", ""), javaCast("Object[]", []));
            }

            var browserType = $getBrowserType(engine=arguments.engine);
            // LaunchOptions via reflection through URLClassLoader is fragile;
            // zero-arg launch() defaults to headless=true, which is what we want.
            var launchMethod = $findZeroArgMethod(klass=browserType.getClass(), name="launch");
            browser = launchMethod.invoke(browserType, javaCast("Object[]", []));
        } catch (any e) {
            $popTCCL(previousLoader=previousTCCL);
            // Re-throw errors that are already Wheels-typed (e.g.,
            // BrowserEngineInvalid from $getBrowserType, ReflectionError
            // from $findZeroArgMethod). Only wrap unknown/Java errors.
            if (findNoCase("Wheels.", e.type ?: "")) {
                rethrow;
            }
            // Most likely cause: Chromium binary missing/corrupt under
            // ~/Library/Caches/ms-playwright/. The reflection layer surfaces
            // this as InvocationTargetException wrapping a PlaywrightException;
            // strip the wrapper so callers see something actionable.
            var rootCause = e.message;
            try {
                if (structKeyExists(e, "cause") && isObject(e.cause)) {
                    rootCause = e.cause.getMessage();
                }
            } catch (any inner) {
                // best-effort: if cause unwrapping itself fails, fall back to
                // e.message above. Don't mask the original error.
            }
            throw(
                type="Wheels.BrowserLaunchFailed",
                message="Failed to launch " & arguments.engine & ": " & rootCause
                    & ". If Playwright is not installed, run: bash tools/install-playwright.sh",
                detail=e.detail ?: ""
            );
        }
        $popTCCL(previousLoader=previousTCCL);

        variables.$browsers[arguments.engine] = browser;
        return browser;
    }

    /**
     * Finds the zero-argument method with the given name on the given class.
     * Workaround for Lucee's Java-varargs bridge which can't reliably express
     * an empty `Class<?>[]` to `Class.getMethod(String, Class<?>...)`.
     *
     * Public (with $ prefix indicating "internal but accessible") so callers
     * needing reflection access through our URLClassLoader — and tests of
     * the reflection error path — can use it directly.
     */
    public any function $findZeroArgMethod(required any klass, required string name) {
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

    /**
     * Finds a one-argument method with the given name on the given class.
     * Used to locate fluent setters on Playwright option objects.
     */
    public any function $findSetter(required any klass, required string name) {
        var methods = arguments.klass.getMethods();
        for (var i = 1; i <= arrayLen(methods); i++) {
            if (
                methods[i].getName() == arguments.name
                && arrayLen(methods[i].getParameterTypes()) == 1
            ) {
                return methods[i];
            }
        }
        throw(
            type="Wheels.BrowserOptionError",
            message="No one-arg method named '" & arguments.name
                & "' on class " & arguments.klass.getName()
        );
    }

    /**
     * Cast a CFML value to the Java type expected by a method parameter.
     * Reads the parameter's declared type and applies the appropriate javaCast.
     * Java objects (e.g., nested option objects from $buildOption) pass through.
     */
    public any function $castForParam(required any value, required any paramType) {
        var typeName = arguments.paramType.getName();
        switch (typeName) {
            case "double":
            case "java.lang.Double":
                return javaCast("double", arguments.value);
            case "int":
            case "java.lang.Integer":
                return javaCast("int", arguments.value);
            case "long":
            case "java.lang.Long":
                return javaCast("long", arguments.value);
            case "boolean":
            case "java.lang.Boolean":
                return javaCast("boolean", arguments.value);
            case "java.lang.String":
                return javaCast("string", arguments.value);
            default:
                return arguments.value;
        }
    }

    /**
     * Construct a Playwright option object via reflection through our URLClassLoader.
     *
     * Lucee's createObject("java", "InnerClass") fails when the class lives in a
     * URLClassLoader — it tries to resolve via OSGi bundles. This helper bypasses
     * that by using loadClass() + reflection directly.
     *
     * @className   Fully-qualified Java class name (use $ for inner classes)
     * @setterMap   Struct of setter-name => value. Values auto-cast to match parameter type.
     * @constructorArgs  Array of constructor arguments. Matched by arity; auto-cast per param type.
     */
    public any function $buildOption(
        required string className,
        struct setterMap = {},
        array constructorArgs = []
    ) {
        if (!structKeyExists(variables, "$classLoader")) {
            throw(
                type="Wheels.BrowserOptionError",
                message="Cannot build option: classloader not initialized. Call $loadJars() first."
            );
        }

        var klass = "";
        try {
            klass = variables.$classLoader.loadClass(arguments.className);
        } catch (any e) {
            throw(
                type="Wheels.BrowserOptionError",
                message="Class not found: " & arguments.className & ". " & e.message
            );
        }

        // Construct instance
        var instance = "";
        if (arrayLen(arguments.constructorArgs)) {
            instance = $constructWithArgs(klass=klass, args=arguments.constructorArgs);
        } else {
            // Lucee's varargs bridge can't call getDeclaredConstructor() with
            // zero args (same issue as getMethod). Find the zero-arg constructor
            // by iterating getDeclaredConstructors().
            instance = $constructZeroArg(klass=klass, className=arguments.className);
        }

        // Apply setters
        for (var setterName in arguments.setterMap) {
            var value = arguments.setterMap[setterName];
            try {
                var setter = $findSetter(klass=klass, name=setterName);
                var paramType = setter.getParameterTypes()[1];
                var castedValue = $castForParam(value=value, paramType=paramType);
                setter.invoke(instance, javaCast("Object[]", [castedValue]));
            } catch (any e) {
                if (findNoCase("Wheels.", e.type ?: "")) rethrow;
                throw(
                    type="Wheels.BrowserOptionError",
                    message="Failed to call " & setterName & " on "
                        & arguments.className & ": " & e.message
                );
            }
        }

        return instance;
    }

    /**
     * Construct an instance using the zero-arg constructor found by iterating
     * getDeclaredConstructors(). Workaround for Lucee's varargs bridge which
     * can't call getDeclaredConstructor() with zero args.
     */
    private any function $constructZeroArg(required any klass, required string className) {
        var constructors = arguments.klass.getDeclaredConstructors();
        for (var i = 1; i <= arrayLen(constructors); i++) {
            if (arrayLen(constructors[i].getParameterTypes()) == 0) {
                try {
                    return constructors[i].newInstance(javaCast("Object[]", []));
                } catch (any e) {
                    throw(
                        type="Wheels.BrowserOptionError",
                        message="Failed to construct " & arguments.className
                            & " with zero-arg constructor: " & e.message
                    );
                }
            }
        }
        throw(
            type="Wheels.BrowserOptionError",
            message="No zero-arg constructor found on " & arguments.className
        );
    }

    /**
     * Construct an instance using a constructor matched by argument count.
     * Tries each constructor with matching arity until one succeeds.
     */
    private any function $constructWithArgs(required any klass, required array args) {
        var constructors = arguments.klass.getDeclaredConstructors();
        var targetArity = arrayLen(arguments.args);
        var lastError = "";

        for (var i = 1; i <= arrayLen(constructors); i++) {
            var paramTypes = constructors[i].getParameterTypes();
            if (arrayLen(paramTypes) != targetArity) continue;

            try {
                var castedArgs = [];
                for (var j = 1; j <= targetArity; j++) {
                    arrayAppend(castedArgs, $castForParam(
                        value=arguments.args[j],
                        paramType=paramTypes[j]
                    ));
                }
                return constructors[i].newInstance(javaCast("Object[]", castedArgs));
            } catch (any e) {
                lastError = e.message;
            }
        }

        throw(
            type="Wheels.BrowserOptionError",
            message="No constructor with " & targetArity & " arg(s) succeeded on "
                & arguments.klass.getName()
                & (len(lastError) ? ". Last error: " & lastError : "")
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
     * Closes all acquired browsers, the Playwright instance, and the
     * URLClassLoader (which holds native file handles on the seven JARs).
     * Call once per test run, not per spec CFC.
     */
    public void function release() {
        for (var engine in variables.$browsers) {
            try {
                variables.$browsers[engine].close();
            } catch (any e) {
                // Best-effort: browser close can fail if the node-driver
                // process already exited (timeout, crash). Safe to swallow —
                // the JVM exit will reap any orphaned handles. Other browsers
                // in this loop should still get a chance to close.
            }
        }
        variables.$browsers = {};

        if (isObject(variables.$playwright)) {
            try {
                variables.$playwright.close();
            } catch (any e) {
                // Best-effort: same rationale as the per-browser close above.
                // Continuing on to URLClassLoader release.
            }
            variables.$playwright = "";
        }

        // Close the URLClassLoader so its native file handles on the seven
        // pinned JARs are released. Important on Windows (would prevent JAR
        // replacement) and prevents FD exhaustion if release() + new launcher
        // cycles happen in a long-running process.
        if (structKeyExists(variables, "$classLoader")) {
            try {
                variables.$classLoader.close();
            } catch (any e) {
                // Best-effort: close can fail if the loader is already closed
                // (idempotent release()) or if a child class is mid-use. JVM
                // exit cleans up regardless.
            }
            structDelete(variables, "$classLoader");
        }

        variables.$state = "shut-down";
    }
}
