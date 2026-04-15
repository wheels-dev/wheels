/**
 * Self-test: exercises BrowserTest base class by extending it and
 * verifying the lifecycle hooks fire in the expected shape.
 *
 * Skips gracefully when Playwright JARs aren't installed (same pattern
 * as BrowserIntegrationSpec) so CI stays green without the install step.
 */
component extends="wheels.wheelstest.BrowserTest" {

    function run() {
        browserDescribe("BrowserTest lifecycle", () => {

            it("this.browser is populated before each it block", () => {
                if (this.browserTestSkipped) return;
                expect(isObject(this.browser)).toBeTrue();
            });

            it("this.browser exposes the full DSL (has getBaseUrl etc.)", () => {
                if (this.browserTestSkipped) return;
                // getBaseUrl / visit / assertSee etc. are the DSL API surface
                expect(this.browser.getBaseUrl()).toBeTypeOf("string");
            });

            it("each it gets a fresh Page (window globals don't leak)", () => {
                if (this.browserTestSkipped) return;
                // Data URLs disable localStorage/cookies, but window globals
                // work within a page. A fresh Page per it means fresh window.
                this.browser.visitUrl("data:text/html,<h1>set</h1>");
                this.browser.script("() => { window.myLeakProbe = 'leaked'; }");
                expect(this.browser.script("() => window.myLeakProbe || 'clean'")).toBe("leaked");
            });

            it("window global from previous it is not visible here", () => {
                if (this.browserTestSkipped) return;
                this.browser.visitUrl("data:text/html,<h1>check</h1>");
                expect(this.browser.script("() => window.myLeakProbe || 'clean'")).toBe("clean");
            });

            it("getBrowserLauncher() exposes the shared process-scoped launcher", () => {
                if (this.browserTestSkipped) return;
                var launcher = getBrowserLauncher();
                expect(isObject(launcher)).toBeTrue();
                expect(launcher.getState()).toBe("ready");
            });
        });
    }
}
