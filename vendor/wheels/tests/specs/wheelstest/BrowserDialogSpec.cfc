component extends="wheels.wheelstest.BrowserTest" {

    function run() {

        describe("Dialog handling", () => {

            browserDescribe("acceptDialog", () => {

                it("auto-accepts an alert dialog", () => {
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""alert('hello')"">Alert</button>")
                        .acceptDialog()
                        .click("##btn");
                    // If dialog wasn't accepted, Playwright would hang/timeout.
                    // Reaching here means the dialog was handled.
                    expect(true).toBeTrue();
                });

                it("captures the dialog message text", () => {
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""alert('test message')"">Alert</button>")
                        .acceptDialog()
                        .click("##btn");
                    expect(this.browser.dialogMessage()).toBe("test message");
                });

                it("accepts a confirm dialog returning true", () => {
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=confirm('sure?')"">Confirm</button><span id='r'></span>")
                        .acceptDialog()
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("true");
                });

                it("sends text to a prompt dialog", () => {
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=prompt('name?')"">Prompt</button><span id='r'></span>")
                        .acceptDialog(text="Claude")
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("Claude");
                });

            });

            browserDescribe("dismissDialog", () => {

                it("dismisses a confirm dialog returning false", () => {
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=confirm('sure?')"">Confirm</button><span id='r'></span>")
                        .dismissDialog()
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("false");
                });

                it("dismisses a prompt returning null", () => {
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=String(prompt('name?'))"">Prompt</button><span id='r'></span>")
                        .dismissDialog()
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("null");
                });

            });

            browserDescribe("dialog with press()", () => {

                it("handles dialog triggered by press()", () => {
                    this.browser
                        .visitUrl("data:text/html,<button onclick=""alert('pressed')"">Click me</button>")
                        .acceptDialog()
                        .press("Click me");
                    expect(this.browser.dialogMessage()).toBe("pressed");
                });

            });

            browserDescribe("dialog with keys()", () => {

                it("handles dialog triggered by keys()", () => {
                    this.browser
                        .visitUrl("data:text/html,<input id='inp' onkeydown=""if(event.key==='Enter')alert('enter pressed')"">")
                        .acceptDialog()
                        .keys("##inp", "Enter");
                    expect(this.browser.dialogMessage()).toBe("enter pressed");
                });

            });

            browserDescribe("dialogMessage", () => {

                it("returns empty string when no dialog has fired", () => {
                    this.browser
                        .visitUrl("data:text/html,<p>no dialog</p>");
                    expect(this.browser.dialogMessage()).toBe("");
                });

            });

            browserDescribe("listener detach", () => {

                it("second dialog in the same it block is handled by the new action, not a stale listener", () => {
                    // $clearDialogListener must offDialog() the previous
                    // listener — otherwise the first (accept) listener stays
                    // attached to the Page and handles the second dialog
                    // before the dismiss listener gets a chance.
                    this.browser
                        .visitUrl("data:text/html,<button id='b1' onclick=""document.getElementById('r1').textContent=confirm('first?')"">One</button><button id='b2' onclick=""document.getElementById('r2').textContent=confirm('second?')"">Two</button><span id='r1'></span><span id='r2'></span>");
                    this.browser.acceptDialog().click("##b1");
                    expect(this.browser.text("##r1")).toBe("true");
                    this.browser.dismissDialog().click("##b2");
                    expect(this.browser.text("##r2")).toBe("false");
                });

            });

        });

    }
}
