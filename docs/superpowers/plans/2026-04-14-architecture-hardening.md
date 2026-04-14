# Architecture Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address the actionable findings from the architecture review — improve production error handling, add an inline XSS encoding helper, add error lifecycle hooks for package integration, and add dev-mode interface contract verification at startup.

**Architecture:** Four independent improvements to the framework core, all in `vendor/wheels/`. Each task produces a self-contained change with tests. No task depends on another.

**Tech Stack:** CFML (Lucee/Adobe CF/BoxLang), TestBox BDD

---

## Scope Notes

The following architecture review recommendations were **dropped after research** because they're already implemented:

- ~~Enable XSS encoding defaults~~ — `encodeHtmlTags=true` and `encodeHtmlAttributes=true` already set in `vendor/wheels/events/init/orm.cfm:8-9`
- ~~Per-environment config auto-loading~~ — Already implemented in `vendor/wheels/events/onapplicationstart.cfc:272-274`
- ~~Engine adapter polymorphism~~ — Already proper Strategy pattern with 3 concrete adapters
- ~~Extract `$integrateComponents`~~ — The outer method is identical across Controller/Model/Mapper, but `$integrateFunctions` differs significantly (super-prefix logic, exclude lists, mixin type checking). Not worth the risk for minimal gain.
- ~~Freeze `application.wheels` after bootstrap~~ — CFML has no native struct immutability. A write-detection wrapper adds complexity for low payoff.

---

## File Structure

### New Files
- `vendor/wheels/view/encoding.cfc` — Inline XSS encoding view helper (`h()`)
- `vendor/wheels/tests/specs/view/encodingSpec.cfc` — Tests for `h()` helper
- `vendor/wheels/tests/specs/events/errorHooksSpec.cfc` — Tests for error callback hooks
- `vendor/wheels/tests/specs/events/interfaceBootstrapSpec.cfc` — Tests for dev-mode interface verification

### Modified Files
- `vendor/wheels/events/EventMethods.cfc:2-131` — Add error hook callback chain to `$runOnError()`
- `vendor/wheels/events/onapplicationstart.cfc` — Add dev-mode interface contract verification after bootstrap
- `vendor/wheels/events/init/debugging.cfm` — Add `onErrorCallbacks` setting
- `app/events/onerror.cfm` — Replace bare stub with sensible production error page

---

## Task 1: Inline XSS Encoding View Helper `h()`

CFML templates use `#variable#` for expression output, which is raw/unencoded. The framework's form/link helpers encode via `$element()` and `$tagAttribute()`, but developers writing custom templates have no convenient shorthand. Rails has `h()`, Django has `|escape` — Wheels needs the equivalent.

**Files:**
- Create: `vendor/wheels/view/encoding.cfc`
- Create: `vendor/wheels/tests/specs/view/encodingSpec.cfc`

- [ ] **Step 1: Write the failing test**

Create `vendor/wheels/tests/specs/view/encodingSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

	function run() {

		describe("h() view helper", () => {

			it("encodes HTML special characters", () => {
				var result = h("<script>alert('xss')</script>");
				expect(result).toBe("&lt;script&gt;alert(&#x27;xss&#x27;)&lt;&#x2f;script&gt;");
			});

			it("returns empty string for empty input", () => {
				expect(h("")).toBe("");
			});

			it("passes through safe text unchanged", () => {
				expect(h("Hello World")).toBe("Hello World");
			});

			it("encodes ampersands", () => {
				var result = h("Tom & Jerry");
				expect(result).toInclude("&amp;");
			});

			it("encodes double quotes", () => {
				var result = h('He said "hello"');
				expect(result).toInclude("&quot;");
			});

			it("handles numeric input by converting to string", () => {
				expect(h(42)).toBe("42");
			});

		});

		describe("hAttr() view helper", () => {

			it("encodes for HTML attribute context", () => {
				var result = hAttr('"><script>alert(1)</script>');
				expect(result).notToInclude("<script>");
			});

			it("returns empty string for empty input", () => {
				expect(hAttr("")).toBe("");
			});

		});

	}

}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tools/test-local.sh` or:
```bash
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.view.encodingSpec" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```
Expected: FAIL/ERROR — `h()` function not defined

