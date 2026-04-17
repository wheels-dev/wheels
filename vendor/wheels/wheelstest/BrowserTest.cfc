/**
 * TestBox base class for browser-driven specs. Wraps BrowserLauncher
 * lifecycle so individual specs can focus on describe/it blocks:
 *
 *     component extends="wheels.wheelstest.BrowserTest" {
 *         this.browserEngine = "chromium";  // optional (default chromium)
 *
 *         function run() {
 *             describe("signup flow", () => {
 *                 it("lands on the form", () => {
 *                     this.browser.visitUrl("data:text/html,<h1>Hi</h1>")
 *                                 .assertSee("Hi");
 *                 });
 *             });
 *         }
 *     }
 *
 * Lifecycle:
 *   - beforeAll:  ensure an application-scoped BrowserLauncher is initialized,
 *                 acquire the shared Browser handle for the requested engine
 *   - beforeEach: fresh BrowserContext + Page, wrapped in a new BrowserClient,
 *                 exposed as `this.browser`
 *   - afterEach:  close the context (cookies, localStorage, etc. reset)
 *   - afterAll:   drop our handle to the Browser — process-scoped Launcher
 *                 keeps it alive for the next spec in the run
 *
 * Specs that use this base can assume this.browser is populated and
 * well-isolated without managing Playwright plumbing themselves.
 *
 * Deferred (per the browser testing foundation PR scope):
 *   - keepSignedInAs / storageState replay — require building additional
 *     Playwright option objects through the URLClassLoader.
 *     Specs needing these can drop down to the raw Playwright objects via
 *     getBrowserLauncher() / this.browser.getContext() / getPage().
 */
