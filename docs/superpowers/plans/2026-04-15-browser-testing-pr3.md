# Browser Testing PR 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add loginAs/logout DSL, dialog handling, visitRoute/assertRouteIs, and fixture route mounting to the Wheels browser testing framework.

**Architecture:** Mount fixture controllers under `/_browser/` prefix in the main app (env-gated to testing). loginAs uses a GET endpoint for simplicity. Dialogs use Lucee's `createDynamicProxy` to implement `Consumer<Dialog>`. Route resolution calls `application.wo.URLFor()` directly.

**Tech Stack:** CFML (Lucee), Playwright Java 1.52, TestBox BDD, createDynamicProxy

---

### Task 1: Fixture Controllers + Views + Layout

Create the BrowserTest fixture controllers and views in the main app directory. These are test-only controllers with a `BrowserTest` prefix.

**Files:**
- Create: `app/controllers/BrowserTestHome.cfc`
- Create: `app/controllers/BrowserTestSessions.cfc`
- Create: `app/views/browsertesthome/index.cfm`
- Create: `app/views/browsertesthome/dashboard.cfm`
- Create: `app/views/browsertesthome/layout.cfm`
- Create: `app/views/browsertestsessions/new.cfm`
- Create: `app/views/browsertestsessions/layout.cfm`

- [ ] **Step 1: Create BrowserTestHome controller**

```cfm
// app/controllers/BrowserTestHome.cfc
component extends="Controller" {

    function config() {
        filters(through="$requireLogin", except="index");
    }

    function index() {
    }

    function dashboard() {
        user = {email: session.userEmail ?: ""};
    }

    private function $requireLogin() {
        if (!structKeyExists(session, "userId")) {
            redirectTo(route="browserTestLogin");
        }
    }
}
```

- [ ] **Step 2: Create BrowserTestSessions controller**

```cfm
// app/controllers/BrowserTestSessions.cfc
component extends="Controller" {

    function new() {
        flashError = flash("error") ?: "";
    }

    function create() {
        if (params.email == "alice@example.com" && params.password == "secret") {
            session.userId = 1;
            session.userEmail = params.email;
            redirectTo(route="browserTestDashboard");
        } else {
            flashInsert(error="Invalid credentials");
            redirectTo(route="browserTestLogin");
        }
    }

    function destroy() {
        structClear(session);
        redirectTo(route="browserTestLogin");
    }
}
```

- [ ] **Step 3: Create shared layout**

```cfm
// app/views/browsertesthome/layout.cfm
<cfoutput>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Browser Test Fixture</title>
</head>
<body>
    #contentForLayout()#
</body>
</html>
</cfoutput>
```

Copy the same layout for the sessions controller:

```cfm
// app/views/browsertestsessions/layout.cfm
<cfoutput>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Browser Test Fixture</title>
</head>
<body>
    #contentForLayout()#
</body>
</html>
</cfoutput>
```

- [ ] **Step 4: Create home views**

```cfm
// app/views/browsertesthome/index.cfm
<cfoutput>
<h1>Home</h1>
<p>Welcome to the browser test fixture app.</p>
<a href="#urlFor(route='browserTestLogin')#">Log in</a>
</cfoutput>
```

```cfm
// app/views/browsertesthome/dashboard.cfm
<cfparam name="user" default="#{}#">
<cfoutput>
<h1>Dashboard</h1>
<p>Welcome, <span id="user-email">#encodeForHTML(user.email)#</span></p>
<form method="post" action="#urlFor(route='browserTestLogout')#">
    <button type="submit">Log out</button>
</form>
</cfoutput>
```

- [ ] **Step 5: Create login view**

```cfm
// app/views/browsertestsessions/new.cfm
<cfparam name="flashError" default="">
<cfoutput>
<h1>Log in</h1>
<cfif len(flashError)>
    <div class="error" id="error-message">#flashError#</div>
</cfif>
<form method="post" action="#urlFor(route='browserTestAuthenticate')#">
    <label for="email">Email</label>
    <input type="email" name="email" id="email">
    <label for="password">Password</label>
    <input type="password" name="password" id="password">
    <button type="submit">Sign in</button>
</form>
</cfoutput>
```

