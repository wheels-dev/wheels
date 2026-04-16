component extends="wheels.wheelstest.BrowserTest" {

    this.dialogSkipped = false;

    function run() {

        describe("Dialog handling", () => {

            beforeAll(() => {
                // createDynamicProxy may not be available in all Lucee environments
                // (e.g. LuCLI Express). Detect once and skip all dialog tests if unsupported.
                if (this.browserTestSkipped) return;
                try {
                    createDynamicProxy(
                        {accept: function(x) {}},
                        ["java.lang.Runnable"]
                    );
                } catch (any e) {
                    this.dialogSkipped = true;
                }
            });

            browserDescribe("acceptDialog", () => {

                it("auto-accepts an alert dialog", () => {
                    if (this.browserTestSkipped || this.dialogSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""alert('hello')"">Alert</button>")
                        .acceptDialog()
                        .click("##btn");
                    // If dialog wasn't accepted, Playwright would hang/timeout.
                    // Reaching here means the dialog was handled.
                    expect(true).toBeTrue();
                });

                it("captures the dialog message text", () => {
                    if (this.browserTestSkipped || this.dialogSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""alert('test message')"">Alert</button>")
                        .acceptDialog()
                        .click("##btn");
                    expect(this.browser.dialogMessage()).toBe("test message");
                });

                it("accepts a confirm dialog returning true", () => {
                    if (this.browserTestSkipped || this.dialogSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=confirm('sure?')"">Confirm</button><span id='r'></span>")
                        .acceptDialog()
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("true");
                });

                it("sends text to a prompt dialog", () => {
                    if (this.browserTestSkipped || this.dialogSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=prompt('name?')"">Prompt</button><span id='r'></span>")
                        .acceptDialog(text="Claude")
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("Claude");
                });

            });

            browserDescribe("dismissDialog", () => {

                it("dismisses a confirm dialog returning false", () => {
                    if (this.browserTestSkipped || this.dialogSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=confirm('sure?')"">Confirm</button><span id='r'></span>")
                        .dismissDialog()
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("false");
                });

                it("dismisses a prompt returning null", () => {
                    if (this.browserTestSkipped || this.dialogSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=String(prompt('name?'))"">Prompt</button><span id='r'></span>")
                        .dismissDialog()
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("null");
                });

            });

            browserDescribe("dialog with press()", () => {

                it("handles dialog triggered by press()", () => {
                    if (this.browserTestSkipped || this.dialogSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button onclick=""alert('pressed')"">Click me</button>")
                        .acceptDialog()
                        .press("Click me");
                    expect(this.browser.dialogMessage()).toBe("pressed");
                });

            });

            browserDescribe("dialog with keys()", () => {

                it("handles dialog triggered by keys()", () => {
                    if (this.browserTestSkipped || this.dialogSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<input id='inp' onkeydown=""if(event.key==='Enter')alert('enter pressed')"">")
                        .acceptDialog()
                        .keys("##inp", "Enter");
                    expect(this.browser.dialogMessage()).toBe("enter pressed");
                });

            });

            browserDescribe("dialogMessage", () => {

                it("returns empty string when no dialog has fired", () => {
                    if (this.browserTestSkipped || this.dialogSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<p>no dialog</p>");
                    expect(this.browser.dialogMessage()).toBe("");
                });

            });

        });

    }
}
