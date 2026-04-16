component extends="wheels.WheelsTest" {

    // Shared BrowserLauncher + Browser across specs (expensive, ~1.7s per launch).
    // beforeEach creates a fresh BrowserContext for isolation between `it`s.

    function beforeAll() {
        variables.launcher = new wheels.wheelstest.BrowserLauncher();
        var paths = variables.launcher.$classpathJarPaths(installDir=variables.launcher.resolveInstallDir());
        // Check JAR presence explicitly. Distinguishes "not installed"
        // (legitimate skip) from "installed but launcher crashed" (loud
        // failure that should propagate). Mirrors BrowserTest.cfc's
        // catch-specific pattern.
        for (var p in paths) {
            if (!fileExists(p)) {
                variables.skipBrowserTests = true;
                return;
            }
        }
        variables.skipBrowserTests = false;
        variables.launcher.$loadJars(jarPaths=paths);
        // If acquireBrowser throws (Wheels.BrowserLaunchFailed, etc), let it
        // propagate — those are real failures that should surface, not skip.
        variables.browser = variables.launcher.acquireBrowser(engine="chromium");
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

        describe("BrowserClient — launcher wiring", () => {

            it("exposes launcher via getLauncher()", () => {
                if (variables.skipBrowserTests) return;
                var bc = new wheels.wheelstest.BrowserClient()
                    .init(baseUrl="", launcher=variables.launcher);
                expect(isObject(bc.getLauncher())).toBeTrue();
                expect(bc.getLauncher().getState()).toBe("ready");
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
                    .init(page=variables.pg, context=variables.ctx, baseUrl="", launcher=variables.launcher);
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
                    .init(page=variables.pg, context=variables.ctx, baseUrl="", launcher=variables.launcher);
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

            it("waitFor honors custom timeout (short timeout fails on missing element)", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>No target here</h1>");
                expect(() => {
                    variables.bc.waitFor("##never-exists", 1);
                }).toThrow();
            });

            it("waitForText honors custom timeout (short timeout fails on missing text)", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>Hello</h1>");
                expect(() => {
                    variables.bc.waitForText("never appears", 1);
                }).toThrow();
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

        describe("BrowserClient — waitForUrl", () => {

            beforeEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx = variables.browser.newContext();
                variables.pg = variables.ctx.newPage();
                variables.bc = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="", launcher=variables.launcher);
            });

            afterEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx.close();
            });

            it("resolves immediately when URL already matches", () => {
                if (variables.skipBrowserTests) return;
                var targetUrl = "data:text/html,<h1>Here</h1>";
                variables.bc.visitUrl(targetUrl);
                // Use the exact URL rather than a glob — data: URLs don't
                // follow path-based glob conventions.
                variables.bc.waitForUrl(variables.bc.currentUrl(), 5);
            });

            it("throws on timeout when URL does not match", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>Here</h1>");
                expect(() => {
                    variables.bc.waitForUrl("http://will-never-match.example.com/**", 1);
                }).toThrow();
            });
        });

        describe("BrowserClient — viewport + script", () => {

            beforeEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx = variables.browser.newContext();
                variables.pg = variables.ctx.newPage();
                variables.bc = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="", launcher=variables.launcher);
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

        describe("BrowserClient — text + visibility + presence assertions", () => {

            beforeEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx = variables.browser.newContext();
                variables.pg = variables.ctx.newPage();
                variables.bc = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="", launcher=variables.launcher);
            });

            afterEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx.close();
            });

            it("assertSee passes when text is on page", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>Welcome</h1>").assertSee("Welcome");
            });

            it("assertSee throws Wheels.BrowserAssertionFailed when absent", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>A</h1>");
                expect(() => variables.bc.assertSee("Missing")).toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertDontSee passes when text is absent", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>A</h1>").assertDontSee("Missing");
            });

            it("assertSeeIn scopes text search to a selector", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>Title</h1><p>Body text</p>")
                    .assertSeeIn("h1", "Title");
                expect(() => variables.bc.assertSeeIn("h1", "Body"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertVisible passes when element is rendered", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='e'>").assertVisible("##e");
            });

            it("assertMissing passes when selector matches no elements", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='e'>").assertMissing("##nope");
            });

            it("assertPresent / assertNotPresent check DOM presence", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='e'>")
                    .assertPresent("##e")
                    .assertNotPresent("##nope");
            });
        });

        describe("BrowserClient — URL + title + query assertions", () => {

            beforeEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx = variables.browser.newContext();
                variables.pg = variables.ctx.newPage();
                variables.bc = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="", launcher=variables.launcher);
            });

            afterEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx.close();
            });

            it("assertUrlContains matches a substring of the current URL", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>X</h1>")
                    .assertUrlContains("text/html");
            });

            it("assertUrlContains throws when substring not present", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>X</h1>");
                expect(() => variables.bc.assertUrlContains("not-here"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertTitleContains matches via <title> element", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<title>My Page</title><h1>X</h1>")
                    .assertTitleContains("My Page");
                expect(() => variables.bc.assertTitleContains("Other"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertQueryStringHas / Missing parse the URL's query", () => {
                if (variables.skipBrowserTests) return;
                // data: URL with a query string. Playwright preserves the ?
                variables.bc.visitUrl("data:text/html,<h1>X</h1>?foo=bar&baz=qux")
                    .assertQueryStringHas("foo", "bar")
                    .assertQueryStringHas("baz")
                    .assertQueryStringMissing("nope");
            });
        });

        describe("BrowserClient — form assertions + terminals", () => {

            beforeEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx = variables.browser.newContext();
                variables.pg = variables.ctx.newPage();
                variables.bc = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="", launcher=variables.launcher);
            });

            afterEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx.close();
            });

            it("assertInputValue matches on filled value", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='e'>")
                    .fill("##e", "hello")
                    .assertInputValue("##e", "hello");
            });

            it("assertChecked passes on checked box", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='cb' type='checkbox'>")
                    .check("##cb")
                    .assertChecked("##cb");
            });

            it("assertHasClass passes when element has the named class", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<div id='d' class='foo bar baz'>x</div>")
                    .assertHasClass("##d", "bar")
                    .assertHasClass("##d", "foo");
                expect(() => variables.bc.assertHasClass("##d", "nope"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("title() returns the <title> element content", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<title>T</title><h1>X</h1>");
                expect(variables.bc.title()).toBe("T");
            });

            it("pageSource() returns full rendered HTML", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>Hello</h1>");
                expect(variables.bc.pageSource()).toInclude("Hello");
            });

            it("text(selector) returns the element's textContent", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>Heading</h1>");
                expect(variables.bc.text("h1")).toBe("Heading");
            });

            it("value(selector) returns current input value", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='e' value='preset'>");
                expect(variables.bc.value("##e")).toBe("preset");
            });

            it("screenshot(path) writes a valid PNG (magic bytes verified)", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>Snap</h1>");
                var tmpPath = getTempDirectory() & "wheels-bc-" & createUUID() & ".png";
                try {
                    variables.bc.screenshot(tmpPath);
                    expect(fileExists(tmpPath)).toBeTrue();
                    expect(getFileInfo(tmpPath).size).toBeGT(0);
                    // PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A. Verifying these
                    // catches binary-encoding regressions where fileWrite turns
                    // the byte[] into a text-encoded blob.
                    var bytes = fileReadBinary(tmpPath);
                    expect(bytes[1]).toBe(-119);  // 0x89 as signed byte
                    expect(bytes[2]).toBe(80);    // P
                    expect(bytes[3]).toBe(78);    // N
                    expect(bytes[4]).toBe(71);    // G
                } finally {
                    if (fileExists(tmpPath)) fileDelete(tmpPath);
                }
            });

            it("screenshot with fullPage option writes a PNG file", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<div style='height:2000px'>Tall page</div>");
                var tmpPath = getTempDirectory() & "wheels-bc-fullpage-" & createUUID() & ".png";
                try {
                    variables.bc.screenshot(path=tmpPath, fullPage=true);
                    expect(fileExists(tmpPath)).toBeTrue();
                    expect(getFileInfo(tmpPath).size).toBeGT(0);
                } finally {
                    if (fileExists(tmpPath)) fileDelete(tmpPath);
                }
            });
        });

        describe("BrowserClient — additional negative-path + coverage gaps", () => {

            beforeEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx = variables.browser.newContext();
                variables.pg = variables.ctx.newPage();
                variables.bc = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl="", launcher=variables.launcher);
            });

            afterEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx.close();
            });

            // assertUrlIs — the most complex assertion; previously untested
            it("assertUrlIs with full URL passes when current URL matches exactly", () => {
                if (variables.skipBrowserTests) return;
                var dataUrl = "data:text/html,<h1>x</h1>";
                variables.bc.visitUrl(dataUrl);
                variables.bc.assertUrlIs(variables.bc.currentUrl());
            });

            it("assertUrlIs with full URL throws on mismatch", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>a</h1>");
                expect(() => variables.bc.assertUrlIs("data:text/html,<h1>b</h1>"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertUrlIs with leading-slash arg compares path only", () => {
                if (variables.skipBrowserTests) return;
                // Use page.evaluate to push a synthetic history entry so we
                // can test path extraction without a real HTTP server.
                variables.bc.visitUrl("data:text/html,<h1>x</h1>");
                // currentUrl() will be the data: URL — assertUrlIs("/path")
                // would extract the "path" from a data: URL and compare.
                // For data: URLs $pathFromUrl returns the full URL, so the
                // compare fails. That's correct behavior; verify it throws:
                expect(() => variables.bc.assertUrlIs("/some-path"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            // Negative paths on assertions that previously had positive-only tests
            it("assertDontSee throws when text IS on page", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>Welcome</h1>");
                expect(() => variables.bc.assertDontSee("Welcome"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertVisible throws when selector matches no visible elements", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='hidden' style='display:none'>");
                expect(() => variables.bc.assertVisible("##hidden"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertMissing throws when selector matches at least one element", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='here'>");
                expect(() => variables.bc.assertMissing("##here"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertInputValue throws on mismatch", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='e' value='actual'>");
                expect(() => variables.bc.assertInputValue("##e", "wrong"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertChecked throws when checkbox is unchecked", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<input id='cb' type='checkbox'>");
                expect(() => variables.bc.assertChecked("##cb"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            it("assertQueryStringHas throws when key missing", () => {
                if (variables.skipBrowserTests) return;
                variables.bc.visitUrl("data:text/html,<h1>x</h1>");
                expect(() => variables.bc.assertQueryStringHas("nope"))
                    .toThrow(type="Wheels.BrowserAssertionFailed");
            });

            // Previously untested method: pressEscape
            it("pressEscape(selector) dispatches Escape keypress", () => {
                if (variables.skipBrowserTests) return;
                var html = "<input id='i' onkeydown=""if(event.key==='Escape') document.getElementById('o').textContent='ESC'""><div id='o'></div>";
                variables.bc.visitUrl("data:text/html," & html);
                variables.bc.pressEscape("##i");
                expect(variables.pg.locator("##o").textContent()).toBe("ESC");
            });
        });

        describe("BrowserClient — cookies", () => {

            // Cookie operations require a real HTTP origin — data: URLs do not
            // support cookies. We detect the test server at http://localhost and
            // the port from CGI or default to 8080. Tests skip if no server is
            // reachable.

            beforeEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx = variables.browser.newContext();
                variables.pg = variables.ctx.newPage();
                // Detect the test server port from CGI (the request that runs
                // this spec is itself served by the test server).
                var testPort = cgi.server_port ?: "8080";
                variables.testBaseUrl = "http://localhost:" & testPort;
                variables.bc = new wheels.wheelstest.BrowserClient()
                    .init(page=variables.pg, context=variables.ctx, baseUrl=variables.testBaseUrl, launcher=variables.launcher);
            });

            afterEach(() => {
                if (variables.skipBrowserTests) return;
                variables.ctx.close();
            });

            it("setCookie sets a cookie and cookie() reads it back", () => {
                if (variables.skipBrowserTests) return;
                var testUrl = variables.bc.getBaseUrl();
                if (!len(testUrl)) return;
                variables.bc.visitUrl(testUrl);
                variables.bc.setCookie(name="testCookie", value="hello123", url=testUrl);
                var c = variables.bc.cookie("testCookie");
                expect(c.name).toBe("testCookie");
                expect(c.value).toBe("hello123");
            });

            it("deleteCookie removes a specific cookie", () => {
                if (variables.skipBrowserTests) return;
                var testUrl = variables.bc.getBaseUrl();
                if (!len(testUrl)) return;
                variables.bc.visitUrl(testUrl);
                variables.bc.setCookie(name="toDelete", value="bye", url=testUrl);
                var c = variables.bc.cookie("toDelete");
                expect(c.value).toBe("bye");
                variables.bc.deleteCookie("toDelete");
                expect(() => {
                    variables.bc.cookie("toDelete");
                }).toThrow("Wheels.BrowserAssertionFailed");
            });

            it("cookie() throws when cookie not found", () => {
                if (variables.skipBrowserTests) return;
                var testUrl = variables.bc.getBaseUrl();
                if (!len(testUrl)) return;
                variables.bc.visitUrl(testUrl);
                expect(() => {
                    variables.bc.cookie("nonexistent_cookie_xyz");
                }).toThrow("Wheels.BrowserAssertionFailed");
            });

            it("setCookie is chainable", () => {
                if (variables.skipBrowserTests) return;
                var testUrl = variables.bc.getBaseUrl();
                if (!len(testUrl)) return;
                variables.bc.visitUrl(testUrl);
                var result = variables.bc.setCookie(name="chain1", value="a", url=testUrl)
                    .setCookie(name="chain2", value="b", url=testUrl);
                expect(result).toBeInstanceOf("wheels.wheelstest.BrowserClient");
            });
        });
    }
}
