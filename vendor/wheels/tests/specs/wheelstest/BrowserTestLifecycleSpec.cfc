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
                expect(isObject(this.browser)).toBeTrue();
            });

            it("this.browser exposes the full DSL (has getBaseUrl etc.)", () => {
                // getBaseUrl / visit / assertSee etc. are the DSL API surface
                expect(this.browser.getBaseUrl()).toBeTypeOf("string");
            });

            it("each it gets a fresh Page (window globals don't leak)", () => {
                // Data URLs disable localStorage/cookies, but window globals
                // work within a page. A fresh Page per it means fresh window.
                this.browser.visitUrl("data:text/html,<h1>set</h1>");
                this.browser.script("() => { window.myLeakProbe = 'leaked'; }");
                expect(this.browser.script("() => window.myLeakProbe || 'clean'")).toBe("leaked");
            });

            it("window global from previous it is not visible here", () => {
                this.browser.visitUrl("data:text/html,<h1>check</h1>");
                expect(this.browser.script("() => window.myLeakProbe || 'clean'")).toBe("clean");
            });

            it("getBrowserLauncher() exposes the shared process-scoped launcher", () => {
                var launcher = getBrowserLauncher();
                expect(isObject(launcher)).toBeTrue();
                expect(launcher.getState()).toBe("ready");
            });
        });

        browserDescribe("viewport config", () => {

            it("applies mobile viewport preset when this.browserViewport is set", () => {
                var original = this.browserViewport ?: "";
                this.browserViewport = "mobile";

                this.$endBrowserContext();
                this.$startBrowserContext();

                this.browser.visitUrl("data:text/html,<h1>Test</h1>");
                var width = this.browser.script("() => window.innerWidth");
                expect(width).toBe(375);

                this.browserViewport = original;
                this.$endBrowserContext();
                this.$startBrowserContext();
            });

            it("applies custom viewport dimensions from struct", () => {
                var original = this.browserViewport ?: "";
                this.browserViewport = {width: 800, height: 600};

                this.$endBrowserContext();
                this.$startBrowserContext();

                this.browser.visitUrl("data:text/html,<h1>Test</h1>");
                var width = this.browser.script("() => window.innerWidth");
                expect(width).toBe(800);

                this.browserViewport = original;
                this.$endBrowserContext();
                this.$startBrowserContext();
            });

        });

        browserDescribe("auto-screenshot on failure", () => {

            it("$captureFailureArtifacts writes screenshot and HTML", () => {
                this.browser.visitUrl("data:text/html,<h1>Capture Me</h1>");

                var testDir = expandPath("/tests/_output/browser_capture_test");
                this.browserArtifactPath = testDir;

                var fakeSpec = {name: "test_capture_verification"};
                this.$captureFailureArtifacts(fakeSpec);

                expect(directoryExists(testDir)).toBeTrue();
                var files = directoryList(testDir, false, "name");
                var hasPng = false;
                var hasHtml = false;
                for (var f in files) {
                    if (findNoCase(".png", f)) hasPng = true;
                    if (findNoCase(".html", f)) hasHtml = true;
                }
                expect(hasPng).toBeTrue();
                expect(hasHtml).toBeTrue();

                directoryDelete(testDir, true);
                structDelete(this, "browserArtifactPath");
            });

            it("respects browserScreenshotOnFailure=false", () => {
                this.browser.visitUrl("data:text/html,<h1>No Capture</h1>");

                var testDir = expandPath("/tests/_output/browser_optout_test");
                this.browserArtifactPath = testDir;
                this.browserScreenshotOnFailure = false;

                var fakeSpec = {name: "test_optout"};
                this.$captureFailureArtifacts(fakeSpec);

                expect(directoryExists(testDir)).toBeFalse();

                this.browserScreenshotOnFailure = true;
                structDelete(this, "browserArtifactPath");
            });

        });
    }
}