- [ ] **Step 6: Commit**

```bash
git add app/controllers/BrowserTestHome.cfc app/controllers/BrowserTestSessions.cfc \
       app/views/browsertesthome/ app/views/browsertestsessions/
git commit -m "feat(test): add browser test fixture controllers and views"
```

---

### Task 2: loginAs Controller + Route Registration

Add the test-only loginAs endpoint and register all `/_browser/` routes in `config/routes.cfm`.

**Files:**
- Create: `app/controllers/BrowserTestLogin.cfc`
- Create: `app/views/browsertestlogin/create.cfm`
- Create: `app/views/browsertestlogin/layout.cfm`
- Modify: `config/routes.cfm`

- [ ] **Step 1: Create BrowserTestLogin controller**

```cfm
// app/controllers/BrowserTestLogin.cfc
component extends="Controller" {

    function config() {
    }

    function create() {
        if (application.$wheels.environment != "testing") {
            throw(
                type="Wheels.BrowserTestSecurityError",
                message="loginAs endpoint is only available in testing environment"
            );
        }

        session.userId = 1;
        session.userEmail = params.identifier;
    }
}
```

- [ ] **Step 2: Create loginAs view**

```cfm
// app/views/browsertestlogin/create.cfm
<cfparam name="params" default="#{}#">
<cfoutput>
<p id="login-status">Logged in as #encodeForHTML(params.identifier ?: "unknown")#</p>
</cfoutput>
```

```cfm
// app/views/browsertestlogin/layout.cfm
<cfoutput>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Browser Test Fixture</title>
</head>
<body>
    #contentForLayout()#
</body>
</html>
</cfoutput>
```

- [ ] **Step 3: Register /_browser/ routes in config/routes.cfm**

The routes must go BEFORE `.wildcard()` and be env-gated. Insert them right after the `// CLI-Appends-Here` comment:

```cfm
// config/routes.cfm
<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://wheels.dev/3.1.0/guides/handling-requests-with-controllers/routing for more info.

	mapper()
		// CLI-Appends-Here

		// Browser test fixture routes — only available in testing environment
		.scope(path="/_browser", $call="scope")
			.get(name="browserTestHome", pattern="/home", to="BrowserTestHome##index")
			.get(name="browserTestLogin", pattern="/login", to="BrowserTestSessions##new")
			.post(name="browserTestAuthenticate", pattern="/login", to="BrowserTestSessions##create")
			.get(name="browserTestDashboard", pattern="/dashboard", to="BrowserTestHome##dashboard")
			.post(name="browserTestLogout", pattern="/logout", to="BrowserTestSessions##destroy")
			.get(name="browserTestLoginAs", pattern="/login-as", to="BrowserTestLogin##create")
		.end()

		// The "wildcard" call below enables automatic mapping of "controller/action" type routes.
		// This way you don't need to explicitly add a route every time you create a new action in a controller.
		.wildcard()

		// The root route below is the one that will be called on your application's home page (e.g. http://127.0.0.1/).
		//.root(to = "home##index", method = "get")
		.root(method = "get")
	.end();
</cfscript>
```

Note: The routes are always registered (not env-gated in routes.cfm) because routes.cfm runs before the environment is fully available in some bootstrap paths. The security gate is in the `BrowserTestLogin.cfc` controller itself (`application.$wheels.environment != "testing"` check). The other fixture controllers (Home, Sessions) are harmless — they just serve static pages.

- [ ] **Step 4: Verify routes register correctly**

Run:
```bash
bash tools/test-local.sh
```

After the server starts, test that the fixture routes respond:
```bash
curl -s "http://localhost:8080/_browser/home" | grep -o "browser test fixture"
```

Expected: `browser test fixture` (from the home page view)

- [ ] **Step 5: Commit**

```bash
git add app/controllers/BrowserTestLogin.cfc app/views/browsertestlogin/ config/routes.cfm
git commit -m "feat(test): add loginAs controller and browser test routes"
```

---

### Task 3: loginAs + logout on BrowserClient

