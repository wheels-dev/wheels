component extends="wheels.wheelstest.BrowserTest" {

    function run() {

        describe("Route navigation (fixture server)", () => {

            browserDescribe("visitRoute", () => {

                it("navigates to a named route", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitRoute(route="browserTestHome")
                        .assertSee("Welcome to the browser test fixture");
                });

                it("navigates to dashboard route", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .loginAs("alice@example.com")
                        .visitRoute(route="browserTestDashboard")
                        .assertSee("Dashboard");
                });

            });

            browserDescribe("assertRouteIs", () => {

                it("passes when on the correct route", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitRoute(route="browserTestHome")
                        .assertRouteIs(route="browserTestHome");
                });

                it("fails with descriptive message when on wrong route", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitRoute(route="browserTestHome");
                    try {
                        this.browser.assertRouteIs(route="browserTestDashboard");
                        fail("Expected assertRouteIs to throw");
                    } catch (Wheels.BrowserAssertionFailed e) {
                        expect(e.message).toInclude("browserTestDashboard");
                        expect(e.message).toInclude("/_browser/dashboard");
                    }
                });

            });

            browserDescribe("$resolveRoute", () => {

                it("resolves a named route to a path", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitRoute(route="browserTestLogin")
                        .assertUrlContains("/_browser/login");
                });

            });

        });

    }
}
