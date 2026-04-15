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

        describe("BrowserClient — interaction against real Chromium (inline HTML)", () => {

            // Each `it` gets a fresh context + page. Inline HTML forms via
            // data: URLs let us test fill/click/check/etc without a real
            // server. Return values of interaction methods are asserted via
            // reading the locator's current state after the call.

            beforeEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx = variables.browser.newContext();
                variables.pg = variables.ctx.newPage();
                variables.bc = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="");
            });

            afterEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx.close();
            });

            it("fill() sets an input value and returns this for chaining", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='e' type='email'>");
                var result = variables.bc.fill("##e", "alice@example.com");
                expect(result).toBe(variables.bc);
                expect(variables.pg.locator("##e").inputValue()).toBe("alice@example.com");
            });

            it("type() sends keystrokes one-by-one", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='n'>");
                variables.bc.type("##n", "hello");
                expect(variables.pg.locator("##n").inputValue()).toBe("hello");
            });

            it("clear() empties a previously-filled input", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='e'>");
                variables.bc.fill("##e", "abc").clear("##e");
                expect(variables.pg.locator("##e").inputValue()).toBe("");
            });

            it("click() triggers button handler (verified via DOM mutation)", () => {
                if (variables.skipBrowserTests) return;
                // Use a button that mutates the DOM on click — avoids needing
                // a form submit path (which would require a real server).
                var html = "<button id='b' onclick=""document.getElementById('out').textContent='clicked'"">Go</button><div id='out'></div>";
                variables.bc.visitUrl("data:text/html," & html);
                variables.bc.click("##b");
                expect(variables.pg.locator("##out").textContent()).toBe("clicked");
            });

            it("press('Go') clicks by visible text", () => {
                if (variables.skipBrowserTests) return;
                var html = "<button onclick=""document.getElementById('out').textContent='pressed'"">Go</button><div id='out'></div>";
                variables.bc.visitUrl("data:text/html," & html);
                variables.bc.press("Go");
                expect(variables.pg.locator("##out").textContent()).toBe("pressed");
            });

            it("check() / uncheck() toggle a checkbox", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='cb' type='checkbox'>");
                variables.bc.check("##cb");
                expect(variables.pg.locator("##cb").isChecked()).toBeTrue();
                variables.bc.uncheck("##cb");
                expect(variables.pg.locator("##cb").isChecked()).toBeFalse();
            });

            it("select() chooses a dropdown option by value", () => {
                if (variables.skipBrowserTests) return;
                var html = "<select id='s'><option value='a'>A</option><option value='b'>B</option></select>";
                variables.bc.visitUrl("data:text/html," & html);
                variables.bc.select("##s", "b");
                expect(variables.pg.locator("##s").inputValue()).toBe("b");
            });
        });
    }
}