Add `loginAs()`, `logout()`, and `clearCookies()` methods to BrowserClient.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`

- [ ] **Step 1: Add loginAs, logout, and clearCookies methods**

Add these methods to BrowserClient.cfc in a new section between the Cookies section and the Assertions section:

```cfm
// ─── Auth ────────────────────────────────────────────────────────

/**
 * Logs in as the given identifier by navigating to the test-only
 * /_browser/login-as endpoint. Sets session.userId and session.userEmail
 * on the server side. Only available when the Wheels app is in testing mode.
 *
 *     this.browser.loginAs("alice@example.com")
 *                 .visit("/_browser/dashboard")
 *                 .assertSee("alice@example.com");
 */
public BrowserClient function loginAs(required string identifier) {
    visit("/_browser/login-as?identifier=" & encodeForURL(arguments.identifier));
    return this;
}

/**
 * Logs out by clearing all cookies on the browser context and navigating
 * to the fixture home page to reset page state. For testing the logout UI
 * flow (click button, see redirect), use click()/press() directly instead.
 */
public BrowserClient function logout() {
    variables.context.clearCookies();
    visit("/_browser/home");
    return this;
}

/**
 * Clears all cookies on the browser context. Unlike deleteCookie(name)
 * which targets a single cookie, this removes everything — session,
 * tracking, etc.
 */
public BrowserClient function clearCookies() {
    variables.context.clearCookies();
    return this;
}
```

- [ ] **Step 2: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc
git commit -m "feat(test): add loginAs, logout, clearCookies to BrowserClient"
```

---

### Task 4: loginAs + logout Test Spec

Write the test spec for loginAs/logout. These tests require the fixture server (main app running on localhost:8080).

**Files:**
- Create: `vendor/wheels/tests/specs/wheelstest/BrowserLoginSpec.cfc`

- [ ] **Step 1: Write BrowserLoginSpec**

```cfm
// vendor/wheels/tests/specs/wheelstest/BrowserLoginSpec.cfc
component extends="wheels.wheelstest.BrowserTest" {

    function run() {

        describe("loginAs + logout (fixture server)", () -> {

            browserDescribe("loginAs", () -> {

                it("sets session and shows login confirmation", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .loginAs("alice@example.com")
                        .assertSee("Logged in as");
                });

                it("allows access to protected dashboard after loginAs", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .loginAs("alice@example.com")
                        .visit("/_browser/dashboard")
                        .assertSee("Dashboard")
                        .assertSee("alice@example.com");
                });

                it("works with arbitrary identifiers", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .loginAs("bob@example.com")
                        .visit("/_browser/dashboard")
                        .assertSee("bob@example.com");
                });

            });

            browserDescribe("logout", () -> {

                it("clears session and redirects to login on protected page", () -> {
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

            browserDescribe("full login flow (form-based)", () -> {

                it("logs in via form submission", () -> {
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

                it("shows error on invalid credentials", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visit("/_browser/login")
                        .fill("##email", "wrong@example.com")
                        .fill("##password", "wrong")
                        .press("Sign in")
                        .assertSee("Invalid credentials");
                });

                it("redirects to login when accessing protected page", () -> {
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
```

- [ ] **Step 2: Run the tests**

Run:
```bash
bash tools/test-local.sh
```

Expected: All tests pass (or skip gracefully if Playwright JARs not installed).

To run just the browser test specs:
```bash
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.wheelstest&reload=true" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```

- [ ] **Step 3: Commit**

```bash
git add vendor/wheels/tests/specs/wheelstest/BrowserLoginSpec.cfc
git commit -m "test(test): add loginAs, logout, and login flow browser specs"
```

---

### Task 5: Dialog State + Engine Gate on BrowserClient

Add dialog state variables, engine gate, and the `acceptDialog`/`dismissDialog`/`dialogMessage` public API to BrowserClient. This task adds the API surface; Task 6 wires it into interaction methods.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`

- [ ] **Step 1: Add dialog state variables to init()**

In `BrowserClient.cfc`, add these variables declarations right after the existing `variables.$launcher = "";` line:

```cfm
variables.$pendingDialogAction = "";
variables.$lastDialogMessage = "";
variables.$dialogProxy = "";
variables.$dialogState = "";
variables.$dialogSupported = "";
```

- [ ] **Step 2: Add dialog public API methods**

Add a new section between the Cookies section and the Auth section:

```cfm
// ─── Dialogs ─────────────────────────────────────────────────────

