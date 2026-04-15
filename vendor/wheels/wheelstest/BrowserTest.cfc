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
 *   - viewport / keepSignedInAs / storageState replay — require building
 *     Playwright option objects (Browser$NewContextOptions, ViewportSize)
 *     through the URLClassLoader, which hits Lucee's OSGi bundle resolver.
 *     Resolving that is a reflection-helper pass planned for a follow-up.
 *     Specs needing these can drop down to the raw Playwright objects via
 *     getBrowserLauncher() / this.browser.getContext() / getPage().
 */
component extends="wheels.WheelsTest" {

    this.browserEngine = "chromium";
    this.browser = "";
    this.browserTestSkipped = false;

    variables.$launcher = "";
    variables.$browser = "";
    variables.$context = "";
    variables.$page = "";
    variables.$baseUrl = "";

    function beforeAll() {
        try {
            variables.$launcher = $ensureLauncher();
        } catch (Wheels.BrowserNotInstalled e) {
            this.browserTestSkipped = true;
            return;
        }
        variables.$browser = variables.$launcher.acquireBrowser(engine=this.browserEngine);
        variables.$baseUrl = $resolveBaseUrl();
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
        variables.$context = variables.$browser.newContext();
        variables.$page = variables.$context.newPage();
        this.browser = new wheels.wheelstest.BrowserClient()
            .init(
                page=variables.$page,
                context=variables.$context,
                baseUrl=variables.$baseUrl
            );
    }

    public void function $endBrowserContext() {
        if (this.browserTestSkipped) return;
        if (isObject(variables.$context)) {
            try { variables.$context.close(); } catch (any e) {}
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
     */
    private any function $ensureLauncher() {
        if (!structKeyExists(application, "$wheelsBrowserLauncher")) {
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
        } catch (any e) {}
        return "http://localhost:8080";
    }

}