- [ ] **Step 3: Write the implementation**

Create `vendor/wheels/view/encoding.cfc`:

```cfm
component {

	/**
	 * Encodes a value for safe HTML output. Use in templates to prevent XSS:
	 * `#h(user.name)#` instead of `#user.name#`.
	 *
	 * [section: View Helpers]
	 * [category: Sanitization Functions]
	 *
	 * @value The value to encode for HTML output. Converted to string if not already.
	 */
	public string function h(required any value) {
		return EncodeForHTML(ToString(arguments.value));
	}

	/**
	 * Encodes a value for safe use inside an HTML attribute.
	 * Use when building attribute values manually:
	 * `<div title="#hAttr(user.bio)#">`.
	 *
	 * [section: View Helpers]
	 * [category: Sanitization Functions]
	 *
	 * @value The value to encode for HTML attribute context.
	 */
	public string function hAttr(required any value) {
		return EncodeForHTMLAttribute(ToString(arguments.value));
	}

}
```

- [ ] **Step 4: Reload and run test to verify it passes**

```bash
curl -s "http://localhost:8080/?reload=true&password=wheels"
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.view.encodingSpec" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```
Expected: All pass. The `h()` and `hAttr()` functions are automatically mixed into controllers via `$integrateComponents("wheels.view")` since `encoding.cfc` is in the `view/` directory.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/view/encoding.cfc vendor/wheels/tests/specs/view/encodingSpec.cfc
git commit -m "feat(view): add h() and hAttr() inline encoding helpers for XSS prevention"
```

---

## Task 2: Sensible Production Error Handler

The current `app/events/onerror.cfm` is a bare HTML stub with no logging, no request ID, and no useful structure. Replace it with a production-quality default that logs to stderr and renders a clean error page. The `exception` variable is already available in scope (passed by `EventMethods.$runOnError()` at line 117).

**Files:**
- Modify: `app/events/onerror.cfm`

- [ ] **Step 1: Write the improved production error page**

Replace `app/events/onerror.cfm`:

```cfm
<cfscript>
	// Log the error to stderr so it appears in server logs / container output.
	// The exception struct is passed into scope by the framework's $runOnError().
	local.message = "ERROR";
	if (StructKeyExists(variables, "exception")) {
		if (StructKeyExists(exception, "rootCause") && StructKeyExists(exception.rootCause, "message")) {
			local.message = exception.rootCause.type & ": " & exception.rootCause.message;
		} else if (StructKeyExists(exception, "message")) {
			local.message = exception.message;
		}
	}
	cflog(text = local.message, type = "error", file = "wheels-errors");
	WriteLog(type = "Error", text = local.message);