/**
 * Registers intent to accept the next JavaScript dialog (alert, confirm,
 * prompt). Must be called BEFORE the interaction that triggers the dialog.
 * The optional `text` argument provides input for prompt() dialogs.
 *
 *     this.browser.acceptDialog().click("##delete-btn")
 *     this.browser.acceptDialog(text="yes").click("##confirm-btn")
 */
public BrowserClient function acceptDialog(string text = "") {
    $requireDialogSupport();
    variables.$pendingDialogAction = {type: "accept", text: arguments.text};
    return this;
}

/**
 * Registers intent to dismiss the next JavaScript dialog. Must be called
 * BEFORE the interaction that triggers the dialog.
 *
 *     this.browser.dismissDialog().click("##cancel-btn")
 */
public BrowserClient function dismissDialog() {
    $requireDialogSupport();
    variables.$pendingDialogAction = {type: "dismiss", text: ""};
    return this;
}

/**
 * Returns the message text from the last dialog that was handled by
 * acceptDialog() or dismissDialog(). Terminal — not chainable.
 *
 *     this.browser.acceptDialog().click("##alert-btn");
 *     var msg = this.browser.dialogMessage();
 */
public string function dialogMessage() {
    return variables.$lastDialogMessage;
}
```

- [ ] **Step 3: Add dialog internal helpers**

Add these private methods in the Internal helpers section:

```cfm
/**
 * Checks that the current engine supports createDynamicProxy (Lucee-only).
 * Caches the result so the check only runs once per BrowserClient instance.
 */
private void function $requireDialogSupport() {
    if (isBoolean(variables.$dialogSupported) && variables.$dialogSupported) return;
    if (isBoolean(variables.$dialogSupported) && !variables.$dialogSupported) {
        throw(
            type="Wheels.BrowserDialogNotSupported",
            message="Dialog handling requires Lucee. This engine does not support createDynamicProxy."
        );
    }
    try {
        createDynamicProxy(
            {accept: function(x) {}},
            ["java.lang.Runnable"]
        );
        variables.$dialogSupported = true;
    } catch (any e) {
        variables.$dialogSupported = false;
        throw(
            type="Wheels.BrowserDialogNotSupported",
            message="Dialog handling requires Lucee. This engine does not support createDynamicProxy."
        );
    }
}

/**
 * Registers a one-shot Consumer<Dialog> listener on the page. Called
 * by dialog-aware interaction methods (click, press, keys) when
 * $pendingDialogAction is set.
 */
public void function $registerDialogListener() {
    if (!isStruct(variables.$pendingDialogAction)) return;

    var action = variables.$pendingDialogAction;
    var state = {lastMessage: "", handled: false};
    variables.$dialogState = state;

    var handler = {
        accept: function(dialog) {
            state.lastMessage = dialog.message();
            state.handled = true;
            if (action.type == "accept") {
                if (len(action.text)) {
                    dialog.accept(action.text);
                } else {
                    dialog.accept();
                }
            } else {
                dialog.dismiss();
            }
        }
    };

    variables.$dialogProxy = createDynamicProxy(handler, ["java.util.function.Consumer"]);
    variables.page.onDialog(variables.$dialogProxy);
}

/**
 * Cleans up after a dialog interaction. Copies the dialog message to
 * $lastDialogMessage and resets pending state. Called by dialog-aware
 * interaction methods after the Playwright action completes.
 */
public void function $clearDialogListener() {
    if (isStruct(variables.$dialogState)) {
        variables.$lastDialogMessage = variables.$dialogState.lastMessage ?: "";
    }
    variables.$pendingDialogAction = "";
    variables.$dialogProxy = "";
    variables.$dialogState = "";
}
```

- [ ] **Step 4: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc
git commit -m "feat(test): add dialog state, engine gate, and public API to BrowserClient"
```

---

### Task 6: Wire Dialog Handling into Interaction Methods

