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
     * The Wheels repository root, with a trailing slash, derived from the `/wheels`
     * mapping (`vendor/wheels`).
     */
    public string function $frameworkRepoRoot() {
        return ExpandPath("/wheels/../..") & "/";
    }

    /**
     * Skips the calling spec when the run is not inside the Wheels framework
     * repository. The framework suite run from an app (`/wheels/core/tests`) has
     * no `cli/`, `tools/`, `.github/`, `web/` or demo app, so a spec that reads
     * them reports as skipped there, naming the path it needs, instead of
     * erroring. Call it first in the spec, before any try/catch. Returns the
     * absolute path.
     *
     * @relativePath The path the spec reads, relative to the repository root.
     */
    public string function $requireRepoPath(required string relativePath) {
        local.relative = ReReplace(arguments.relativePath, "^[/\\]+", "");
        local.root = $frameworkRepoRoot();
        if (!DirectoryExists(local.root & "cli/lucli/templates")) {
            skip("Needs '" & local.relative & "' from the Wheels framework repository, which an app does not have.");
        }
        return local.root & local.relative;
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
     *   5. probed servlet local listen port   — when the request's local port
     *                                            differs from its Host port (a
     *                                            port mapping), probe the loopback
     *                                            candidate (http then https) and
     *                                            use the one that answers as HTTP;
     *                                            skip when none answers (AJP, TLS
     *                                            mismatch) so the cgi step runs
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
            var mapped = $resolveServletLoopbackBaseUrl(cgi);
            if (len(mapped)) {
                return mapped;
            }
        } catch (any e) {
            // Servlet request unavailable or probe failed — fall through to
            // cgi detection (never block a test run on the probe).
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
     * Resolve a loopback base URL from the server's actual local listen port,
     * but only when it is a usable HTTP(S) endpoint. A local/Host port mismatch
     * alone does NOT prove a direct loopback HTTP endpoint: behind an AJP front
     * end (IIS+BonCode, mod_jk) the local port is the AJP port, and getScheme()
     * is the logical request scheme (a TLS-terminating HTTP connector can report
     * https on a plain-HTTP socket). So we probe the candidate(s) — http first,
     * then https — and return the first that answers as HTTP. Returns "" when
     * there is no mapping, no servlet port, or nothing answers, so the caller
     * falls through to cgi detection (today's behaviour). Shared by WheelsTest
     * and BrowserTest. Public so the parallel resolver can call it.
     */
    public string function $resolveServletLoopbackBaseUrl(required any cgiScope) {
        var candidates = $servletLoopbackCandidates(arguments.cgiScope, $servletLocalPort());
        var probe = (candidate) => $probeHttpEndpointCached(candidate);
        return $selectAnsweringCandidate(candidates, probe);
    }

    /**
     * Candidate loopback base URLs to probe, http first then https, or [] when
     * there is no port mapping (local port == Host port, or no local port). Pure
     * and public for specs. The scheme is decided empirically by the probe, not
     * taken from getScheme().
     */
    public array function $servletLoopbackCandidates(required any cgiScope, required numeric localPort) {
        if (arguments.localPort <= 0 || !structKeyExists(arguments.cgiScope, "server_port")) {
            return [];
        }
        if (val(arguments.cgiScope.server_port) == arguments.localPort) {
            return [];
        }
        return ["http://127.0.0.1:" & arguments.localPort, "https://127.0.0.1:" & arguments.localPort];
    }

    /**
     * Return the first candidate URL for which probe(url) is true, or "" when
     * none answers. Pure logic with an injected probe so specs can exercise the
     * mapped-answers, only-https-answers, and nothing-answers (AJP/fallback)
     * cases without a live server. Public for specs.
     */
    public string function $selectAnsweringCandidate(required array candidates, required any probe) {
        var probeFn = arguments.probe;
        for (var candidate in arguments.candidates) {
            if (probeFn(candidate)) {
                return candidate;
            }
        }
        return "";
    }

    /**
     * The in-flight servlet request's local listen port, or 0 when unavailable
     * (e.g. a non-servlet engine such as RustCFML, which then skips the whole
     * step). Public so a test double can stub it; the pure candidate logic lives
     * in $servletLoopbackCandidates.
     */
    public numeric function $servletLocalPort() {
        try {
            if (getFunctionList().keyExists("getPageContext")) {
                var req = getPageContext().getRequest();
                if (!isNull(req)) {
                    var p = req.getLocalPort();
                    if (!isNull(p) && val(p) > 0) {
                        return val(p);
                    }
                }
            }
        } catch (any e) {
            // Non-servlet engine or restricted request.
        }
        return 0;
    }

    /**
     * $probeHttpEndpoint memoized per candidate URL (scheme+port) in the
     * application scope. A positive result is cached for the app lifetime; a
     * negative is cached only for a short TTL, so a transient failure (e.g. a
     * cold-start blip) self-heals rather than permanently pinning the candidate
     * as "no HTTP here", while a real AJP front end still avoids paying the
     * timeout on every single $testClient() call within the TTL window.
     * Lock-free: the read/write is a cheap struct op and the probe (which waits)
     * runs outside any lock; concurrent first-use probes are idempotent.
     */
    private boolean function $probeHttpEndpointCached(required string candidate) {
        var cacheKey = "$testClientLoopbackProbe";
        var negativeTtlMs = 60000;
        try {
            var appScope = application[$appKey()];
            if (!structKeyExists(appScope, cacheKey)) {
                appScope[cacheKey] = {};
            }
            var cache = appScope[cacheKey];
            if (structKeyExists(cache, arguments.candidate)) {
                var entry = cache[arguments.candidate];
                // A positive result is cached for the app lifetime; a negative
                // expires after a short TTL so a transient failure self-heals
                // (never permanently pins a cold-start timeout as "no HTTP here").
                if (entry.answer || (GetTickCount() - entry.at) < negativeTtlMs) {
                    return entry.answer;
                }
            }
            var answered = $probeHttpEndpoint(arguments.candidate);
            cache[arguments.candidate] = {answer = answered, at = GetTickCount()};
            return answered;
        } catch (any e) {
            // If the cache scope is unavailable, probe directly (uncached).
            return $probeHttpEndpoint(arguments.candidate);
        }
    }

    /**
     * True when a loopback candidate answers as HTTP. A bare GET (no test-context
     * header, so it never recurses into the isolated-app binding) to a cheap
     * framework endpoint, with redirects disabled and a short timeout. ANY HTTP
     * status (200/302/404/...) means the transport works; a transport failure
     * (connection refused, timeout, AJP speaking a non-HTTP protocol, TLS
     * mismatch) means it does not. Any error is swallowed as "no" so a probe
     * never blocks a test run. Public for specs.
     */
    public boolean function $probeHttpEndpoint(required string candidate) {
        try {
            cfhttp(
                method = "GET",
                url = arguments.candidate & "/WEB-INF/wheels-loopback-probe",
                redirect = false,
                timeout = 1,
                throwonerror = false,
                result = "local.probeResult"
            );
            // "Answers as HTTP" means the server actually sent a status line + headers.
            // The raw `header` field is populated on any real HTTP response (200/302/404/...),
            // and empty on a connect failure or a read timeout (AJP speaking a non-HTTP
            // protocol, TLS mismatch) — where cfhttp synthesizes a 408/502 status_code with
            // no header, so status_code alone cannot be trusted.
            return len(trim(local.probeResult.header ?: "")) > 0;
        } catch (any e) {
            return false;
        }
    }

    /**
     * Snapshot EVERY route-derived structure into an opaque struct that
     * $restoreRoutes() replays to reproduce byte-identical route state.
     *
     * Route specs that redefine the table must restore it in afterEach or
     * they leak stale state into later specs (routes, staticRoutes, and
     * namedRoutePositions are separate structures; $setNamedRoutePositions()
     * APPENDS and mapper().end() rebuilds staticRoutes, so a partial restore
     * is the #4192 bug class). These helpers centralise the full set:
     *
     *   beforeEach(() => { variables._routes = $snapshotRoutes(); $clearRoutes();
     *                      g.mapper()...end(); g.$setNamedRoutePositions(); });
     *   afterEach(() => $restoreRoutes(variables._routes));
     *
     * Managed keys (each guarded, so this works on develop now and auto-covers
     * #4183's dynamicRouteIndex / routeTableGeneration once it merges):
     *   application[appKey].{routes, staticRoutes, namedRoutePositions,
     *                        urlForCache, dynamicRouteIndex, routeTableGeneration}
     *   request.wheels.urlForCache  (the whole core suite runs in ONE request,
     *                                so this request-scoped memo persists across specs)
     */
    public struct function $snapshotRoutes() {
        return {
            route = $captureRouteStateKeys(
                application[$routeStateAppKey()],
                "routes,staticRoutes,namedRoutePositions,urlForCache,dynamicRouteIndex,routeTableGeneration"
            ),
            request = StructKeyExists(request, "wheels")
                ? $captureRouteStateKeys(request.wheels, "urlForCache")
                : {}
        };
    }

    /** Restore route state captured by $snapshotRoutes(), exactly — a managed key absent at snapshot time is deleted. */
    public void function $restoreRoutes(required struct snapshot) {
        $applyRouteStateKeys(application[$routeStateAppKey()], arguments.snapshot.route);
        if (StructKeyExists(request, "wheels") && StructKeyExists(arguments.snapshot, "request")) {
            $applyRouteStateKeys(request.wheels, arguments.snapshot.request);
        }
    }

    /** Empty the route table and invalidate every route cache (for the snapshot -> clear -> rebuild -> restore idiom). */
    public void function $clearRoutes() {
        var scope = application[$routeStateAppKey()];
        scope.routes = [];
        scope.staticRoutes = {};
        scope.namedRoutePositions = {};
        StructDelete(scope, "dynamicRouteIndex");
        if (StructKeyExists(scope, "urlForCache")) {
            StructClear(scope.urlForCache);
        }
        if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "urlForCache")) {
            StructClear(request.wheels.urlForCache);
        }
    }

    /** The application key the route table and caches live under ("wheels" unless the framework reports otherwise). */
    private string function $routeStateAppKey() {
        if (StructKeyExists(application, "wo") && StructKeyExists(application.wo, "$appKey")) {
            try {
                var resolved = application.wo.$appKey();
                if (Len(resolved) && StructKeyExists(application, resolved)) {
                    return resolved;
                }
            } catch (any e) {
            }
        }
        return "wheels";
    }

    /** Deep-copy each listed key from a scope, recording whether it was present (so restore can delete absent ones). */
    private struct function $captureRouteStateKeys(required struct scope, required string keyList) {
        var captured = {};
        for (var key in ListToArray(arguments.keyList)) {
            if (StructKeyExists(arguments.scope, key)) {
                captured[key] = {present = true, value = Duplicate(arguments.scope[key])};
            } else {
                captured[key] = {present = false};
            }
        }
        return captured;
    }

    /** Replay captured keys onto a scope: present -> deep-copy back; absent -> delete. */
    private void function $applyRouteStateKeys(required struct scope, required struct captured) {
        for (var key in arguments.captured) {
            if (arguments.captured[key].present) {
                arguments.scope[key] = Duplicate(arguments.captured[key].value);
            } else {
                StructDelete(arguments.scope, key);
            }
        }
    }

}
