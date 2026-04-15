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
}