Modify `click()`, `press()`, and `keys()` to check for pending dialog actions and register/clear the listener around the Playwright interaction.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`

- [ ] **Step 1: Replace click() method**

Replace the existing `click()` method:

```cfm
public BrowserClient function click(required string selector) {
    if (isStruct(variables.$pendingDialogAction)) {
        $registerDialogListener();
    }
    $locator(arguments.selector).click();
    if (isStruct(variables.$pendingDialogAction)) {
        $clearDialogListener();
    }
    return this;
}
```

- [ ] **Step 2: Replace press() method**

Replace the existing `press()` method:

```cfm
/**
 * Clicks the first element matching the given visible text. Simpler than
 * getByRole because it avoids building Playwright option objects through
 * the URLClassLoader. If you need role-specific matching (e.g. button
 * only, ignoring headings), use click("button:has-text('...')") instead.
 */
public BrowserClient function press(required string buttonText) {
    if (isStruct(variables.$pendingDialogAction)) {
        $registerDialogListener();
    }
    variables.page.getByText(arguments.buttonText).first().click();
    if (isStruct(variables.$pendingDialogAction)) {
        $clearDialogListener();
    }
    return this;
}
```

- [ ] **Step 3: Replace keys() method**

Replace the existing `keys()` method:

```cfm
/**
 * Press a keyboard key against the element matching `selector`.
 * Key syntax follows Playwright: "Enter", "Tab", "Escape",
 * "Control+A", "Shift+Home", etc.
 */
public BrowserClient function keys(
    required string selector,
    required string key
) {
    if (isStruct(variables.$pendingDialogAction)) {
        $registerDialogListener();
    }
    $locator(arguments.selector).press(arguments.key);
    if (isStruct(variables.$pendingDialogAction)) {
        $clearDialogListener();
    }
    return this;
}
```

- [ ] **Step 4: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc
git commit -m "feat(test): wire dialog handling into click, press, keys methods"
```

---

### Task 7: Dialog Test Spec

Write the test spec for dialog handling. Dialog tests use data: URLs — no fixture server needed.

**Files:**
- Create: `vendor/wheels/tests/specs/wheelstest/BrowserDialogSpec.cfc`

- [ ] **Step 1: Write BrowserDialogSpec**

```cfm
// vendor/wheels/tests/specs/wheelstest/BrowserDialogSpec.cfc
component extends="wheels.wheelstest.BrowserTest" {

    function run() {

        describe("Dialog handling", () -> {

            browserDescribe("acceptDialog", () -> {

                it("auto-accepts an alert dialog", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""alert('hello')"">Alert</button>")
                        .acceptDialog()
                        .click("##btn");
                    // If dialog wasn't accepted, Playwright would hang/timeout.
                    // Reaching here means the dialog was handled.
                    expect(true).toBeTrue();
                });

                it("captures the dialog message text", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""alert('test message')"">Alert</button>")
                        .acceptDialog()
                        .click("##btn");
                    expect(this.browser.dialogMessage()).toBe("test message");
                });

                it("accepts a confirm dialog returning true", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=confirm('sure?')"">Confirm</button><span id='r'></span>")
                        .acceptDialog()
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("true");
                });

                it("sends text to a prompt dialog", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=prompt('name?')"">Prompt</button><span id='r'></span>")
                        .acceptDialog(text="Claude")
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("Claude");
                });

            });

            browserDescribe("dismissDialog", () -> {

                it("dismisses a confirm dialog returning false", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=confirm('sure?')"">Confirm</button><span id='r'></span>")
                        .dismissDialog()
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("false");
                });

                it("dismisses a prompt returning null", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button id='btn' onclick=""document.getElementById('r').textContent=String(prompt('name?'))"">Prompt</button><span id='r'></span>")
                        .dismissDialog()
                        .click("##btn");
                    expect(this.browser.text("##r")).toBe("null");
                });

            });

            browserDescribe("dialog with press()", () -> {

                it("handles dialog triggered by press()", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<button onclick=""alert('pressed')"">Click me</button>")
                        .acceptDialog()
                        .press("Click me");
                    expect(this.browser.dialogMessage()).toBe("pressed");
                });

            });

            browserDescribe("dialog with keys()", () -> {

                it("handles dialog triggered by keys()", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<input id='inp' onkeydown=""if(event.key==='Enter')alert('enter pressed')"">")
                        .acceptDialog()
                        .keys("##inp", "Enter");
                    expect(this.browser.dialogMessage()).toBe("enter pressed");
                });

            });

            browserDescribe("dialogMessage", () -> {

                it("returns empty string when no dialog has fired", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitUrl("data:text/html,<p>no dialog</p>");
                    expect(this.browser.dialogMessage()).toBe("");
                });

            });

        });

    }
}
```