</cfscript>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>Something went wrong</title>
	<style>
		body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: ##f8f9fa; color: ##333; }
		.container { text-align: center; max-width: 480px; padding: 2rem; }
		h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
		p { color: ##666; line-height: 1.6; }
	</style>
</head>
<body>
	<div class="container">
		<h1>Something went wrong</h1>
		<p>We encountered an unexpected error processing your request. The issue has been logged and our team will look into it.</p>
		<p><a href="/">Return to homepage</a></p>
	</div>
</body>
</html>
```

Note: `##` is required in CFML templates to produce a literal `#` character in CSS hex colors.

- [ ] **Step 2: Verify by manually testing**

Start the server and trigger an error in production mode to confirm the page renders correctly and the error is logged.

- [ ] **Step 3: Commit**

```bash
git add app/events/onerror.cfm
git commit -m "fix(config): replace bare production error stub with logging and clean error page"
```

---

## Task 3: Error Lifecycle Hooks

Currently `EventMethods.$runOnError()` is monolithic — there's no way for packages (like Sentry) to hook into error events without middleware. Add a callback registration mechanism (`onError`) that fires before the error response is rendered. This mirrors the model callback pattern (`beforeSave`, etc.) at the application level.

**Files:**
- Modify: `vendor/wheels/events/init/debugging.cfm`
- Modify: `vendor/wheels/events/EventMethods.cfc:2-131`
- Create: `vendor/wheels/tests/specs/events/errorHooksSpec.cfc`

- [ ] **Step 1: Write the failing test**

Create `vendor/wheels/tests/specs/events/errorHooksSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

	function run() {

		describe("Error Lifecycle Hooks", () => {

			afterEach(() => {
				// Reset callbacks after each test
				application.wheels.onErrorCallbacks = [];
			});

			it("has an empty onErrorCallbacks array by default", () => {
				expect(application.wheels).toHaveKey("onErrorCallbacks");
				expect(application.wheels.onErrorCallbacks).toBeArray();
			});

			it("registerOnError adds a callback", () => {
				var callCount = {value: 0};
				application.wo.registerOnError(function(exception) {
					callCount.value++;
				});
				expect(ArrayLen(application.wheels.onErrorCallbacks)).toBe(1);
			});

			it("$fireOnErrorCallbacks invokes all registered callbacks", () => {
				var log = {entries: []};
				application.wo.registerOnError(function(exception) {
					ArrayAppend(log.entries, "first");
				});
				application.wo.registerOnError(function(exception) {
					ArrayAppend(log.entries, "second");
				});

				var fakeException = {message: "test error", type: "TestError"};
				application.wo.$fireOnErrorCallbacks(fakeException);

				expect(ArrayLen(log.entries)).toBe(2);
				expect(log.entries[1]).toBe("first");
				expect(log.entries[2]).toBe("second");
			});

			it("$fireOnErrorCallbacks does not throw if a callback fails", () => {
				application.wo.registerOnError(function(exception) {
					throw(type="CallbackBug", message="Broken callback");
				});
				application.wo.registerOnError(function(exception) {
					// This should still run
				});

				var fakeException = {message: "test", type: "TestError"};
				// Should not throw
				application.wo.$fireOnErrorCallbacks(fakeException);
			});

		});

	}

}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.events.errorHooksSpec" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```
Expected: FAIL — `onErrorCallbacks` key doesn't exist, `registerOnError` not defined

- [ ] **Step 3: Add the default setting**

In `vendor/wheels/events/init/debugging.cfm`, add after line 18 (after the `errorEmailAddress` block):

```cfm
		// Error lifecycle hooks — callbacks invoked when an error occurs.
		// Packages and app code can register via registerOnError(callback).
		application.$wheels.onErrorCallbacks = [];
```

- [ ] **Step 4: Add registration and invocation methods to EventMethods.cfc**

In `vendor/wheels/events/EventMethods.cfc`, add two new public methods after the `$runOnError` method (after the closing brace at line 131):

```cfm
	/**
	 * Registers a callback function to be invoked when an unhandled error occurs.
	 * Callbacks receive a single argument: the exception struct.
	 * Multiple callbacks are invoked in registration order. A failing callback
	 * is logged and skipped — it will not prevent other callbacks from running.
	 *
	 * [section: Configuration]
	 * [category: Error Handling]
	 *
	 * @callback A function that accepts an exception struct argument.
	 */
	public void function registerOnError(required function callback) {
		ArrayAppend(application.wheels.onErrorCallbacks, arguments.callback);
	}

	/**
	 * Fires all registered onError callbacks. Each runs in its own try/catch
	 * so a broken callback cannot suppress other callbacks or break error rendering.
	 */
	public void function $fireOnErrorCallbacks(required any exception) {
		if (
			StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "onErrorCallbacks")
			&& IsArray(application.wheels.onErrorCallbacks)
		) {
			for (var cb in application.wheels.onErrorCallbacks) {
				try {
					cb(arguments.exception);
				} catch (any e) {
					cflog(text = "onError callback failed: #e.message#", type = "error", file = "wheels-errors");
				}
			}
		}
	}
```

- [ ] **Step 5: Wire the hook into $runOnError**

In `vendor/wheels/events/EventMethods.cfc`, inside `$runOnError()`, add the callback invocation right after the email-sending block (after the closing brace of `if (application.wheels.sendEmailOnError)`, around line 42) and before the `if (application.wheels.showErrorInformation)` check:

```cfm
			// Fire registered onError callbacks (packages like Sentry hook in here).
			$fireOnErrorCallbacks(arguments.exception);
```

- [ ] **Step 6: Reload and run tests**

```bash
curl -s "http://localhost:8080/?reload=true&password=wheels"
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.events.errorHooksSpec" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```
Expected: All pass

- [ ] **Step 7: Run full test suite to check for regressions**

```bash
bash tools/test-local.sh
```
Expected: No regressions

- [ ] **Step 8: Commit**

```bash
git add vendor/wheels/events/init/debugging.cfm vendor/wheels/events/EventMethods.cfc vendor/wheels/tests/specs/events/errorHooksSpec.cfc
git commit -m "feat(config): add onError lifecycle hooks for package integration"
```

---

## Task 4: Dev-Mode Interface Contract Verification at Startup

The `vendor/wheels/interfaces/` directory contains 23 interface files across 7 subsystems. Only 4 use compile-time `implements=` enforcement (MiddlewareInterface, AuthStrategy, InjectorInterface, EventHandlerInterface). The remaining 11 model/controller/view/routing interfaces are "documentation-only" — verified by test specs but not checked at startup.

Add a dev-mode check that runs at the end of application bootstrap (after all mixins are integrated) to verify that Controller and Model instances satisfy their interface contracts. This catches broken mixin integration immediately instead of waiting for a test run.

**Files:**
- Modify: `vendor/wheels/events/onapplicationstart.cfc`
- Create: `vendor/wheels/tests/specs/events/interfaceBootstrapSpec.cfc`

- [ ] **Step 1: Write the failing test**

Create `vendor/wheels/tests/specs/events/interfaceBootstrapSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

	function run() {

		describe("Dev-Mode Interface Contract Verification", () => {

			it("$verifyInterfaceContracts does not throw in a healthy app", () => {
				// Should complete without error when all mixins are properly loaded
				application.wo.$verifyInterfaceContracts();
			});

			it("$verifyInterfaceContracts checks that model has finder methods", () => {
				// Create a model and verify it has the methods the interface requires
				var user = model("user");
				var requiredMethods = ["findAll", "findOne", "findByKey", "save", "valid"];
				for (var m in requiredMethods) {
					expect(StructKeyExists(user, m)).toBeTrue("Model missing required method: #m#");
				}
			});

			it("$verifyInterfaceContracts checks that controller has rendering methods", () => {
				// Instantiate a controller and check for rendering interface methods
				var params = {controller: "wheels", action: "wheels"};
				var controller = application.wo.$controller(name = "wheels", params = params);
				var requiredMethods = ["renderView", "renderPartial", "renderText", "redirectTo"];
				for (var m in requiredMethods) {
					expect(StructKeyExists(controller, m)).toBeTrue("Controller missing required method: #m#");
				}
			});

		});

	}

}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.events.interfaceBootstrapSpec" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```
Expected: FAIL — `$verifyInterfaceContracts` not defined

- [ ] **Step 3: Read the interface spec files to extract required method lists**

The implementation will use the existing interface spec files as the source of truth for required methods. Read these files to understand the pattern:
- `vendor/wheels/tests/specs/interfaces/ModelInterfaceSpec.cfc`
- `vendor/wheels/tests/specs/interfaces/ControllerInterfaceSpec.cfc`
- `vendor/wheels/tests/specs/interfaces/ViewInterfaceSpec.cfc`

The verification function uses a hardcoded subset of critical methods (not the full interface spec — that's what tests are for). The goal is a fast smoke test, not exhaustive verification.

- [ ] **Step 4: Add `$verifyInterfaceContracts()` to EventMethods.cfc**

In `vendor/wheels/events/EventMethods.cfc`, add after the `$fireOnErrorCallbacks` method:

```cfm
	/**
	 * Verifies that mixin-assembled objects satisfy critical interface contracts.
	 * Runs only in development mode at the end of application bootstrap.
	 * Checks a subset of essential methods — full verification is done by test specs.
	 * Logs warnings instead of throwing to avoid blocking app startup.
	 */
	public void function $verifyInterfaceContracts() {
		local.issues = [];

		// Check Model interface (requires a test model to be available)
		try {
			local.modelMethods = [
				"findAll", "findOne", "findByKey", "count", "exists",
				"save", "valid", "update", "delete",
				"hasMany", "belongsTo", "hasOne",
				"validatesPresenceOf"
			];
			// Use the framework's internal model prototype if available
			if (StructKeyExists(application.wheels, "models") && !StructIsEmpty(application.wheels.models)) {
				local.sampleModelName = StructKeyArray(application.wheels.models)[1];
				local.sampleModel = model(local.sampleModelName);
				for (local.m in local.modelMethods) {
					if (!StructKeyExists(local.sampleModel, local.m)) {
						ArrayAppend(local.issues, "Model(#local.sampleModelName#) missing: #local.m#()");
					}
				}
			}
		} catch (any e) {
			ArrayAppend(local.issues, "Model contract check failed: #e.message#");
		}

		// Check Controller interface
		try {
			local.controllerMethods = [
				"renderView", "renderPartial", "renderText", "redirectTo",
				"linkTo", "urlFor", "startFormTag", "endFormTag",
				"filters", "verifies"
			];
			local.params = {controller: "wheels", action: "wheels"};
			local.testController = $controller(name: "wheels", params: local.params);
			for (local.m in local.controllerMethods) {
				if (!StructKeyExists(local.testController, local.m)) {
					ArrayAppend(local.issues, "Controller missing: #local.m#()");
				}
			}
		} catch (any e) {
			ArrayAppend(local.issues, "Controller contract check failed: #e.message#");
		}

		// Report issues as warnings
		if (ArrayLen(local.issues)) {
			local.msg = "Interface contract warnings: " & ArrayToList(local.issues, "; ");
			cflog(text = local.msg, type = "warning", file = "wheels-errors");
			if (StructKeyExists(application, "$wheels") && application.$wheels.showDebugInformation) {
				request.wheels.interfaceWarnings = local.issues;
			}
		}
	}
```

- [ ] **Step 5: Wire the check into onapplicationstart.cfc**

In `vendor/wheels/events/onapplicationstart.cfc`, find the line near the end of the `$init()` method where `application.$wheels` is swapped to `application.wheels` (the atomic swap). After the swap and after the "initialized" flag is set, add:

```cfm
		// Dev-mode: verify interface contracts after all mixins are loaded
		if (application.wheels.environment == "development") {
			application.wo.$verifyInterfaceContracts();
		}
```

- [ ] **Step 6: Reload and run tests**

```bash
curl -s "http://localhost:8080/?reload=true&password=wheels"
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.events.interfaceBootstrapSpec" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```
Expected: All pass

- [ ] **Step 7: Run full test suite**

```bash
bash tools/test-local.sh
```
Expected: No regressions

- [ ] **Step 8: Commit**

```bash
git add vendor/wheels/events/EventMethods.cfc vendor/wheels/events/onapplicationstart.cfc vendor/wheels/tests/specs/events/interfaceBootstrapSpec.cfc
git commit -m "feat(config): add dev-mode interface contract verification at startup"
```

---

## Unresolved Questions

1. **`h()` name collision** — Is `h` too generic? Could conflict with app-defined helpers. Rails uses it universally; seems safe for Wheels convention. Alternative: `encodeHTML()` (more explicit, longer).
2. **Error hooks in production** — Should `registerOnError` be available in all environments or dev-only? Plan assumes all environments (Sentry needs it in production).
3. **Interface check performance** — Instantiating a controller and model at startup adds ~50ms. Acceptable for dev mode only?
4. **Test model dependency** — `$verifyInterfaceContracts` needs at least one model loaded. In a fresh scaffold with no models, the model check is silently skipped. Should it warn?