component extends="wheels.WheelsTest" {

    this.browserEngine = "chromium";
    this.browserViewport = "";  // empty = Playwright default; "mobile"/"tablet"/"desktop" or {width:N, height:N}
    this.browserScreenshotOnFailure = true;
    this.browser = "";
    this.browserTestSkipped = false;

    variables.$launcher = "";
    variables.$browser = "";
    variables.$context = "";
    variables.$page = "";
    variables.$baseUrl = "";

    function beforeAll() {
        // Opt-in gate for CI: browser fixture infrastructure (routes, dialogs,
        // createDynamicProxy) is not yet reliable under LuCLI Express, so CI
        // defaults to skipping browser specs. Set WHEELS_BROWSER_CI_ENABLE=true
        // to force execution once the fixture server is verified in CI.
        if ($isCiSkipEnabled()) {
            this.browserTestSkipped = true;
            return;
        }

        // Browser specs depend on named fixture routes (browserTestHome,
        // browserTestLogin, etc.) declared in vendor/wheels/tests/routes.cfm.
        // Other specs in the suite (mapperSpec, security/PaginationXssSpec,
        // view/formsSpec, view/linksSpec) legitimately clear the route table
        // via `$clearRoutes()` to test route-registration behavior, and do
        // not restore it afterwards. If those specs run before browser
        // specs — which happens alphabetically in the core suite — the
        // fixture routes are gone by the time browser specs execute.
        // Re-include the test routes here so browser specs are self-contained.
        application.wo.$include(template="/wheels/tests/routes.cfm");
        application.wo.$setNamedRoutePositions();

        try {
            variables.$launcher = $ensureLauncher();
        } catch (Wheels.BrowserNotInstalled e) {
            this.browserTestSkipped = true;
            return;
        }
        variables.$browser = variables.$launcher.acquireBrowser(engine=this.browserEngine);
        variables.$baseUrl = $resolveBaseUrl();
    }

    /**
     * True when CI is detected and browser specs are not explicitly opted in.
     * Checks WHEELS_CI (set by the CI workflow) and WHEELS_BROWSER_CI_ENABLE
     * (opt-in override).
     */
    private boolean function $isCiSkipEnabled() {
        try {
            var sys = createObject("java", "java.lang.System");
            var ci = sys.getenv("WHEELS_CI") ?: "";
            if (!len(ci)) return false;
            var enable = sys.getenv("WHEELS_BROWSER_CI_ENABLE") ?: "";
            return !listFindNoCase("true,1,yes", enable);
        } catch (any e) {
            return false;
        }
    }

    function afterAll() {
        // Launcher + Browser are process-scoped; the application-scoped
        // launcher is released when the Lucee app scope clears. We just
        // drop our local handle.
        variables.$browser = "";
    }

    /**
     * Wraps TestBox's describe() with beforeEach/afterEach closures that
     * set up and tear down a fresh BrowserContext + Page per `it` block.
     * TestBox BDD only treats `beforeAll`/`afterAll` as class-level hooks;
     * beforeEach/afterEach must be registered from INSIDE a describe body.
     *
     *     function run() {
     *         browserDescribe("my feature", () => {
     *             it("does the thing", () => {
     *                 this.browser.visit("/").assertSee("...");
     *             });
     *         });
     *     }
     *
     * Specs can mix plain describe() (no browser wiring) with
     * browserDescribe() (browser wiring) freely in the same run().
     */
    public void function browserDescribe(
        required string title,
        required any body
    ) {
        // Capture this + body so the inline closures can reach them.
        // (CFML `arguments` is per-function; inline closures can't see outer
        // function's arguments scope directly.)
        var me = this;
        var innerBody = arguments.body;

        describe(arguments.title, function() {
            beforeEach(function() { me.$startBrowserContext(); });

            aroundEach(function(spec, suite) {
                if (me.browserTestSkipped) {
                    arguments.spec.body();
                    return;
                }
                try {
                    arguments.spec.body();
                } catch (any e) {
                    me.$captureFailureArtifacts(arguments.spec);
                    rethrow;
                }
            });

            afterEach(function() { me.$endBrowserContext(); });
            innerBody();
        });
    }

    /**
     * Exposed for custom lifecycle patterns — callers who want to write
     * `describe(..., () => { beforeEach(() => { $startBrowserContext(); }); ...})`
     * manually instead of using browserDescribe().
     */
    public void function $startBrowserContext() {
        if (this.browserTestSkipped) return;

        var contextOpts = $buildContextOptions();

        if (isObject(contextOpts)) {
            variables.$context = variables.$browser.newContext(contextOpts);
        } else {
            variables.$context = variables.$browser.newContext();
        }
        variables.$page = variables.$context.newPage();
        this.browser = new wheels.wheelstest.BrowserClient()
            .init(
                page=variables.$page,
                context=variables.$context,
                baseUrl=variables.$baseUrl,
                launcher=variables.$launcher
            );
    }

    public void function $endBrowserContext() {
        if (this.browserTestSkipped) return;
        if (isObject(variables.$context)) {
            try {
                variables.$context.close();
            } catch (any e) {
                // Best-effort: context.close() can fail if the page crashed
                // (bad data: URL, JS unhandled error). Test assertions ran
                // before this, so swallowing here doesn't hide test results.
                // Continuing to clear refs prevents leaked Page/Context
                // references between `it` blocks.
            }
            variables.$context = "";
            variables.$page = "";
            this.browser = "";
        }
    }

    /** Accessor for specs that need to reach Playwright directly. */
    public any function getBrowserLauncher() {
        return variables.$launcher;
    }

    /**
     * Lazily initialize a process-wide BrowserLauncher in application scope.
     * A single Playwright instance + Browser handle serves all BrowserTest
     * subclasses in the run — avoids paying ~1.7s per spec-file startup.
     *
     * Throws Wheels.BrowserNotInstalled if any classpath JAR is missing —
     * callers catch this and skip browser tests gracefully.
     *
     * Wrapped in cflock to guard the check-then-act on application scope
     * against parallel beforeAll invocations (relevant if ParallelRunner or
     * multi-bundle parallelism is ever used; sequential TestBox makes this
     * a no-op today).
     */
    private any function $ensureLauncher() {
        if (structKeyExists(application, "$wheelsBrowserLauncher")) {
            return application.$wheelsBrowserLauncher;
        }
        lock name="wheelsBrowserLauncherInit" type="exclusive" timeout="60" {
            // Re-check inside the lock — another thread may have initialized
            // while we were waiting.
            if (structKeyExists(application, "$wheelsBrowserLauncher")) {
                return application.$wheelsBrowserLauncher;
            }
            var l = new wheels.wheelstest.BrowserLauncher();
            var paths = l.$classpathJarPaths(installDir=l.resolveInstallDir());
            for (var p in paths) {
                if (!fileExists(p)) {
                    throw(
                        type="Wheels.BrowserNotInstalled",
                        message="Playwright JAR missing: " & p
                            & ". Run tools/install-playwright.sh to set up browser testing."
                    );
                }
            }
            l.$loadJars(jarPaths=paths);
            application.$wheelsBrowserLauncher = l;
        }
        return application.$wheelsBrowserLauncher;
    }

    /**
     * Base URL for `client.visit("/path")`. Defaults to localhost:8080
     * (the default LuCLI port); override via WHEELS_BROWSER_TEST_BASE_URL env.
     * For specs that use only `visitUrl(absolute)` (e.g. data:/file:), the
     * baseUrl is effectively unused.
     */
    private string function $resolveBaseUrl() {
        try {
            var env = createObject("java", "java.lang.System")
                .getenv("WHEELS_BROWSER_TEST_BASE_URL");
            if (!isNull(env) && len(env)) return env;
        } catch (any e) {
            // Best-effort: SecurityManager could deny env access. Falling
            // back to the localhost default is correct — if the user actually
            // configured a different URL but we can't read it, their tests
            // will fail with connection-refused, surfacing the problem
            // clearly rather than silently using the wrong URL.
        }
        return "http://localhost:8080";
    }

    /**
     * Best-effort capture of screenshot + HTML on test failure.
     * Called from aroundEach catch block. Swallows all errors to avoid
     * masking the real test failure.
     */
    public void function $captureFailureArtifacts(required any spec) {
        if (!(this.browserScreenshotOnFailure ?: true)) return;
        if (!isObject(this.browser) || this.browserTestSkipped) return;

        try {
            var artifactDir = this.browserArtifactPath
                ?: expandPath("/tests/_output/browser");

            if (!directoryExists(artifactDir)) {
                directoryCreate(artifactDir, true);
            }

            var rawName = arguments.spec.name ?: "unknown_spec";
            var safeName = reReplace(rawName, "[^a-zA-Z0-9_\-]", "_", "all");
            if (len(safeName) > 80) safeName = left(safeName, 80);
            var ts = dateFormat(now(), "yyyymmdd") & "_" & timeFormat(now(), "HHmmss");
            var baseName = safeName & "-" & ts;

            this.browser.screenshot(path=artifactDir & "/" & baseName & ".png");
            fileWrite(artifactDir & "/" & baseName & ".html", this.browser.pageSource());
        } catch (any e) {
            // Best-effort: page may have crashed, context may be closed.
            // Swallow to avoid masking the real test failure.
        }
    }

    /**
     * Builds Browser$NewContextOptions if viewport config is set.
     * Returns the options object, or empty string if no config.
     */
    private any function $buildContextOptions() {
        if (!structKeyExists(this, "browserViewport") || !len(this.browserViewport ?: "")) {
            return "";
        }

        var dims = $resolveViewportDims(this.browserViewport);

        var viewport = variables.$launcher.$buildOption(
            className="com.microsoft.playwright.options.ViewportSize",
            constructorArgs=[dims.width, dims.height]
        );

        return variables.$launcher.$buildOption(
            className="com.microsoft.playwright.Browser$NewContextOptions",
            setterMap={setViewportSize: viewport}
        );
    }

    /**
     * Resolve viewport config to {width, height} struct.
     */
    private struct function $resolveViewportDims(required any viewport) {
        if (isSimpleValue(arguments.viewport)) {
            switch (lCase(arguments.viewport)) {
                case "mobile":
                    return {width: 375, height: 667};
                case "tablet":
                    return {width: 768, height: 1024};
                case "desktop":
                    return {width: 1440, height: 900};
                default:
                    throw(
                        type="Wheels.BrowserViewportInvalid",
                        message="Unknown viewport preset: " & arguments.viewport
                            & ". Valid: mobile, tablet, desktop"
                    );
            }
        }
        return {
            width: arguments.viewport.width ?: 1440,
            height: arguments.viewport.height ?: 900
        };
    }

}
