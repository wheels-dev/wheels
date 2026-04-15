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

        describe("BrowserClient — keyboard, waiting, scoping", () => {

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

            it("keys(selector, 'Enter') dispatches an Enter keypress", () => {
                if (variables.skipBrowserTests) return;
                var html = "<input id='i' onkeydown=""if(event.key==='Enter') document.getElementById('o').textContent='e'""><div id='o'></div>";
                variables.bc.visitUrl("data:text/html," & html);
                variables.bc.keys("##i", "Enter");
                expect(variables.pg.locator("##o").textContent()).toBe("e");
            });

            it("pressEnter(selector) is shorthand for keys(selector, 'Enter')", () => {
                if (variables.skipBrowserTests) return;
                var html = "<input id='i' onkeydown=""if(event.key==='Enter') document.getElementById('o').textContent='E'""><div id='o'></div>";
                variables.bc.visitUrl("data:text/html," & html);
                variables.bc.pressEnter("##i");
                expect(variables.pg.locator("##o").textContent()).toBe("E");
            });

            it("pressTab() with no selector sends Tab to keyboard", () => {
                if (variables.skipBrowserTests) return;
                // Focus input A, press Tab, expect input B to have focus.
                var html = "<input id='a' autofocus><input id='b'>";
                variables.bc.visitUrl("data:text/html," & html);
                // Give the page a tick to apply autofocus.
                variables.bc.click("##a");
                variables.bc.pressTab();
                // activeElement's id reflects focus
                var focusedId = variables.pg.evaluate("() => document.activeElement.id");
                expect(focusedId).toBe("b");
            });

            it("waitFor(selector) resolves once the element is visible", () => {
                if (variables.skipBrowserTests) return;
                // Script injects a new node after 50ms; waitFor blocks until it appears.
                var html = "<div id='root'></div><script>setTimeout(() => { var n = document.createElement('span'); n.id = 'late'; n.textContent = 'hi'; document.getElementById('root').appendChild(n); }, 50);</script>";
                variables.bc.visitUrl("data:text/html," & html);
                var result = variables.bc.waitFor("##late");
                expect(result).toBe(variables.bc);
                expect(variables.pg.locator("##late").textContent()).toBe("hi");
            });

            it("waitForText(text) resolves once the text appears", () => {
                if (variables.skipBrowserTests) return;
                var html = "<div id='root'></div><script>setTimeout(() => { document.getElementById('root').textContent = 'Delayed Text'; }, 50);</script>";
                variables.bc.visitUrl("data:text/html," & html);
                variables.bc.waitForText("Delayed Text");
                expect(variables.pg.locator("##root").textContent()).toBe("Delayed Text");
            });

            it("within(selector, callback) scopes interactions to a subtree", () => {
                if (variables.skipBrowserTests) return;
                // Two forms with same-id inputs. within() should restrict
                // our fill() to the second form.
                var html = "<form id='f1'><input id='email'></form><form id='f2'><input id='email'></form>";
                variables.bc.visitUrl("data:text/html," & html);
                variables.bc.within("form##f2", (scoped) => {
                    scoped.fill("##email", "in-f2");
                });
                // f1's email is still empty; f2's email got set.
                expect(variables.pg.locator("##f1 ##email").inputValue()).toBe("");
                expect(variables.pg.locator("##f2 ##email").inputValue()).toBe("in-f2");
            });
        });

        describe("BrowserClient — viewport + script", () => {

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

            it("resize(w, h) sets viewport size; script can read window dims", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>X</h1>");
                variables.bc.resize(800, 600);
                var w = variables.bc.script("() => window.innerWidth");
                var h = variables.bc.script("() => window.innerHeight");
                expect(w).toBe(800);
                expect(h).toBe(600);
            });

            it("resizeToMobile() sets 375x667", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>X</h1>").resizeToMobile();
                expect(variables.bc.script("() => window.innerWidth")).toBe(375);
                expect(variables.bc.script("() => window.innerHeight")).toBe(667);
            });

            it("resizeToTablet() sets 768x1024", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>X</h1>").resizeToTablet();
                expect(variables.bc.script("() => window.innerWidth")).toBe(768);
            });

            it("resizeToDesktop() sets 1440x900", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>X</h1>").resizeToDesktop();
                expect(variables.bc.script("() => window.innerWidth")).toBe(1440);
            });

            it("script(js) evaluates and returns result", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>Hello</h1>");
                expect(variables.bc.script("() => 2 + 2")).toBe(4);
                expect(variables.bc.script("() => document.querySelector('h1').textContent")).toBe("Hello");
            });
        });
    }
}
