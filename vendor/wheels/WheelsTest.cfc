/**
 * Base WheelsTest spec for Wheels tests.
 * Dynamically binds methods from `application.wo` into both
 * the `variables` and `this` scope for convenience.
 *
 * This is the primary base class for BDD-style tests in Wheels.
 * Extends: wheels.Testbox (deprecated) → wheels.WheelsTest (current)
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    // Pseudo-constructor (runs automatically). Kept so specs that EXTEND
    // WheelsTest get their helpers bound during child compilation.
    $bindApplicationHelpers();
    $guardTestRunDataSource();

    /**
     * Refuses to build a spec bundle when this run was meant to use the test
     * datasource but the app's primary datasource is active, e.g. a project
     * tests/runner.cfm that sets the datasource itself. Only acts inside a run
     * started through Public.cfc's project-runner path (which records its
     * datasource decision for the request); a no-op everywhere else.
     */
    public void function $guardTestRunDataSource() {
        // A run that is still building bundles is alive: keep its deadline ahead, so
        // the stranded-run recovery never restores the primary datasource mid-run.
        if (StructKeyExists(application, "$$$appTestRunDeadline") && StructKeyExists(application, "wo")) {
            application.wo.$extendTestRunDeadline(from = Now());
        }
        if (!StructKeyExists(request, "wheels") || !StructKeyExists(request.wheels, "$testDataSourceDecision")) {
            return;
        }
        local.decision = request.wheels.$testDataSourceDecision;
        if (
            local.decision.action == "swap"
            && StructKeyExists(application, "wheels")
            && Compare(application.wheels.dataSourceName, local.decision.primary) == 0
        ) {
            Throw(
                type = "Wheels.TestDatabaseNotAvailable",
                message = "This test run uses the '#local.decision.target#' datasource, but the app's primary datasource '#local.decision.primary#' is active.",
                extendedInfo = "Something in the run set the datasource back to the primary one; a tests/runner.cfm copied from an older Wheels release can do this. Replace it with the runner `wheels new` creates (it includes wheels/tests/app-runner.cfm)."
            );
        }
    }

    /**
     * Bind application.wo's helpers into this instance (both variables and
     * this scope). Runs from the pseudo-constructor above AND from init():
     * RustCFML skips pseudo-constructor code when instantiating an
     * already-compiled component directly (new wheels.WheelsTest()), so
     * init() covers that path. The binding is idempotent, so engines that
     * run both paths are unaffected.
     */
    public any function $bindApplicationHelpers() {
        if (!structKeyExists(application, "wo")) {
            return this;
        }
        // Iterate struct keys on application.wo and bind every UDF. This
        // catches both methods declared on Global.cfc (visible to
        // getMetaData) AND helpers merged in via cfinclude (e.g.
        // app/global/functions.cfm), which getMetaData(application.wo).functions
        // does NOT enumerate — see #2790.
        local.metaIndex = {};
        for (local.fn in getMetaData(application.wo).functions) {
            local.metaIndex[local.fn.name] = local.fn.access;
        }

        for (local.key in application.wo) {
            if (!isCustomFunction(application.wo[local.key])) {
                continue;
            }
            // For methods present in CFC metadata, keep the existing
            // public-only filter; include-injected helpers have no
            // access modifier so they're treated as public.
            if (structKeyExists(local.metaIndex, local.key) && local.metaIndex[local.key] neq "public") {
                continue;
            }
            if (structKeyExists(variables, local.key) || structKeyExists(this, local.key)) {
                continue;
            }
            variables[local.key] = application.wo[local.key];
            this[local.key]      = application.wo[local.key];
        }
        return this;
    }

    /**
     * Constructor — re-runs the helper binding so a directly instantiated
     * WheelsTest works on engines that skip pseudo-constructor code for
     * already-compiled components (RustCFML). Matches BaseSpec's remote
     * access modifier, which Adobe requires of overrides.
     */
    remote WheelsTest function init() {
        $bindApplicationHelpers();
        $guardTestRunDataSource();
        return this;
    }

    /**
     * Create a TestClient and visit the given path (HTTP GET).
     * Returns the TestClient for fluent assertion chaining.
     *
     * Usage in tests:
     *   visit("/users").assertOk().assertSee("John")
     *
     * @path URL path to visit
     */
    public any function visit(required string path) {
        return $testClient().get(arguments.path);
    }

    /**
     * Join a suffix onto the engine's temp directory with the separator
     * normalized. RustCFML's GetTempDirectory() omits the trailing slash
     * (Lucee and Adobe include it), so a bare concatenation produces a path
     * at the filesystem root on Linux — `/tmpwheels-…` instead of
     * `/tmp/wheels-…` — and every file operation fails with a permission
     * error. Use this helper for BOTH construction and cleanup so the
     * RemoveChars/Replace sweeps in specs' finally blocks key on the same
     * normalized form.
     */
    public string function $tempPath(required string suffix) {
        local.tmp = GetTempDirectory();
        if (Right(local.tmp, 1) != "/" && Right(local.tmp, 1) != "\") {
            local.tmp &= "/";
        }
        return local.tmp & arguments.suffix;
    }

    /**
     * MockBox, with its stub directory in place. MockBox writes a generated stub for
     * each mocked method under its generation path (`/testbox/system/stubs` by
     * default, relative to the webroot) and fails when that directory is missing, as
     * it is in an app made with `wheels new`. Every mock helper (createMock,
     * createEmptyMock, createStub, prepareMock, querySim) goes through here.
     *
     * @generationPath Where MockBox writes its stubs; empty keeps the current path.
     */
    public any function getMockBox(string generationPath = "") {
        local.mockBox = super.getMockBox(argumentCollection = arguments);
        $ensureMockStubDirectory(local.mockBox);
        return local.mockBox;
    }

    /**
     * Creates `mockBox`'s stub directory, and any missing parents, when it does not
     * exist. One level at a time with DirectoryCreate(): its create-parents argument
     * is Lucee-only (issue #2567) and java.io.File is not available on every engine.
     *
     * @mockBox A wheels.wheelstest.system.MockBox.
     */
    public void function $ensureMockStubDirectory(required any mockBox) {
        local.dir = ReReplace(ExpandPath(arguments.mockBox.getGenerationPath()), "[/\\]+$", "");
        local.missing = [];
        while (Len(local.dir) && !DirectoryExists(local.dir)) {
            ArrayPrepend(local.missing, local.dir);
            local.parent = ReReplace(GetDirectoryFromPath(local.dir), "[/\\]+$", "");
            if (local.parent == local.dir) {
                break;
            }
            local.dir = local.parent;
        }
        for (local.path in local.missing) {
            try {
                DirectoryCreate(local.path);
            } catch (any e) {
                // Another request may have created it meanwhile.
                if (!DirectoryExists(local.path)) {
                    rethrow;
                }
            }
        }
    }

    /**
     * Delete a directory and everything in it, symlink-safe.
     *
     * `DirectoryDelete(path, recurse=true)` leaves the directory behind on
     * Adobe CF 2023 when the tree contains a symlink — it throws "The specified
     * directory ... cannot be deleted. This directory is not empty." — which
     * errored the symlink-fixture specs (S4 and the mappings-escape spec in
     * `hardener/PluginsHardenerShouldSpec.cfc`) on every adobe2023 matrix leg
     * and cascaded into the specs that share the same fixture root.
     *
     * Walk the tree first and unlink symlinks with `java.nio.file.Files`, which
     * removes the link itself instead of following it, then hand the now
     * link-free tree to the plain recursive delete. On a JVM-free engine
     * (RustCFML, which never builds symlink fixtures) the walk is a no-op and
     * the recursive delete runs unchanged.
     *
     * @path Directory to remove. A path that does not exist is a no-op.
     */
    public void function $removeTree(required string path) {
        if (!DirectoryExists(arguments.path)) {
            return;
        }
        try {
            $unlinkSymlinks(arguments.path);
        } catch (any e) {
            // No JVM (RustCFML) — nothing to unlink.
        }
        DirectoryDelete(arguments.path, true);
    }

    /**
     * Internal function for `$removeTree()`. Recursively deletes every symlink
     * an entry points at, leaving real files and directories for the caller's
     * recursive delete.
     */
    private void function $unlinkSymlinks(required string path) {
        var jFiles = CreateObject("java", "java.nio.file.Files");
        var jPaths = CreateObject("java", "java.nio.file.Paths");
        // Copy into a fresh array: BoxLang returns a fixed-size array from
        // DirectoryList() and ArrayAppend on it throws with no message.
        var entries = [];
        for (var listed in DirectoryList(arguments.path, false, "path")) {
            ArrayAppend(entries, listed);
        }
        for (var entry in entries) {
            if (jFiles.isSymbolicLink(jPaths.get(entry, []))) {
                jFiles.delete(jPaths.get(entry, []));
            } else if (DirectoryExists(entry)) {
                $unlinkSymlinks(entry);
            }
        }
    }

    /**
     * Return a configured TestClient instance.
     * The base URL is auto-detected from the current server port.
     *
     * @testContext When true (default), send the isolation header + cookie so
     *   fixture HTTP binds the isolated test application (issue #3374). Pass
     *   false to address the live application (isolation specs).
     */
    public any function $testClient(boolean testContext = true) {
        // Do not name this local `client` — that is a reserved CFML scope
        // and Lucee throws "client scope is not enabled" (anti-pattern 11).
        var httpClient = new wheels.wheelstest.TestClient(baseUrl = $getTestBaseUrl(), testContext = arguments.testContext);
        if (arguments.testContext) {
            var ctx = new wheels.events.TestContext();
            // Send the per-process runner secret (not a fixed "1").
            // TestClient requests originate from loopback, so the framework gate
            // binds the isolated application only for this trusted runner.
            var testSecret = ctx.testSecret();
            httpClient.withHeader(ctx.headerName(), testSecret);
            httpClient.withCookie(ctx.cookieName(), testSecret);
        }
        return httpClient;
    }

    /**
     * Auto-detect the base URL of the running test server. Resolved through
     * a layered lookup mirroring BrowserTest.$resolveBaseUrl, so HTTPS,
     * non-localhost, and vhosted setups target the right origin instead of
     * a hardcoded http://localhost. Precedence, highest first:
     *
     *   1. this.testClientBaseUrl             — per-spec override
     *   2. get("testClientBaseUrl")           — Wheels setting
     *   3. -Dwheels.testClient.baseUrl=...    — JVM system property
     *   4. WHEELS_TEST_CLIENT_BASE_URL env    — CI / shell
     *   5. $detectTestBaseUrlFromCgi(cgi)     — scheme/host/port of the
     *                                            in-flight test-runner request
     *   6. "http://localhost:8080" default    — bare LuCLI port
     */
    private string function $getTestBaseUrl() {
        if (len(this.testClientBaseUrl ?: "")) {
            return this.testClientBaseUrl;
        }

        try {
            var setting = get(name = "testClientBaseUrl");
            if (len(setting ?: "")) {
                return setting;
            }
        } catch (any e) {
            // Setting not registered — fall through to the next layer.
        }

        try {
            var sys = createObject("java", "java.lang.System");
            var prop = sys.getProperty("wheels.testClient.baseUrl");
            if (!isNull(prop) && len(prop)) {
                return prop;
            }
            var envValue = sys.getenv("WHEELS_TEST_CLIENT_BASE_URL");
            if (!isNull(envValue) && len(envValue)) {
                return envValue;
            }
        } catch (any e) {
            // Best-effort: a SecurityManager could deny system access.
        }

        try {
            var detected = $detectTestBaseUrlFromCgi(cgi);
            if (len(detected)) {
                return detected;
            }
        } catch (any e) {
            // cgi scope unavailable (rare; e.g. background thread) — fall
            // through to the hardcoded default.
        }

        return "http://localhost:8080";
    }

    /**
     * Derive the test base URL from the in-flight test-runner request,
     * preserving scheme (https) and host instead of assuming
     * http://localhost. Mirrors BrowserTest.$detectBaseUrlFromCgi.
     */
    public string function $detectTestBaseUrlFromCgi(required any cgiScope) {
        if (!structKeyExists(arguments.cgiScope, "server_port") || !val(arguments.cgiScope.server_port ?: 0)) {
            return "";
        }
        var port = val(arguments.cgiScope.server_port);
        var host = len(arguments.cgiScope.server_name ?: "") ? arguments.cgiScope.server_name : "localhost";
        var scheme = (arguments.cgiScope.https ?: "off") == "on" ? "https" : "http";
        var isCanonicalPort = (scheme == "http" && port == 80) || (scheme == "https" && port == 443);
        return scheme & "://" & host & (isCanonicalPort ? "" : ":" & port);
    }

}
