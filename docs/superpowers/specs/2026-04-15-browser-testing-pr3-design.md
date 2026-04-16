# Browser Testing PR 3 — loginAs, Dialogs, Fixture Routes, visitRoute

**Date**: 2026-04-15
**PR**: 3 of 4 in browser testing trail (v4.0 item #4)
**Depends on**: PR 1 (#2113), PR 2 (#2115) — both merged
**Branch**: `peter/browser-testing-pr3`

## Summary

PR 3 delivers four capabilities that require a running Wheels app (unlike PRs 1-2 which used data: URLs for ~95% of tests):

1. **Test route mounting** — fixture controllers served under `/_browser/` in the main app
2. **loginAs / logout DSL** — test-only authentication bypass via POST endpoint
3. **Dialog handling** — acceptDialog/dismissDialog/typeInDialog via Lucee's createDynamicProxy
4. **visitRoute / assertRouteIs** — named route resolution from test context

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Fixture server | Same server, `/_browser/` routes | No second server needed; simplest for CI; env-gated to testing |
| Dialog proxy | Lucee-only via createDynamicProxy | Cross-engine reflection too complex for test tooling; graceful skip on other engines |
| Route resolution | `application.wo.URLFor()` direct call | Already available in test context; no HTTP round-trip; acceptable coupling for framework test tooling |

---

## 1. Test Route Mounting

### Approach

Mount fixture controllers under the `/_browser/` prefix in the main Wheels app's route table. Routes are registered only when `get("environment") == "testing"`.

### Route Table

| Method | Path | Controller | Action | Route Name |
|--------|------|-----------|--------|------------|
| GET | `/_browser/home` | BrowserTestHome | index | browserTestHome |
| GET | `/_browser/login` | BrowserTestSessions | new | browserTestLogin |
| POST | `/_browser/login` | BrowserTestSessions | create | browserTestAuthenticate |
| GET | `/_browser/dashboard` | BrowserTestHome | dashboard | browserTestDashboard |
| POST | `/_browser/logout` | BrowserTestSessions | destroy | browserTestLogout |
| POST | `/_browser/login-as` | BrowserTestLogin | create | browserTestLoginAs |

### Route Registration

Add a testing-only block in `config/routes.cfm` (or the test bootstrap) that registers these routes before `.wildcard()`:

```cfm
if (get("environment") == "testing") {
    .scope(path="/_browser")
        .get(name="browserTestHome", pattern="/home", to="BrowserTestHome##index")
        .get(name="browserTestLogin", pattern="/login", to="BrowserTestSessions##new")
        .post(name="browserTestAuthenticate", pattern="/login", to="BrowserTestSessions##create")
        .get(name="browserTestDashboard", pattern="/dashboard", to="BrowserTestHome##dashboard")
        .post(name="browserTestLogout", pattern="/logout", to="BrowserTestSessions##destroy")
        .post(name="browserTestLoginAs", pattern="/login-as", to="BrowserTestLogin##create")
    .end()
}
```

### Controllers

Existing fixture controllers at `vendor/wheels/tests/fixtures/browserapp/app/controllers/` are renamed with `BrowserTest` prefix:

- `Home.cfc` → `BrowserTestHome.cfc`
- `Sessions.cfc` → `BrowserTestSessions.cfc`
- New: `BrowserTestLogin.cfc` (loginAs endpoint)

Controllers move to `vendor/wheels/tests/fixtures/browserapp/app/controllers/` but must be discoverable by the main app. Options:
- (a) Symlink or copy into the main `app/controllers/` at test time
- (b) Use a Wheels controller path mapping
- (c) Place them directly in the project's `app/controllers/` with `BrowserTest` prefix (simplest)

**Decision**: Place controllers in `app/controllers/` with `BrowserTest` prefix. They only activate in testing mode (routes are env-gated). This is simplest and follows Wheels' convention of controllers living in `app/controllers/`.

### Views

Views stay at `vendor/wheels/tests/fixtures/browserapp/app/views/` but need to be accessible. Since controllers are now named `BrowserTestHome` and `BrowserTestSessions`, the view paths become:

- `app/views/browsertesthome/index.cfm`
- `app/views/browsertesthome/dashboard.cfm`
- `app/views/browsertestsessions/new.cfm`

These go in the main `app/views/` directory, matching the controller names.

### Layout

The fixture views need a minimal layout. Create `app/views/browsertesthome/layout.cfm` (controller-specific layout) with a basic HTML wrapper. No CSS framework, just structural HTML for test assertions.

---

## 2. loginAs / logout DSL

### Login Endpoint

`BrowserTestLogin.cfc` — test-only controller:

```cfm
component extends="Controller" {
    function config() {
        // No filters — this is a backdoor
    }

    function create() {
        // Hard gate: refuse to run outside testing
        if (get("environment") != "testing") {
            throw(type="Wheels.BrowserTestSecurityError",
                  message="loginAs endpoint is only available in testing environment");
        }

        session.userId = 1;
        session.userEmail = params.identifier;

        // Return simple HTML (not redirect) so APIRequestContext can verify
        renderText(text="<html><body>Logged in as #encodeForHTML(params.identifier)#</body></html>");
    }
}
```

### BrowserClient.loginAs(identifier)

The loginAs route accepts GET. `loginAs(identifier)` calls `visit("/_browser/login-as?identifier=" & encodeForURL(identifier))`. This is simple, works regardless of current page origin (data: URL, blank, or app), and avoids fetch/form POST complexity. GET is acceptable since this endpoint only exists in testing mode.

```cfm
public BrowserClient function loginAs(required string identifier) {
    visit("/_browser/login-as?identifier=" & encodeForURL(arguments.identifier));
    return this;
}
```

The loginAs route in `config/routes.cfm` is registered as GET (not POST):

```cfm
.get(name="browserTestLoginAs", pattern="/login-as", to="BrowserTestLogin##create")
```

### BrowserClient.logout()

`logout()` clears all cookies on the browser context and navigates to the fixture home page to reset page state. This is engine-agnostic, doesn't need a server endpoint, and guarantees a clean session.

```cfm
public BrowserClient function logout() {
    variables.context.clearCookies();
    visit("/_browser/home");
    return this;
}
```

If a test needs to verify the logout UI flow (click the logout button, see redirect), it should use `click()` / `press()` directly instead of the `logout()` shortcut.

---

## 3. Dialog Handling

### API

```cfm
// Accept the next dialog
this.browser.acceptDialog().click("##delete-btn")

// Dismiss the next dialog
this.browser.dismissDialog().click("##cancel-btn")

// Type text into a prompt dialog, then accept
// typeInDialog sets the text; acceptDialog sets the action type — order matters
this.browser.acceptDialog(text="yes").click("##confirm-btn")

// Read the last dialog message
var msg = this.browser.dialogMessage()
```

**Method signatures**:
- `acceptDialog(string text="")` — registers accept intent; optional text for prompt dialogs
- `dismissDialog()` — registers dismiss intent
- `dialogMessage()` — returns last dialog's message text (terminal, not chainable)

### State Machine

BrowserClient gains:
- `variables.$pendingDialogAction` — `""` (none) or struct `{type: "accept"|"dismiss", text: ""}`
- `variables.$lastDialogMessage` — last dialog message text (set by listener)
- `variables.$dialogProxy` — the Java proxy object (for cleanup)

### Flow

1. `acceptDialog(text="")` stores `{type: "accept", text: text}` in `$pendingDialogAction`, returns `this`
2. `dismissDialog()` stores `{type: "dismiss", text: ""}` in `$pendingDialogAction`, returns `this`
3. The next dialog-aware interaction method (`click`, `press`, `keys`) checks `$pendingDialogAction`:
   - If set: calls `$registerDialogListener()`, executes the interaction, calls `$clearDialogListener()`
   - If not set: executes normally
4. `dialogMessage()` returns `$lastDialogMessage` (terminal, not chainable)

### createDynamicProxy Implementation

```cfm
private void function $registerDialogListener() {
    if (!len(variables.$pendingDialogAction)) return;

    var action = variables.$pendingDialogAction;
    var state = {lastMessage: "", handled: false};
    variables.$dialogState = state;

    // Build the Consumer<Dialog> proxy
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
```

After the interaction:
```cfm
private void function $clearDialogListener() {
    variables.$lastDialogMessage = variables.$dialogState.lastMessage ?: "";
    variables.$pendingDialogAction = "";
    variables.$dialogProxy = "";
    variables.$dialogState = "";
    // Note: Playwright Java may not have offDialog(). The proxy becomes a no-op
    // after firing since it only acts once. If the page triggers another dialog
    // without a registered listener, Playwright auto-dismisses it.
}
```

### Engine Gate

```cfm
private void function $requireDialogSupport() {
    try {
        createDynamicProxy({accept: function(x){}}, ["java.lang.Runnable"]);
    } catch (any e) {
        throw(type="Wheels.BrowserDialogNotSupported",
              message="Dialog handling requires Lucee. This engine does not support createDynamicProxy.");
    }
}
```

Call `$requireDialogSupport()` from `acceptDialog()` / `dismissDialog()`. Cache the result in a variable so the check only runs once per BrowserClient instance.

### Interaction Method Wrapper

Rather than modifying every interaction method, add a private helper:

```cfm
private void function $withDialogHandler(required function action) {
    if (isStruct(variables.$pendingDialogAction)) {
        $registerDialogListener();
    }
    arguments.action();
    if (isStruct(variables.$pendingDialogAction)) {
        $clearDialogListener();
    }
}
```

Then `click()` becomes:
```cfm
public BrowserClient function click(required string selector) {
    $withDialogHandler(() => {
        $locator(arguments.selector).click();
    });
    return this;
}
```

**Concern**: This changes every interaction method. A less invasive approach: only `click()` and `press()` can trigger dialogs (they're the only ones that fire user events that produce JS alerts). Scope the dialog handling to just those two methods.

**Decision**: Apply dialog handling to `click()`, `press()`, and `keys()` — the three methods that fire user events capable of triggering JS dialogs. Other methods (`fill`, `type`, `select`, etc.) don't trigger dialogs in normal usage. If a user needs dialog handling on a custom action, they can call `$registerDialogListener()` / `$clearDialogListener()` directly (both public with `$` prefix).

### Removed: typeInDialog

Earlier iterations had a separate `typeInDialog(text)` method. This was consolidated into `acceptDialog(text="")` — the `text` argument serves the same purpose with less API surface. For prompt dialogs, use `acceptDialog(text="your input")`.

### Test Data

Dialog tests need HTML with `alert()`, `confirm()`, `prompt()`. These work on data: URLs — no fixture server needed:

```html
data:text/html,<button onclick="alert('hello')">Alert</button>
data:text/html,<button onclick="confirm('sure?')">Confirm</button>
data:text/html,<button onclick="result.textContent=prompt('name?')">Prompt</button><span id="result"></span>
```

---

## 4. visitRoute / assertRouteIs

### API

```cfm
this.browser.visitRoute(route="browserTestDashboard")
this.browser.visitRoute(route="user", key=42)
this.browser.assertRouteIs(route="browserTestDashboard")
```

### Implementation

Both methods call `application.wo.URLFor()` to resolve the route name to a path:

```cfm
public BrowserClient function visitRoute(
    required string route,
    any key = "",
    string params = ""
) {
    var path = $resolveRoute(argumentCollection=arguments);
    return visit(path);
}

public BrowserClient function assertRouteIs(
    required string route,
    any key = "",
    string params = ""
) {
    var expectedPath = $resolveRoute(argumentCollection=arguments);
    var actualPath = $pathFromUrl(currentUrl());
    if (actualPath != expectedPath) {
        $assertFail("Expected route '#arguments.route#' (#expectedPath#) but was at #actualPath#");
    }
    return this;
}

private string function $resolveRoute(
    required string route,
    any key = "",
    string params = ""
) {
    return application.wo.URLFor(
        route=arguments.route,
        key=arguments.key,
        params=arguments.params,
        onlyPath=true
    );
}
```

### Prerequisites

`application.wo.URLFor()` requires:
- `application.wheels.routes` — populated at app start
- `request.wheels.urlForCache` — populated by `$initializeRequestScope()`
- `request.cgi.script_name` — available in test context

All three are present when tests run inside a Wheels request. If `request.wheels` is missing (standalone usage), `$resolveRoute` initializes it:

```cfm
if (!structKeyExists(request, "wheels") || !structKeyExists(request.wheels, "urlForCache")) {
    request.wheels = request.wheels ?: {};
    request.wheels.urlForCache = {};
}
```

### Edge Cases

- **Route not found**: `URLFor` with an invalid route name falls through to default pattern generation. This produces a URL but not the expected one. Consider validating route existence first by scanning `application.wheels.routes` for a matching name.
- **Key encoding**: `URLFor` handles key encoding. We pass through as-is.
- **Query params**: `params` argument passes through to `URLFor` which appends them as query string.

---

## Files Changed

### New Files

| File | Purpose |
|------|---------|
| `app/controllers/BrowserTestHome.cfc` | Fixture: home + dashboard (auth-protected) |
| `app/controllers/BrowserTestSessions.cfc` | Fixture: login form + create/destroy |
| `app/controllers/BrowserTestLogin.cfc` | Test-only loginAs endpoint |
| `app/views/browsertesthome/index.cfm` | Home page view |
| `app/views/browsertesthome/dashboard.cfm` | Protected dashboard view |
| `app/views/browsertesthome/layout.cfm` | Minimal HTML layout |
| `app/views/browsertestsessions/new.cfm` | Login form view |
| `app/views/browsertestlogin/create.cfm` | loginAs success view |
| `vendor/wheels/tests/specs/wheelstest/BrowserLoginSpec.cfc` | loginAs/logout tests |
| `vendor/wheels/tests/specs/wheelstest/BrowserDialogSpec.cfc` | Dialog handling tests |
| `vendor/wheels/tests/specs/wheelstest/BrowserRouteSpec.cfc` | visitRoute/assertRouteIs tests |

### Modified Files

| File | Changes |
|------|---------|
| `config/routes.cfm` | Add `/_browser/*` test routes (env-gated) |
| `vendor/wheels/wheelstest/BrowserClient.cfc` | Add loginAs, logout, dialog methods, visitRoute, assertRouteIs |

### Removed / Deprecated

The fixture app skeleton at `vendor/wheels/tests/fixtures/browserapp/` is superseded by the `app/controllers/BrowserTest*.cfc` + `app/views/browsertest*/` approach. The skeleton files can be removed or left as documentation of the original design.

---

## Test Plan

### loginAs / logout
- loginAs sets session, subsequent visit to dashboard shows user email
- loginAs with unknown identifier still sets session (test backdoor, no validation)
- logout clears cookies, dashboard redirects to login
- loginAs → visit dashboard → logout → visit dashboard → redirected to login
- loginAs outside testing environment throws security error

### Dialogs
- acceptDialog + click triggers alert → no error, dialog auto-accepted
- dismissDialog + click triggers confirm → confirm returns false
- typeInDialog + acceptDialog + click triggers prompt → prompt receives text
- dialogMessage returns last dialog's message text
- acceptDialog without subsequent interaction is harmless (pending action cleared on next interaction)
- Dialog methods on non-Lucee engines throw BrowserDialogNotSupported
- Data URL tests (no server needed for dialog testing)

### visitRoute / assertRouteIs
- visitRoute navigates to correct path
- visitRoute with key substitutes into URL pattern
- assertRouteIs passes when on correct route
- assertRouteIs fails with descriptive message when on wrong route
- Invalid route name produces meaningful error

### Integration
- Full login flow: visit login page → fill form → submit → arrive at dashboard
- loginAs shortcut: loginAs → visit dashboard → see content
- Protected page without login → redirect to login page

---

## Open Questions

- **offDialog**: Does Playwright Java 1.52 expose `page.offDialog(handler)` or `page.removeListener("dialog", handler)`? If not, the one-shot proxy is harmless but stays registered. Need to verify.
- **loginAs GET vs POST**: Design above settles on GET for simplicity. If the test routes ever leak to non-testing mode, GET exposes identifiers in logs. The env gate is the primary security control.
- **View path resolution**: Wheels convention derives view path from controller name (`BrowserTestHome` → `app/views/browsertesthome/`). Verify this works with the `BrowserTest` prefix or if we need explicit `renderView(template=...)` calls.