- [ ] **Step 2: Run dialog tests**

Run:
```bash
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.wheelstest&reload=true" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```

Expected: All dialog tests pass on Lucee. The key indicator is that `acceptDialog().click()` doesn't hang — if the dialog listener isn't registered, Playwright will timeout waiting for the dialog to be dismissed.

- [ ] **Step 3: Commit**

```bash
git add vendor/wheels/tests/specs/wheelstest/BrowserDialogSpec.cfc
git commit -m "test(test): add dialog handling browser specs"
```

---

### Task 8: visitRoute + assertRouteIs on BrowserClient

Add route-aware navigation and assertion methods to BrowserClient.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`

- [ ] **Step 1: Add visitRoute, assertRouteIs, and $resolveRoute methods**

Add a new section between the Navigation section and the Interaction section:

```cfm
// ─── Route Navigation ───────────────────────────────────────────

/**
 * Navigates to a named route by resolving it through application.wo.URLFor().
 * Requires the Wheels app to be running (routes must be loaded).
 *
 *     this.browser.visitRoute(route="browserTestDashboard")
 *     this.browser.visitRoute(route="user", key=42)
 */
public BrowserClient function visitRoute(
    required string route,
    any key = "",
    string params = ""
) {
    var path = $resolveRoute(argumentCollection=arguments);
    return visit(path);
}

/**
 * Asserts that the current page URL matches the given named route.
 * Compares path portions only (ignores protocol, host, port).
 *
 *     this.browser.visitRoute(route="browserTestDashboard")
 *                 .assertRouteIs(route="browserTestDashboard")
 */
public BrowserClient function assertRouteIs(
    required string route,
    any key = "",
    string params = ""
) {
    var expectedPath = $resolveRoute(argumentCollection=arguments);
    var actualPath = $pathFromUrl(currentUrl());
    if (actualPath != expectedPath) {
        $assertFail("Expected route '" & arguments.route & "' (" & expectedPath
            & ") but was at " & actualPath);
    }
    return this;
}

/**
 * Resolves a named route to a URL path using application.wo.URLFor().
 * Ensures request.wheels.urlForCache exists (required by URLFor internals).
 */
private string function $resolveRoute(
    required string route,
    any key = "",
    string params = ""
) {
    if (!structKeyExists(request, "wheels") || !structKeyExists(request.wheels, "urlForCache")) {
        if (!structKeyExists(request, "wheels")) {
            request.wheels = {};
        }
        request.wheels.urlForCache = {};
    }
    return application.wo.URLFor(
        route=arguments.route,
        key=arguments.key,
        params=arguments.params,
        onlyPath=true
    );
}
```

- [ ] **Step 2: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc
git commit -m "feat(test): add visitRoute, assertRouteIs to BrowserClient"
```

---

### Task 9: visitRoute + assertRouteIs Test Spec

Write the test spec for route navigation methods.

**Files:**
- Create: `vendor/wheels/tests/specs/wheelstest/BrowserRouteSpec.cfc`

- [ ] **Step 1: Write BrowserRouteSpec**

