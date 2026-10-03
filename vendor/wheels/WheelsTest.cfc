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
     *   5. servlet local listen port          — when the request's local port
     *                                            differs from its Host port (a
     *                                            port mapping), loopback + the
     *                                            actual listen port/scheme
     *   6. $detectTestBaseUrlFromCgi(cgi)     — scheme/host/port of the
     *                                            in-flight test-runner request
     *   7. "http://localhost:8080" default    — bare LuCLI port
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
            var endpoint = $servletLocalEndpoint();
            var mapped = $detectBaseUrlFromServletPort(cgi, endpoint.port, endpoint.scheme);
            if (len(mapped)) {
                return mapped;
            }
        } catch (any e) {
            // Servlet request unavailable (e.g. a non-servlet engine) — fall
            // through to cgi detection.
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

    /**
     * When the in-flight request's local listen port differs from its Host port
     * (i.e. a port mapping is in play), the Host name + port is not a reliable
     * loopback target, so return a loopback URL on the actual listen port and
     * scheme. Returns "" when there is no mapping (unmapped stays byte-identical
     * via the cgi step) or no servlet port is available. Public seam for specs.
     *
     * @cgiScope      The cgi scope (or a struct with server_port) of the request.
     * @localPort     The servlet request's local listen port (0 when unavailable).
     * @localScheme   The servlet request's scheme ("http"/"https").
     */
    public string function $detectBaseUrlFromServletPort(required any cgiScope, required numeric localPort, string localScheme = "http") {
        if (arguments.localPort <= 0 || !structKeyExists(arguments.cgiScope, "server_port")) {
            return "";
        }
        if (val(arguments.cgiScope.server_port) == arguments.localPort) {
            return "";
        }
        var scheme = len(arguments.localScheme) ? arguments.localScheme : "http";
        return scheme & "://127.0.0.1:" & arguments.localPort;
    }

    /**
     * Best-effort read of the in-flight servlet request's local listen port and
     * scheme. Returns {port = 0, scheme = "http"} when the servlet request is
     * unavailable (e.g. a non-servlet engine such as RustCFML), so callers fall
     * through to cgi detection. Private; the pure mapping logic lives in
     * $detectBaseUrlFromServletPort for testability.
     */
    private struct function $servletLocalEndpoint() {
        var endpoint = {port = 0, scheme = "http"};
        try {
            if (getFunctionList().keyExists("getPageContext")) {
                var req = getPageContext().getRequest();
                if (!isNull(req)) {
                    var p = req.getLocalPort();
                    if (!isNull(p) && val(p) > 0) {
                        endpoint.port = val(p);
                    }
                    var s = req.getScheme();
                    if (!isNull(s) && len(s)) {
                        endpoint.scheme = lCase(s);
                    }
                }
            }
        } catch (any e) {
            // Non-servlet engine or restricted request — leave defaults.
        }
        return endpoint;
    }

}
