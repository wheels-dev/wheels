/**
 * Self-test for the unwired-this.browser guard. A BrowserTest subclass
 * that uses plain describe() (instead of browserDescribe()) must surface
 * a clear "use browserDescribe()" error when any method is invoked on
 * this.browser — not "function [visitUrl] does not exist in the String".
 */
component extends="wheels.WheelsTest" {

    function run() {
        describe("BrowserTest unwired this.browser guard", () => {

            it("throws Wheels.BrowserTest.NotWired when a DSL method is called before browserDescribe wiring", () => {
                var spec = new wheels.wheelstest.BrowserTest();
                expect(function() {
                    spec.browser.visitUrl("data:text/html,<h1>Hi</h1>");
                }).toThrow(type="Wheels.BrowserTest.NotWired");
            });

            it("error message names browserDescribe() so users see the fix", () => {
                var spec = new wheels.wheelstest.BrowserTest();
                var state = {message: "", detail: ""};

                try {
                    spec.browser.assertSee("anything");
                } catch (Wheels.BrowserTest.NotWired e) {
                    state.message = e.message;
                    state.detail = e.detail;
                }

                expect(state.message).toInclude("browserDescribe");
                expect(state.detail).toInclude("assertSee");
            });

            it("$startBrowserContext() throws Wheels.BrowserTest.NotWired when no Browser was acquired", () => {
                // Simulates a spec that overrides beforeAll() without calling
                // super.beforeAll(): $browser stays an empty string, and the
                // guard must surface a clear error instead of the cryptic
                // "function [newContext] does not exist in the String".
                var spec = new wheels.wheelstest.BrowserTest();
                expect(function() {
                    spec.$startBrowserContext();
                }).toThrow(type="Wheels.BrowserTest.NotWired");
            });

            it("$startBrowserContext() guard message points at super.beforeAll()", () => {
                var spec = new wheels.wheelstest.BrowserTest();
                var state = {message: ""};

                try {
                    spec.$startBrowserContext();
                } catch (Wheels.BrowserTest.NotWired e) {
                    state.message = e.message;
                }

                expect(state.message).toInclude("super.beforeAll()");
            });

        });
    }
}