```cfm
// vendor/wheels/tests/specs/wheelstest/BrowserRouteSpec.cfc
component extends="wheels.wheelstest.BrowserTest" {

    function run() {

        describe("Route navigation (fixture server)", () -> {

            browserDescribe("visitRoute", () -> {

                it("navigates to a named route", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitRoute(route="browserTestHome")
                        .assertSee("Welcome to the browser test fixture");
                });

                it("navigates to dashboard route", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .loginAs("alice@example.com")
                        .visitRoute(route="browserTestDashboard")
                        .assertSee("Dashboard");
                });

            });

            browserDescribe("assertRouteIs", () -> {

                it("passes when on the correct route", () -> {
                    if (this.browserTestSkipped) return;
                    this.browser
                        .visitRoute(route="browserTestHome")
                        .assertRouteIs(route="browserTestHome");
                });

                it("fails with descriptive message when on wrong route", () -> {
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

            browserDescribe("$resolveRoute", () -> {

                it("resolves a named route to a path", () -> {
                    if (this.browserTestSkipped) return;
                    // Access the private method through the public API — visitRoute
                    // internally calls $resolveRoute. We verify by checking the URL
                    // after navigation.
                    this.browser
                        .visitRoute(route="browserTestLogin")
                        .assertUrlContains("/_browser/login");
                });

            });

        });

    }
}
```

- [ ] **Step 2: Run all browser test specs**

Run:
```bash
bash tools/test-local.sh
```

Or run just the browser specs:
```bash
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.wheelstest&reload=true" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```

Expected: All tests pass. The total count should be around 3100+ (existing 3045 + new specs).

- [ ] **Step 3: Commit**

```bash
git add vendor/wheels/tests/specs/wheelstest/BrowserRouteSpec.cfc
git commit -m "test(test): add visitRoute and assertRouteIs browser specs"
```

---

### Task 10: Remove Old Fixture Skeleton + Final Verification

Clean up the superseded fixture app skeleton and run the full test suite.

**Files:**
- Remove: `vendor/wheels/tests/fixtures/browserapp/` (entire directory)
- Modify: `CLAUDE.md` — update browser testing docs section

- [ ] **Step 1: Remove old fixture skeleton**

```bash
rm -rf vendor/wheels/tests/fixtures/browserapp/
```

- [ ] **Step 2: Update CLAUDE.md browser testing section**

In `CLAUDE.md`, update the "Browser Testing Quick Reference" section. Replace the "Deferred to follow-up PRs" list. Remove items that PR 3 delivers (loginAs, dialogs, visitRoute) and keep only what's actually deferred to PR 4.

Replace this block in CLAUDE.md:

```
### Deferred to follow-up PRs

These need a reflection-based Playwright option-object builder (URLClassLoader + Lucee OSGi trap), a running fixture-app server, or `createDynamicProxy` plumbing — each worth its own focused pass:

- Auth: `loginAs(identifier)`, `logout()` — test-only route + fixture server
- Cookies: `setCookie`, `deleteCookie`, `cookie` — needs `options.Cookie`
- Dialogs: `acceptDialog`, `dismissDialog`, `typeInDialog` — needs `createDynamicProxy` → `Consumer<Dialog>`
- `waitForUrl`, `assertRouteIs` — depend on baseUrl concat + Wheels `urlFor` context
- Configurable timeouts on `waitFor` — needs `Locator$WaitForOptions`
- `visitRoute` — depends on controller-context `urlFor`
- Viewport configuration at `BrowserTest` level — needs `ViewportSize` + `Browser$NewContextOptions`
- Auto screenshot on failure — needs TestBox aroundEach + failure hook
```

With:

```
### Deferred to PR 4

- CI workflow integration (Playwright install + browser specs in GitHub Actions)
- Reference docs promotion from draft `.ai/` to published docs
```

Also add the new DSL methods to the "Implemented DSL methods" list:

Under **Auth:** add `loginAs, logout, clearCookies`
Under **Dialogs:** add `acceptDialog, dismissDialog, dialogMessage`
Under **Navigation:** add `visitRoute`
Under **Assertions:** add `assertRouteIs`

- [ ] **Step 3: Run full test suite**

```bash
bash tools/test-local.sh
```

Expected: All tests pass, 0 failures, 0 errors. Total count should be ~3100+.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore(test): remove old fixture skeleton, update browser testing docs"
```

- [ ] **Step 5: Run full suite one more time to confirm clean state**

```bash
bash tools/test-local.sh
```

Expected: Same pass count as step 3, confirming the removal didn't break anything.
