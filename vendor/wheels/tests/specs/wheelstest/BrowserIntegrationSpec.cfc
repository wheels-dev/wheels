component extends="wheels.WheelsTest" {

    // Shared BrowserLauncher + Browser across specs (expensive, ~1.7s per launch).
    // beforeEach creates a fresh BrowserContext for isolation between `it`s.

    function beforeAll() {
        variables.skipBrowserTests = true;
        variables.launcher = new wheels.wheelstest.BrowserLauncher();
        var paths = variables.launcher.$classpathJarPaths(installDir=variables.launcher.resolveInstallDir());
        for (var p in paths) {
            if (!fileExists(p)) return;
        }
        variables.launcher.$loadJars(jarPaths=paths);
        variables.browser = variables.launcher.acquireBrowser(engine="chromium");
        variables.skipBrowserTests = false;
    }

    function afterAll() {
        if (!(variables.skipBrowserTests ?: true)) {
            variables.launcher.release();
        }
    }

    function run() {

        describe("BrowserClient — pure unit-level behavior (no browser)", () => {

            it("visit() rejects paths without a leading slash", () => {
                var c = new wheels.wheelstest.BrowserClient()
                    .init(page="", context="", baseUrl="http://localhost");
                expect(() => {
                    c.visit("no-leading-slash");
                }).toThrow(type="Wheels.BrowserInvalidPath");
            });

            it("getBaseUrl() returns what init() received", () => {
                var c = new wheels.wheelstest.BrowserClient()
                    .init(baseUrl="http://example.test:1234");
                expect(c.getBaseUrl()).toBe("http://example.test:1234");
            });

            it("init() is chainable", () => {
                var c = new wheels.wheelstest.BrowserClient();
                var result = c.init(baseUrl="http://x");
                expect(result).toBe(c);
            });
        });

        describe("BrowserClient — navigation against real Chromium (data: URLs)", () => {

            // data: URLs avoid needing a fixture server; still exercises real
            // Playwright navigation + currentUrl plumbing through our DSL.

            beforeEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx = variables.browser.newContext();
                variables.pg = variables.ctx.newPage();
            });

            afterEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx.close();
            });

            it("visitUrl() navigates and currentUrl() reflects the page", () => {
                if (variables.skipBrowserTests) return;
                var c = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="");
                var result = c.visitUrl("data:text/html,<h1>Hello</h1>");
                expect(result).toBe(c);
                expect(c.currentUrl()).toInclude("data:text/html");
                expect(c.currentUrl()).toInclude("Hello");
            });

            it("back() / forward() navigate history", () => {
                if (variables.skipBrowserTests) return;
                var c = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="");
                c.visitUrl("data:text/html,<h1>One</h1>");
                c.visitUrl("data:text/html,<h1>Two</h1>");
                expect(c.currentUrl()).toInclude("Two");
                c.back();
                expect(c.currentUrl()).toInclude("One");
                c.forward();
                expect(c.currentUrl()).toInclude("Two");
            });

            it("refresh() keeps the url stable", () => {
                if (variables.skipBrowserTests) return;
                var c = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="");
                c.visitUrl("data:text/html,<title>X</title>");
                var before = c.currentUrl();
                c.refresh();
                expect(c.currentUrl()).toBe(before);
            });
        });
    }
}
