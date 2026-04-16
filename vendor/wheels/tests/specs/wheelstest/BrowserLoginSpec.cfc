component extends="wheels.wheelstest.BrowserTest" {

    function run() {

        describe("loginAs + logout (fixture server)", () => {

            browserDescribe("loginAs", () => {

                it("sets session and shows login confirmation", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .loginAs("alice@example.com")
                        .assertSee("Logged in as");
                });

                it("allows access to protected dashboard after loginAs", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .loginAs("alice@example.com")
                        .visit("/_browser/dashboard")
                        .assertSee("Dashboard")
                        .assertSee("alice@example.com");
                });

                it("works with arbitrary identifiers", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .loginAs("bob@example.com")
                        .visit("/_browser/dashboard")
                        .assertSee("bob@example.com");
                });

            });

            browserDescribe("logout", () => {

                it("clears session and redirects to login on protected page", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .loginAs("alice@example.com")
                        .visit("/_browser/dashboard")
                        .assertSee("Dashboard")
                        .logout()
                        .visit("/_browser/dashboard");
                    // After logout, visiting dashboard should redirect to login
                    this.browser
                        .assertSee("Log in");
                });

            });

            browserDescribe("full login flow (form-based)", () => {

                it("logs in via form submission", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visit("/_browser/login")
                        .assertSee("Log in")
                        .fill("##email", "alice@example.com")
                        .fill("##password", "secret")
                        .press("Sign in")
                        .assertSee("Dashboard")
                        .assertSee("alice@example.com");
                });

                it("shows error on invalid credentials", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visit("/_browser/login")
                        .fill("##email", "wrong@example.com")
                        .fill("##password", "wrong")
                        .press("Sign in")
                        .assertSee("Invalid credentials");
                });

                it("redirects to login when accessing protected page", () => {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visit("/_browser/dashboard")
                        .assertSee("Log in")
                        .assertUrlContains("login");
                });

            });

        });

    }
}
