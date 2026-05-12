# Browser Testing PR 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `$buildOption` reflection helper to unblock deferred DSL methods (cookies, configurable timeouts, waitForUrl, screenshot options, viewport config), CLI commands (`wheels browser:install`, `wheels browser:test`), and auto-screenshot on test failure.

**Architecture:** `$buildOption` on BrowserLauncher loads Playwright inner classes via URLClassLoader reflection, constructs option objects, and applies fluent setters. BrowserClient wraps these in thin DSL methods. CLI commands delegate to a shared BrowserService for JAR management. Auto-screenshot uses TestBox `aroundEach` to capture artifacts on failure.

**Tech Stack:** CFML (Lucee), Playwright Java 1.52.0, TestBox BDD, Java reflection API, URLClassLoader

**Spec:** `docs/superpowers/specs/2026-04-15-browser-testing-pr2-design.md`

---

## File Structure

### New Files

| File | Responsibility |
|------|----------------|
| `cli/src/commands/wheels/browser/install.cfc` | CommandBox `wheels browser:install` command |
| `cli/src/commands/wheels/browser/test.cfc` | CommandBox `wheels browser:test` command |
| `cli/src/models/BrowserService.cfc` | Shared JAR download, SHA verification, pre-flight checks |

### Modified Files

| File | Changes |
|------|---------|
| `vendor/wheels/wheelstest/BrowserLauncher.cfc` | Add `$buildOption`, `$findSetter`, `$castForParam` |
| `vendor/wheels/wheelstest/BrowserClient.cfc` | Accept launcher in init; add cookies, waitForUrl; update waitFor, waitForText, screenshot |
| `vendor/wheels/wheelstest/BrowserTest.cfc` | Pass launcher to BrowserClient; add viewport config; add aroundEach + `$captureFailureArtifacts` |
| `cli/lucli/Module.cfc` | Add `browser()` public function with install/test subcommand dispatch |
| `tools/install-playwright.sh` | Add deprecation notice |
| `vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc` | Tests for `$buildOption`, `$findSetter`, `$castForParam` |
| `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc` | Tests for new/updated DSL methods |
| `vendor/wheels/tests/specs/wheelstest/BrowserTestLifecycleSpec.cfc` | Tests for viewport config, auto-screenshot |
| `.ai/wheels/testing/browser-testing.md` | Document new DSL methods + CLI commands |

### Verified Playwright Java 1.52.0 API

| Class | Constructor | Key Setters |
|-------|------------|-------------|
| `options.Cookie` | `(String name, String value)` — two-arg only | `setUrl(String)`, `setDomain(String)`, `setPath(String)`, `setExpires(double)`, `setHttpOnly(boolean)`, `setSecure(boolean)` |
| `BrowserContext$ClearCookiesOptions` | zero-arg | `setName(String)`, `setDomain(String)`, `setPath(String)` (also Pattern overloads) |
| `options.ViewportSize` | `(int width, int height)` — no zero-arg | public fields `width`, `height` |
| `Browser$NewContextOptions` | zero-arg | `setViewportSize(ViewportSize)`, `setViewportSize(int, int)` |
| `Page$ScreenshotOptions` | zero-arg | `setPath(Path)`, `setFullPage(boolean)`, `setQuality(int)`, `setTimeout(double)` |
| `Locator$WaitForOptions` | zero-arg | `setTimeout(double)` |
| `Page$WaitForURLOptions` | zero-arg | `setTimeout(double)` |

---

## Task 1: `$buildOption` Reflection Helper

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserLauncher.cfc`
- Test: `vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc`

### Sub-helpers first: `$findSetter` and `$castForParam`

- [ ] **Step 1: Write failing tests for `$findSetter`**

Add to `BrowserLauncherSpec.cfc` inside a new `describe("$findSetter")` block after the existing `$findZeroArgMethod` tests:

```cfm
describe("$findSetter", () => {

    it("finds a one-arg setter by name on a JDK class", () => {
        // java.util.Date has setTime(long) — one-arg setter
        var klass = createObject("java", "java.util.Date").getClass();
        var method = launcher.$findSetter(klass=klass, name="setTime");
        expect(method.getName()).toBe("setTime");
        expect(arrayLen(method.getParameterTypes())).toBe(1);
    });

    it("throws BrowserOptionError for nonexistent setter", () => {
        var klass = createObject("java", "java.util.Date").getClass();
        expect(() => {
            launcher.$findSetter(klass=klass, name="setNonexistent");
        }).toThrow("Wheels.BrowserOptionError");
    });

});
```

- [ ] **Step 2: Run test, verify failure**

```bash
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.wheelstest" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
for b in d.get('bundleStats',[]):
  for s in b.get('suiteStats',[]):
    for sp in s.get('specStats',[]):
      if sp.get('status') in ('Failed','Error'):
        print(f'  {sp[\"status\"]}: {sp[\"name\"]}: {sp.get(\"failMessage\",\"\")[:120]}')
"
```

Expected: FAIL — `$findSetter` method does not exist.

- [ ] **Step 3: Implement `$findSetter` and `$castForParam`**

Add to `BrowserLauncher.cfc` after the existing `$findZeroArgMethod` method:

```cfm
/**
 * Finds a one-argument method with the given name on the given class.
 * Used to locate fluent setters on Playwright option objects.
 */
public any function $findSetter(required any klass, required string name) {
    var methods = arguments.klass.getMethods();
    for (var i = 1; i <= arrayLen(methods); i++) {
        if (
            methods[i].getName() == arguments.name
            && arrayLen(methods[i].getParameterTypes()) == 1
        ) {
            return methods[i];
        }
    }
    throw(
        type="Wheels.BrowserOptionError",
        message="No one-arg method named '" & arguments.name
            & "' on class " & arguments.klass.getName()
    );
}

/**
 * Cast a CFML value to the Java type expected by a method parameter.
 * Reads the parameter's declared type and applies the appropriate javaCast.
 * Java objects (e.g., nested option objects from $buildOption) pass through.
 */
public any function $castForParam(required any value, required any paramType) {
    var typeName = arguments.paramType.getName();
    switch (typeName) {
        case "double":
        case "java.lang.Double":
            return javaCast("double", arguments.value);
        case "int":
        case "java.lang.Integer":
            return javaCast("int", arguments.value);
        case "long":
        case "java.lang.Long":
            return javaCast("long", arguments.value);
        case "boolean":
        case "java.lang.Boolean":
            return javaCast("boolean", arguments.value);
        case "java.lang.String":
            return javaCast("string", arguments.value);
        default:
            return arguments.value;
    }
}
```

- [ ] **Step 4: Run tests, verify pass**

Same curl command as Step 2. Expected: `$findSetter` tests PASS.

- [ ] **Step 5: Write failing test for `$castForParam`**

Add to `BrowserLauncherSpec.cfc`:

```cfm
describe("$castForParam", () => {

    it("casts numeric to java.lang.Double for double param type", () => {
        var paramType = createObject("java", "java.lang.Double").TYPE;
        var result = launcher.$castForParam(value=5000, paramType=paramType);
        expect(result.getClass().getName()).toBe("java.lang.Double");
    });

    it("casts numeric to java.lang.Integer for int param type", () => {
        var paramType = createObject("java", "java.lang.Integer").TYPE;
        var result = launcher.$castForParam(value=42, paramType=paramType);
        expect(result.getClass().getName()).toBe("java.lang.Integer");
    });

    it("passes Java objects through unchanged", () => {
        var obj = createObject("java", "java.util.Date").init();
        var paramType = createObject("java", "java.util.Date").getClass();
        var result = launcher.$castForParam(value=obj, paramType=paramType);
        expect(result).toBe(obj);
    });

});
```

- [ ] **Step 6: Run tests, verify pass**

These should pass immediately since `$castForParam` was already implemented. Expected: all PASS.

### Core method: `$buildOption`

- [ ] **Step 7: Write failing integration test for `$buildOption`**

Add to `BrowserLauncherSpec.cfc` inside a new `describe("$buildOption")` block. This goes in the integration test section (guarded by JAR-present skip):

```cfm
describe("$buildOption", () => {

    it("throws BrowserOptionError when classloader not initialized", () => {
        var freshLauncher = new wheels.wheelstest.BrowserLauncher();
        expect(() => {
            freshLauncher.$buildOption(className="java.util.Date");
        }).toThrow("Wheels.BrowserOptionError");
    });

    it("builds a zero-arg Playwright option with setters", () => {
        if (skipBrowserTests) return;
        var opts = launcher.$buildOption(
            className="com.microsoft.playwright.Locator$WaitForOptions",
            setterMap={setTimeout: 5000}
        );
        expect(isObject(opts)).toBeTrue();
    });

    it("builds an option with constructor args", () => {
        if (skipBrowserTests) return;
        var viewport = launcher.$buildOption(
            className="com.microsoft.playwright.options.ViewportSize",
            constructorArgs=[375, 667]
        );
        expect(isObject(viewport)).toBeTrue();
        expect(viewport.width).toBe(375);
        expect(viewport.height).toBe(667);
    });

    it("builds an option with constructor args AND setters", () => {
        if (skipBrowserTests) return;
        var cookie = launcher.$buildOption(
            className="com.microsoft.playwright.options.Cookie",
            constructorArgs=["testName", "testValue"],
            setterMap={setUrl: "http://localhost"}
        );
        expect(isObject(cookie)).toBeTrue();
        expect(cookie.name).toBe("testName");
        expect(cookie.value).toBe("testValue");
    });

    it("passes nested Java objects through setters", () => {
        if (skipBrowserTests) return;
        var viewport = launcher.$buildOption(
            className="com.microsoft.playwright.options.ViewportSize",
            constructorArgs=[375, 667]
        );
        var contextOpts = launcher.$buildOption(
            className="com.microsoft.playwright.Browser$NewContextOptions",
            setterMap={setViewportSize: viewport}
        );
        expect(isObject(contextOpts)).toBeTrue();
    });

});
```

- [ ] **Step 8: Run tests, verify failure**

Expected: FAIL — `$buildOption` method does not exist.

- [ ] **Step 9: Implement `$buildOption`**

Add to `BrowserLauncher.cfc`:

```cfm
/**
 * Construct a Playwright option object via reflection through our URLClassLoader.
 *
 * Lucee's createObject("java", "InnerClass") fails when the class lives in a
 * URLClassLoader — it tries to resolve via OSGi bundles. This helper bypasses
 * that by using loadClass() + reflection directly.
 *
 * @className   Fully-qualified Java class name (use $ for inner classes)
 * @setterMap   Struct of setter-name => value. Values auto-cast to match parameter type.
 * @constructorArgs  Array of constructor arguments. Matched by arity; auto-cast per param type.
 */
public any function $buildOption(
    required string className,
    struct setterMap = {},
    array constructorArgs = []
) {
    if (!structKeyExists(variables, "$classLoader")) {
        throw(
            type="Wheels.BrowserOptionError",
            message="Cannot build option: classloader not initialized. Call $loadJars() first."
        );
    }

    var klass = "";
    try {
        klass = variables.$classLoader.loadClass(arguments.className);
    } catch (any e) {
        throw(
            type="Wheels.BrowserOptionError",
            message="Class not found: " & arguments.className & ". " & e.message
        );
    }

    // Construct instance
    var instance = "";
    if (arrayLen(arguments.constructorArgs)) {
        instance = $constructWithArgs(klass=klass, args=arguments.constructorArgs);
    } else {
        try {
            instance = klass.getDeclaredConstructor().newInstance();
        } catch (any e) {
            throw(
                type="Wheels.BrowserOptionError",
                message="Failed to construct " & arguments.className
                    & " with zero-arg constructor: " & e.message
            );
        }
    }

    // Apply setters
    for (var setterName in arguments.setterMap) {
        var value = arguments.setterMap[setterName];
        try {
            var setter = $findSetter(klass=klass, name=setterName);
            var paramType = setter.getParameterTypes()[1];
            var castedValue = $castForParam(value=value, paramType=paramType);
            setter.invoke(instance, javaCast("Object[]", [castedValue]));
        } catch (any e) {
            if (findNoCase("Wheels.", e.type ?: "")) rethrow;
            throw(
                type="Wheels.BrowserOptionError",
                message="Failed to call " & setterName & " on "
                    & arguments.className & ": " & e.message
            );
        }
    }

    return instance;
}

/**
 * Construct an instance using a constructor matched by argument count.
 * Tries each constructor with matching arity until one succeeds.
 */
private any function $constructWithArgs(required any klass, required array args) {
    var constructors = arguments.klass.getDeclaredConstructors();
    var targetArity = arrayLen(arguments.args);

    for (var i = 1; i <= arrayLen(constructors); i++) {
        var paramTypes = constructors[i].getParameterTypes();
        if (arrayLen(paramTypes) != targetArity) continue;

        try {
            var castedArgs = [];
            for (var j = 1; j <= targetArity; j++) {
                arrayAppend(castedArgs, $castForParam(
                    value=arguments.args[j],
                    paramType=paramTypes[j]
                ));
            }
            return constructors[i].newInstance(javaCast("Object[]", castedArgs));
        } catch (any e) {
            // Type mismatch — try next constructor with same arity
        }
    }

    throw(
        type="Wheels.BrowserOptionError",
        message="No constructor with " & targetArity & " arg(s) found on "
            & arguments.klass.getName()
    );
}
```

- [ ] **Step 10: Run tests, verify all pass**

Expected: all `$buildOption` tests PASS. Run the full browser test suite to check for regressions:

```bash
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.wheelstest" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
"
```

- [ ] **Step 11: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserLauncher.cfc vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc
git commit -m "feat(test): add \$buildOption reflection helper to BrowserLauncher

Enables construction of Playwright inner-class option objects through
the URLClassLoader, bypassing Lucee's OSGi bundle resolver. Supports
zero-arg + setter, multi-arg constructor, and nested objects."
```

---

## Task 2: Wire Launcher into BrowserClient

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Modify: `vendor/wheels/wheelstest/BrowserTest.cfc`
- Test: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Write failing test**

Add to `BrowserIntegrationSpec.cfc` inside the existing navigation describe block (or a new "launcher wiring" describe):

```cfm
it("exposes launcher via getLauncher()", () => {
    if (skipBrowserTests) return;
    expect(isObject(bc.getLauncher())).toBeTrue();
    expect(bc.getLauncher().getState()).toBe("ready");
});
```

Note: `bc` is the BrowserClient instance used by integration tests. If integration tests create their own BrowserClient, the launcher needs to be passed in. Check how `bc` is currently initialized in the spec and update accordingly.

- [ ] **Step 2: Run test, verify failure**

Expected: FAIL — `getLauncher()` method does not exist.

- [ ] **Step 3: Update BrowserClient.init to accept launcher**

In `BrowserClient.cfc`, update the `init` method and add `getLauncher`:

```cfm
variables.page = "";
variables.context = "";
variables.baseUrl = "";
variables.$launcher = "";

public BrowserClient function init(
    any page = "",
    any context = "",
    string baseUrl = "",
    any launcher = ""
) {
    variables.page = arguments.page;
    variables.context = arguments.context;
    variables.baseUrl = arguments.baseUrl;
    variables.$launcher = arguments.launcher;
    return this;
}

public any function getLauncher() {
    return variables.$launcher;
}
```

- [ ] **Step 4: Update BrowserTest to pass launcher**

In `BrowserTest.cfc`, update `$startBrowserContext` to pass the launcher:

```cfm
this.browser = new wheels.wheelstest.BrowserClient().init(
    page=variables.$page,
    context=variables.$context,
    baseUrl=variables.$baseUrl,
    launcher=variables.$launcher
);
```

Also update `within()` in `BrowserClient.cfc` to propagate the launcher to scoped clients:

```cfm
public BrowserClient function within(
    required string selector,
    required any callback
) {
    var scoped = new wheels.wheelstest.BrowserClient()
        .init(
            page=variables.page,
            context=variables.context,
            baseUrl=variables.baseUrl,
            launcher=variables.$launcher
        );
    scoped.$setScope(variables.page.locator(arguments.selector).first());
    arguments.callback(scoped);
    return this;
}
```

- [ ] **Step 5: Update integration test setup to pass launcher**

In `BrowserIntegrationSpec.cfc`, find where BrowserClient `bc` is created in the integration test setup. Update it to pass the launcher. The launcher is the same application-scoped instance used by BrowserTest. Access it via:

```cfm
var launcherRef = application.wheelsBrowserLauncher ?: "";
// When creating bc for integration tests:
bc = new wheels.wheelstest.BrowserClient().init(
    page=testPage,
    context=testContext,
    baseUrl="",
    launcher=launcherRef
);
```

- [ ] **Step 6: Run tests, verify pass**

Expected: all tests PASS including new `getLauncher()` test.

- [ ] **Step 7: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc vendor/wheels/wheelstest/BrowserTest.cfc vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): wire launcher reference into BrowserClient

BrowserClient.init now accepts a launcher parameter. BrowserTest passes
the application-scoped launcher, and within() propagates it to scoped
clients. Enables DSL methods to call \$buildOption for Playwright options."
```

---

## Task 3: Configurable Timeouts on waitFor / waitForText

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Test: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Write failing test**

Add to `BrowserIntegrationSpec.cfc` inside the existing "waiting" describe:

```cfm
it("waitFor honors custom timeout (short timeout fails on missing element)", () => {
    if (skipBrowserTests) return;
    bc.visitUrl("data:text/html,<h1>No target here</h1>");
    expect(() => {
        bc.waitFor("##never-exists", 1);
    }).toThrow();
});

it("waitForText honors custom timeout (short timeout fails on missing text)", () => {
    if (skipBrowserTests) return;
    bc.visitUrl("data:text/html,<h1>Hello</h1>");
    expect(() => {
        bc.waitForText("never appears", 1);
    }).toThrow();
});
```

- [ ] **Step 2: Run test, verify behavior**

These tests might already pass with the current default 30s timeout (Playwright would wait 30s then fail). But with `seconds=1`, the test should fail/timeout much faster — within ~1s instead of ~30s. The test verifies the timeout is actually applied. If the test takes ~30s, the custom timeout isn't being honored.

Run and time it:
```bash
time curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.wheelstest" > /dev/null
```

- [ ] **Step 3: Update waitFor and waitForText**

In `BrowserClient.cfc`, replace the existing `waitFor` method:

```cfm
public BrowserClient function waitFor(
    required string selector,
    numeric seconds = 30
) {
    var loc = $locator(arguments.selector).first();
    if (arguments.seconds != 30 && isObject(variables.$launcher)) {
        var opts = variables.$launcher.$buildOption(
            className="com.microsoft.playwright.Locator$WaitForOptions",
            setterMap={setTimeout: arguments.seconds * 1000}
        );
        loc.waitFor(opts);
    } else {
        loc.waitFor();
    }
    return this;
}
```

Replace the existing `waitForText` method:

```cfm
public BrowserClient function waitForText(
    required string text,
    numeric seconds = 30
) {
    var loc = variables.page.getByText(arguments.text).first();
    if (arguments.seconds != 30 && isObject(variables.$launcher)) {
        var opts = variables.$launcher.$buildOption(
            className="com.microsoft.playwright.Locator$WaitForOptions",
            setterMap={setTimeout: arguments.seconds * 1000}
        );
        loc.waitFor(opts);
    } else {
        loc.waitFor();
    }
    return this;
}
```

- [ ] **Step 4: Run tests, verify pass**

The timeout tests should now complete in ~1s (not 30s) and throw as expected. All existing waitFor/waitForText tests should still pass.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): add configurable timeouts to waitFor and waitForText

Uses \$buildOption to construct Locator\$WaitForOptions when a non-default
timeout is specified. Zero-arg fast path preserved for default 30s."
```

---

## Task 4: waitForUrl

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Test: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Write failing test**

Add to `BrowserIntegrationSpec.cfc`:

```cfm
describe("waitForUrl", () => {

    it("resolves immediately when URL already matches", () => {
        if (skipBrowserTests) return;
        bc.visitUrl("data:text/html,<h1>Here</h1>");
        bc.waitForUrl("data:text/html,*", 5);
        // No throw = success
    });

    it("throws on timeout when URL does not match", () => {
        if (skipBrowserTests) return;
        bc.visitUrl("data:text/html,<h1>Here</h1>");
        expect(() => {
            bc.waitForUrl("http://will-never-match.example.com/**", 1);
        }).toThrow();
    });

});
```

- [ ] **Step 2: Run test, verify failure**

Expected: FAIL — `waitForUrl` method does not exist.

- [ ] **Step 3: Implement waitForUrl**

Add to `BrowserClient.cfc` after the `waitForText` method:

```cfm
/**
 * Waits for the page URL to match the given pattern. Supports exact
 * strings and glob patterns (Playwright native).
 */
public BrowserClient function waitForUrl(
    required string url,
    numeric seconds = 30
) {
    if (arguments.seconds != 30 && isObject(variables.$launcher)) {
        var opts = variables.$launcher.$buildOption(
            className="com.microsoft.playwright.Page$WaitForURLOptions",
            setterMap={setTimeout: arguments.seconds * 1000}
        );
        variables.page.waitForURL(arguments.url, opts);
    } else {
        variables.page.waitForURL(arguments.url);
    }
    return this;
}
```

- [ ] **Step 4: Run tests, verify pass**

Expected: both waitForUrl tests PASS.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): add waitForUrl DSL method

Waits for page URL to match a string or glob pattern. Uses
Page\$WaitForURLOptions for configurable timeout via \$buildOption."
```

---

## Task 5: Screenshot Options

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Test: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Write failing test**

Add to `BrowserIntegrationSpec.cfc` in the existing "screenshot" describe:

```cfm
it("screenshot with fullPage option writes a PNG file", () => {
    if (skipBrowserTests) return;
    bc.visitUrl("data:text/html,<div style='height:2000px'>Tall page</div>");
    var outPath = expandPath("/tests/_output/test_fullpage_screenshot.png");
    bc.screenshot(path=outPath, fullPage=true);
    expect(fileExists(outPath)).toBeTrue();
    expect(fileReadBinary(outPath).len()).toBeGT(0);
    // Cleanup
    fileDelete(outPath);
});
```

- [ ] **Step 2: Run test, verify failure**

Expected: FAIL — `screenshot` doesn't accept `fullPage` argument (or it's ignored and no option is built).

- [ ] **Step 3: Update screenshot method**

In `BrowserClient.cfc`, replace the existing `screenshot` method:

```cfm
/**
 * Screenshot to `path`. When fullPage or quality are specified, builds
 * Page$ScreenshotOptions via $buildOption. Otherwise uses the fast path
 * (no-arg screenshot → byte[] → fileWrite).
 */
public BrowserClient function screenshot(
    required string path,
    boolean fullPage = false,
    numeric quality = 0
) {
    if ((arguments.fullPage || arguments.quality > 0) && isObject(variables.$launcher)) {
        var emptyStringArr = javaCast("String[]", []);
        var pathObj = createObject("java", "java.nio.file.Paths")
            .get(arguments.path, emptyStringArr);
        var setters = {setPath: pathObj};
        if (arguments.fullPage) {
            setters["setFullPage"] = true;
        }
        if (arguments.quality > 0) {
            setters["setQuality"] = arguments.quality;
        }
        var opts = variables.$launcher.$buildOption(
            className="com.microsoft.playwright.Page$ScreenshotOptions",
            setterMap=setters
        );
        variables.page.screenshot(opts);
    } else {
        var bytes = variables.page.screenshot();
        fileWrite(arguments.path, bytes);
    }
    return this;
}
```

- [ ] **Step 4: Run tests, verify pass**

Expected: new fullPage test PASS, existing screenshot test still PASS.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): add screenshot options (fullPage, quality)

Builds Page\$ScreenshotOptions via \$buildOption when non-default options
are specified. Zero-arg fast path preserved for simple screenshots."
```

---

## Task 6: Cookie DSL Methods

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Test: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

Cookie tests require a real HTTP origin (not `data:` URLs). They use `baseUrl` (the test runner at localhost:8080) which is always running during test execution.

- [ ] **Step 1: Write failing tests**

Add to `BrowserIntegrationSpec.cfc`:

```cfm
describe("cookies", () => {

    it("setCookie sets a cookie and cookie() reads it back", () => {
        if (skipBrowserTests) return;
        // Need a real HTTP origin for cookies — use the test runner
        var testUrl = bc.getBaseUrl();
        if (!len(testUrl)) {
            // No server running — skip
            return;
        }
        bc.visitUrl(testUrl);
        bc.setCookie(name="testCookie", value="hello123", url=testUrl);
        var c = bc.cookie("testCookie");
        expect(c.name).toBe("testCookie");
        expect(c.value).toBe("hello123");
    });

    it("deleteCookie removes a specific cookie", () => {
        if (skipBrowserTests) return;
        var testUrl = bc.getBaseUrl();
        if (!len(testUrl)) return;
        bc.visitUrl(testUrl);
        bc.setCookie(name="toDelete", value="bye", url=testUrl);
        // Verify it exists
        var c = bc.cookie("toDelete");
        expect(c.value).toBe("bye");
        // Delete it
        bc.deleteCookie("toDelete");
        // Verify it's gone
        expect(() => {
            bc.cookie("toDelete");
        }).toThrow("Wheels.BrowserAssertionFailed");
    });

    it("cookie() throws when cookie not found", () => {
        if (skipBrowserTests) return;
        var testUrl = bc.getBaseUrl();
        if (!len(testUrl)) return;
        bc.visitUrl(testUrl);
        expect(() => {
            bc.cookie("nonexistent_cookie_xyz");
        }).toThrow("Wheels.BrowserAssertionFailed");
    });

    it("setCookie is chainable", () => {
        if (skipBrowserTests) return;
        var testUrl = bc.getBaseUrl();
        if (!len(testUrl)) return;
        bc.visitUrl(testUrl);
        var result = bc.setCookie(name="chain1", value="a", url=testUrl)
            .setCookie(name="chain2", value="b", url=testUrl);
        expect(result).toBeInstanceOf("wheels.wheelstest.BrowserClient");
    });

});
```

- [ ] **Step 2: Run test, verify failure**

Expected: FAIL — `setCookie`, `deleteCookie`, `cookie` methods do not exist.

- [ ] **Step 3: Implement cookie methods**

Add to `BrowserClient.cfc` after the scoping section:

```cfm
// ─── Cookies ─────────────────────────────────────────────────────

/**
 * Set a cookie on the current browser context. Requires the page to
 * have been navigated to a real HTTP origin (not data: URLs).
 */
public BrowserClient function setCookie(
    required string name,
    required string value,
    required string url
) {
    var cookieObj = variables.$launcher.$buildOption(
        className="com.microsoft.playwright.options.Cookie",
        constructorArgs=[arguments.name, arguments.value],
        setterMap={setUrl: arguments.url}
    );
    var cookieList = createObject("java", "java.util.Collections")
        .singletonList(cookieObj);
    variables.context.addCookies(cookieList);
    return this;
}

/**
 * Delete a specific cookie by name from the browser context.
 */
public BrowserClient function deleteCookie(required string name) {
    var opts = variables.$launcher.$buildOption(
        className="com.microsoft.playwright.BrowserContext$ClearCookiesOptions",
        setterMap={setName: arguments.name}
    );
    variables.context.clearCookies(opts);
    return this;
}

/**
 * Read a cookie by name from the browser context. Returns a struct
 * with name, value, domain, path, expires, httpOnly, secure.
 * Throws BrowserAssertionFailed if cookie not found.
 */
public struct function cookie(required string name) {
    var cookies = variables.context.cookies();
    for (var i = 0; i < cookies.size(); i++) {
        var c = cookies.get(javaCast("int", i));
        if (c.name == arguments.name) {
            return {
                name: c.name,
                value: c.value,
                domain: c.domain ?: "",
                path: c.path ?: "",
                expires: c.expires ?: -1,
                httpOnly: c.httpOnly ?: false,
                secure: c.secure ?: false
            };
        }
    }
    $assertFail("Cookie '" & arguments.name & "' not found");
}
```

- [ ] **Step 4: Run tests, verify pass**

Expected: all cookie tests PASS (requires Playwright installed AND test runner server running).

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): add cookie DSL methods (setCookie, deleteCookie, cookie)

Uses \$buildOption to construct Cookie and ClearCookiesOptions objects.
Requires a real HTTP origin; data: URLs don't support cookies."
```

---

## Task 7: Viewport Config at BrowserTest Level

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserTest.cfc`
- Test: `vendor/wheels/tests/specs/wheelstest/BrowserTestLifecycleSpec.cfc`

- [ ] **Step 1: Write failing test**

Add to `BrowserTestLifecycleSpec.cfc`:

```cfm
describe("viewport config", () => {

    it("applies mobile viewport preset when this.browserViewport is set", () => {
        if (this.browserTestSkipped) return;
        // Save original and set viewport
        var original = this.browserViewport ?: "";
        this.browserViewport = "mobile";

        // Re-create browser context with viewport config
        this.$endBrowserContext();
        this.$startBrowserContext();

        this.browser.visitUrl("data:text/html,<h1>Test</h1>");
        var width = this.browser.script("() => window.innerWidth");
        expect(width).toBe(375);

        // Restore
        this.browserViewport = original;
        this.$endBrowserContext();
        this.$startBrowserContext();
    });

    it("applies custom viewport dimensions from struct", () => {
        if (this.browserTestSkipped) return;
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
```

- [ ] **Step 2: Run test, verify failure**

Expected: FAIL — viewport is not applied (dimensions don't match).

- [ ] **Step 3: Implement viewport config**

In `BrowserTest.cfc`, update `$startBrowserContext`:

```cfm
public void function $startBrowserContext() {
    if (this.browserTestSkipped) return;

    // Build context options if viewport is configured
    var contextOpts = $buildContextOptions();

    if (isObject(contextOpts)) {
        variables.$context = variables.$browser.newContext(contextOpts);
    } else {
        variables.$context = variables.$browser.newContext();
    }
    variables.$page = variables.$context.newPage();
    this.browser = new wheels.wheelstest.BrowserClient().init(
        page=variables.$page,
        context=variables.$context,
        baseUrl=variables.$baseUrl,
        launcher=variables.$launcher
    );
}
```

Add the viewport resolution helper:

```cfm
/**
 * Builds Browser$NewContextOptions if viewport config is set.
 * Returns the options object, or empty string if no config.
 */
private any function $buildContextOptions() {
    if (!structKeyExists(this, "browserViewport") || !len(this.browserViewport ?: "")) {
        return "";
    }

    var dims = $resolveViewportDims(this.browserViewport);

    var viewport = variables.$launcher.$buildOption(
        className="com.microsoft.playwright.options.ViewportSize",
        constructorArgs=[dims.width, dims.height]
    );

    return variables.$launcher.$buildOption(
        className="com.microsoft.playwright.Browser$NewContextOptions",
        setterMap={setViewportSize: viewport}
    );
}

/**
 * Resolve viewport config to {width, height} struct.
 * Accepts preset strings ("mobile", "tablet", "desktop") or a struct.
 */
private struct function $resolveViewportDims(required any viewport) {
    if (isSimpleValue(arguments.viewport)) {
        switch (lCase(arguments.viewport)) {
            case "mobile":
                return {width: 375, height: 667};
            case "tablet":
                return {width: 768, height: 1024};
            case "desktop":
                return {width: 1440, height: 900};
            default:
                throw(
                    type="Wheels.BrowserViewportInvalid",
                    message="Unknown viewport preset: " & arguments.viewport
                        & ". Valid: mobile, tablet, desktop"
                );
        }
    }
    return {
        width: arguments.viewport.width ?: 1440,
        height: arguments.viewport.height ?: 900
    };
}
```

Also add the default property at the top of `BrowserTest.cfc` (near `this.browserEngine`):

```cfm
this.browserViewport = "";  // empty = use Playwright default; "mobile"/"tablet"/"desktop" or {width:N, height:N}
```

- [ ] **Step 4: Run tests, verify pass**

Expected: viewport tests PASS. All existing lifecycle tests still PASS.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserTest.cfc vendor/wheels/tests/specs/wheelstest/BrowserTestLifecycleSpec.cfc
git commit -m "feat(test): add viewport config at BrowserTest level

Spec CFCs can set this.browserViewport to a preset string or
{width, height} struct. Builds ViewportSize + NewContextOptions
via \$buildOption for each new browser context."
```

---

## Task 8: Auto-Screenshot on Failure

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserTest.cfc`
- Test: `vendor/wheels/tests/specs/wheelstest/BrowserTestLifecycleSpec.cfc`

- [ ] **Step 1: Write failing tests**

Add to `BrowserTestLifecycleSpec.cfc`:

```cfm
describe("auto-screenshot on failure", () => {

    it("$captureFailureArtifacts writes screenshot and HTML", () => {
        if (this.browserTestSkipped) return;
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

        // Cleanup
        directoryDelete(testDir, true);
        structDelete(this, "browserArtifactPath");
    });

    it("respects browserScreenshotOnFailure=false", () => {
        if (this.browserTestSkipped) return;
        this.browser.visitUrl("data:text/html,<h1>No Capture</h1>");

        var testDir = expandPath("/tests/_output/browser_optout_test");
        this.browserArtifactPath = testDir;
        this.browserScreenshotOnFailure = false;

        var fakeSpec = {name: "test_optout"};
        this.$captureFailureArtifacts(fakeSpec);

        expect(directoryExists(testDir)).toBeFalse();

        // Restore
        this.browserScreenshotOnFailure = true;
        structDelete(this, "browserArtifactPath");
    });

});
```

- [ ] **Step 2: Run test, verify failure**

Expected: FAIL — `$captureFailureArtifacts` does not exist.

- [ ] **Step 3: Implement `$captureFailureArtifacts` and aroundEach**

Add default property at top of `BrowserTest.cfc`:

```cfm
this.browserScreenshotOnFailure = true;
```

Add the capture method:

```cfm
/**
 * Best-effort capture of screenshot + HTML on test failure.
 * Called from aroundEach catch block. Swallows all errors to avoid
 * masking the real test failure.
 */
public void function $captureFailureArtifacts(required any spec) {
    if (!(this.browserScreenshotOnFailure ?: true)) return;
    if (!isObject(this.browser) || this.browserTestSkipped) return;

    try {
        var artifactDir = this.browserArtifactPath
            ?: expandPath("/tests/_output/browser");

        if (!directoryExists(artifactDir)) {
            directoryCreate(artifactDir, true);
        }

        var rawName = arguments.spec.name ?: "unknown_spec";
        var safeName = reReplace(rawName, "[^a-zA-Z0-9_\-]", "_", "all");
        if (len(safeName) > 80) safeName = left(safeName, 80);
        var ts = dateFormat(now(), "yyyymmdd") & "_" & timeFormat(now(), "HHmmss");
        var baseName = safeName & "-" & ts;

        this.browser.screenshot(path=artifactDir & "/" & baseName & ".png");
        fileWrite(artifactDir & "/" & baseName & ".html", this.browser.pageSource());
    } catch (any e) {
        // Best-effort: page may have crashed, context may be closed.
        // Swallow to avoid masking the real test failure.
    }
}
```

Update `browserDescribe` to add `aroundEach`:

```cfm
public void function browserDescribe(required string title, required any body) {
    var me = this;
    var innerBody = arguments.body;

    describe(arguments.title, () => {
        beforeEach(() => {
            me.$startBrowserContext();
        });

        aroundEach(function(spec, suite) {
            if (me.browserTestSkipped) {
                arguments.spec.body();
                return;
            }
            try {
                arguments.spec.body();
            } catch (any e) {
                me.$captureFailureArtifacts(arguments.spec);
                rethrow;
            }
        });

        afterEach(() => {
            me.$endBrowserContext();
        });

        innerBody();
    });
}
```

- [ ] **Step 4: Run tests, verify pass**

Expected: both auto-screenshot tests PASS. All existing lifecycle tests still PASS.

**Fallback note:** If `aroundEach` doesn't work inside `browserDescribe`'s dynamically-registered describe body, fall back to setting a caught-error flag in `afterEach`:

```cfm
// Alternative: track failure in afterEach instead of aroundEach
afterEach(() => {
    // TestBox sets spec.status before afterEach runs
    // Check if the current spec failed and capture if so
    me.$endBrowserContext();
});
```

But try `aroundEach` first — it's cleaner and follows the same registration pattern as `beforeEach`/`afterEach` which already work.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserTest.cfc vendor/wheels/tests/specs/wheelstest/BrowserTestLifecycleSpec.cfc
git commit -m "feat(test): add auto-screenshot and HTML dump on test failure

browserDescribe registers aroundEach to capture artifacts on failure.
Screenshot + HTML written to tests/_output/browser/. Opt-out via
this.browserScreenshotOnFailure = false."
```

---

## Task 9: BrowserService for CLI

**Files:**
- Create: `cli/src/models/BrowserService.cfc`

- [ ] **Step 1: Create BrowserService.cfc**

```bash
ls /Users/peter/GitHub/wheels-dev/wheels/cli/src/models/
```

Verify the models directory exists, then create:

```cfm
/**
 * Shared service for Playwright browser JAR management.
 * Used by both browser:install and browser:test CLI commands.
 */
component {

    /**
     * Read and parse browser-manifest.json from the project.
     */
    public struct function getManifest(required string projectRoot) {
        var manifestPath = arguments.projectRoot & "/vendor/wheels/browser-manifest.json";
        if (!fileExists(manifestPath)) {
            throw(
                type="BrowserService.ManifestMissing",
                message="browser-manifest.json not found at: " & manifestPath
            );
        }
        return deserializeJSON(fileRead(manifestPath));
    }

    /**
     * Resolve install directory from env var or default.
     */
    public string function resolveInstallDir() {
        var envHome = "";
        try {
            envHome = createObject("java", "java.lang.System")
                .getenv("WHEELS_BROWSER_HOME") ?: "";
        } catch (any e) {}
        if (len(trim(envHome))) return envHome;

        var home = createObject("java", "java.lang.System").getProperty("user.home");
        return home & "/.wheels/browser";
    }

    /**
     * Check if all JARs are installed and SHAs match.
     * Returns {installed: boolean, missing: [], mismatched: []}.
     */
    public struct function verifyInstall(
        required struct manifest,
        required string installDir
    ) {
        var result = {installed: true, missing: [], mismatched: []};
        for (var entry in arguments.manifest.classpath) {
            var jarPath = arguments.installDir & "/lib/" & entry.filename;
            if (!fileExists(jarPath)) {
                result.installed = false;
                arrayAppend(result.missing, entry.filename);
            } else if (sha256(jarPath) != lCase(entry.sha256)) {
                result.installed = false;
                arrayAppend(result.mismatched, entry.filename);
            }
        }
        return result;
    }

    /**
     * Download a single JAR from its manifest URL to the target path.
     */
    public void function downloadJar(
        required string url,
        required string targetPath
    ) {
        var parentDir = getDirectoryFromPath(arguments.targetPath);
        if (!directoryExists(parentDir)) {
            directoryCreate(parentDir, true);
        }
        cfhttp(
            url=arguments.url,
            method="GET",
            getAsBinary="yes",
            timeout=300,
            result="local.response"
        );
        if (!findNoCase("200", local.response.statusCode)) {
            throw(
                type="BrowserService.DownloadFailed",
                message="HTTP " & local.response.statusCode & " downloading " & arguments.url
            );
        }
        fileWrite(arguments.targetPath, local.response.fileContent);
    }

    /**
     * SHA-256 hash of a file, lowercase hex.
     */
    public string function sha256(required string filePath) {
        var md = createObject("java", "java.security.MessageDigest")
            .getInstance("SHA-256");
        var digest = md.digest(fileReadBinary(arguments.filePath));
        return lCase(
            createObject("java", "java.util.HexFormat").of().formatHex(digest)
        );
    }

}
```

- [ ] **Step 2: Commit**

```bash
git add cli/src/models/BrowserService.cfc
git commit -m "feat(cli): add BrowserService for JAR management

Shared service for manifest reading, install verification, JAR download
with SHA-256 verification. Used by browser:install and browser:test."
```

---

## Task 10: CommandBox `wheels browser:install`

**Files:**
- Create: `cli/src/commands/wheels/browser/install.cfc`

- [ ] **Step 1: Create the command**

First verify the directory:
```bash
ls /Users/peter/GitHub/wheels-dev/wheels/cli/src/commands/wheels/
mkdir -p /Users/peter/GitHub/wheels-dev/wheels/cli/src/commands/wheels/browser
```

Create `cli/src/commands/wheels/browser/install.cfc`:

```cfm
/**
 * Install Playwright browser binaries for E2E testing.
 *
 * Downloads 7 JARs from Maven Central (Playwright client + driver +
 * driver-bundle + transitive deps), verifies SHA-256 hashes, then
 * installs browser binaries via the Playwright CLI.
 *
 * Examples:
 *   wheels browser:install
 *   wheels browser:install --force
 *   wheels browser:install --browser=firefox
 */
component aliases="wheels browser:install, wheels browser install" extends="../../base" {

    property name="browserService" inject="BrowserService@wheels-cli";

    /**
     * @force     Re-download JARs even if SHAs match
     * @browser   Which browser to install (chromium, firefox, webkit)
     */
    function run(
        boolean force = false,
        string browser = "chromium"
    ) {
        var projectRoot = getCWD();
        var manifest = {};
        try {
            manifest = browserService.getManifest(projectRoot);
        } catch (any e) {
            print.redLine("Error: " & e.message);
            return;
        }

        var installDir = browserService.resolveInstallDir();
        print.line("Install directory: " & installDir);
        print.line("Playwright version: " & (manifest.playwrightJavaVersion ?: "unknown"));
        print.line("");

        // Download JARs
        var downloaded = 0;
        var skipped = 0;
        for (var entry in manifest.classpath) {
            var jarPath = installDir & "/lib/" & entry.filename;
            var needsDownload = arguments.force;

            if (!fileExists(jarPath)) {
                needsDownload = true;
            } else if (!arguments.force) {
                var currentSha = browserService.sha256(jarPath);
                if (currentSha != lCase(entry.sha256)) {
                    print.yellowLine("  SHA mismatch: " & entry.filename & " — re-downloading");
                    needsDownload = true;
                }
            }

            if (needsDownload) {
                print.text("  Downloading " & entry.filename & "...");
                try {
                    browserService.downloadJar(url=entry.url, targetPath=jarPath);
                    // Verify SHA after download
                    var sha = browserService.sha256(jarPath);
                    if (sha != lCase(entry.sha256)) {
                        print.redLine(" FAILED (SHA mismatch)");
                        print.redLine("    Expected: " & lCase(entry.sha256));
                        print.redLine("    Got:      " & sha);
                        return;
                    }
                    print.greenLine(" OK");
                    downloaded++;
                } catch (any e) {
                    print.redLine(" FAILED: " & e.message);
                    return;
                }
            } else {
                print.line("  " & chr(10003) & " " & entry.filename);
                skipped++;
            }
        }

        print.line("");
        print.line("JARs: #downloaded# downloaded, #skipped# up-to-date");

        // Install browser binaries
        print.line("");
        print.text("Installing #arguments.browser# browser binaries...");

        var classpath = "";
        for (var entry in manifest.classpath) {
            if (len(classpath)) classpath &= (server.os.name contains "Windows" ? ";" : ":");
            classpath &= installDir & "/lib/" & entry.filename;
        }

        try {
            cfexecute(
                name="java",
                arguments="-cp #classpath# com.microsoft.playwright.CLI install #arguments.browser#",
                timeout=300,
                variable="local.stdout",
                errorVariable="local.stderr"
            );
            print.greenLine(" OK");
        } catch (any e) {
            print.redLine(" FAILED");
            print.redLine(local.stderr ?: e.message);
            return;
        }

        print.line("");
        print.greenLine("Browser testing ready. Run: wheels browser:test");
    }

}
```

- [ ] **Step 2: Test manually**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels
box reload
box wheels browser:install
```

Expected: Downloads JARs (or shows checkmarks if already installed), installs Chromium.

- [ ] **Step 3: Commit**

```bash
git add cli/src/commands/wheels/browser/install.cfc
git commit -m "feat(cli): add wheels browser:install command

Downloads Playwright JARs with SHA-256 verification and installs
browser binaries. Replaces tools/install-playwright.sh."
```

---

## Task 11: CommandBox `wheels browser:test`

**Files:**
- Create: `cli/src/commands/wheels/browser/test.cfc`

- [ ] **Step 1: Create the command**

Create `cli/src/commands/wheels/browser/test.cfc`:

```cfm
/**
 * Run browser-based E2E tests.
 *
 * Pre-flight checks that Playwright JARs are installed, then hits
 * the test runner URL scoped to browser test specs.
 *
 * Examples:
 *   wheels browser:test
 *   wheels browser:test --verbose
 *   wheels browser:test --format=json
 */
component aliases="wheels browser:test, wheels browser test" extends="../../base" {

    property name="browserService" inject="BrowserService@wheels-cli";

    /**
     * @format    Output format: text or json
     * @verbose   Show full spec names
     * @directory Test directory (dot-notation, relative to vendor/wheels/)
     */
    function run(
        string format = "text",
        boolean verbose = false,
        string directory = "wheels.tests.specs.wheelstest"
    ) {
        var projectRoot = getCWD();

        // Pre-flight: verify JARs installed
        try {
            var manifest = browserService.getManifest(projectRoot);
            var installDir = browserService.resolveInstallDir();
            var status = browserService.verifyInstall(
                manifest=manifest,
                installDir=installDir
            );
            if (!status.installed) {
                print.redLine("Playwright not installed.");
                if (arrayLen(status.missing)) {
                    print.yellowLine("Missing: " & arrayToList(status.missing, ", "));
                }
                if (arrayLen(status.mismatched)) {
                    print.yellowLine("SHA mismatch: " & arrayToList(status.mismatched, ", "));
                }
                print.line("");
                print.line("Run: wheels browser:install");
                return;
            }
        } catch (any e) {
            print.redLine("Error: " & e.message);
            return;
        }

        print.line("Running browser tests...");
        print.line("Directory: " & arguments.directory);
        print.line("");

        // Determine server URL
        var serverInfo = command("server info").params(property="host").run(returnOutput=true);
        var port = command("server info").params(property="port").run(returnOutput=true);
        var host = trim(serverInfo) ?: "localhost";
        var portNum = trim(port) ?: "8080";
        var baseUrl = "http://#host#:#portNum#";

        var testUrl = baseUrl
            & "/wheels/core/tests?db=sqlite&format=json&directory="
            & arguments.directory;

        try {
            cfhttp(url=testUrl, method="GET", timeout=300, result="local.response");
        } catch (any e) {
            print.redLine("Failed to reach test runner at: " & testUrl);
            print.redLine("Is the server running? Try: server start");
            return;
        }

        if (arguments.format == "json") {
            print.line(local.response.fileContent);
            return;
        }

        // Parse and display results
        try {
            var data = deserializeJSON(local.response.fileContent);
            print.line("Pass: #data.totalPass#  Fail: #data.totalFail#  Error: #data.totalError#");
            print.line("");

            // Show failures
            for (var bundle in (data.bundleStats ?: [])) {
                for (var suite in (bundle.suiteStats ?: [])) {
                    for (var spec in (suite.specStats ?: [])) {
                        if (listFindNoCase("Failed,Error", spec.status ?: "")) {
                            print.redLine(
                                "  " & (spec.status ?: "") & ": "
                                & (spec.name ?: "unknown")
                            );
                            if (arguments.verbose && len(spec.failMessage ?: "")) {
                                print.line("    " & left(spec.failMessage, 200));
                            }
                        }
                    }
                }
            }

            if (data.totalFail == 0 && data.totalError == 0) {
                print.greenLine("All browser tests passed.");
            }
        } catch (any e) {
            print.redLine("Failed to parse test results: " & e.message);
            if (arguments.verbose) {
                print.line(left(local.response.fileContent ?: "", 500));
            }
        }
    }

}
```

- [ ] **Step 2: Test manually**

```bash
box reload
box wheels browser:test
box wheels browser:test --verbose
box wheels browser:test --format=json
```

- [ ] **Step 3: Commit**

```bash
git add cli/src/commands/wheels/browser/test.cfc
git commit -m "feat(cli): add wheels browser:test command

Pre-flight JAR verification, then runs browser test directory via
the test runner URL. Supports text/json output and verbose mode."
```

---

## Task 12: LuCLI `browser` Subcommand

**Files:**
- Modify: `cli/lucli/Module.cfc`

- [ ] **Step 1: Add `browser()` public function**

Find the end of the existing public functions in `Module.cfc` (after the last `public string function`) and add:

```cfm
// ─────────────────────────────────────────────────
//  browser — Browser testing management
// ─────────────────────────────────────────────────

/**
 * hint: Browser testing commands (install, test)
 */
public string function browser() {
    var args = getArgs(arguments);

    if (!arrayLen(args)) {
        out("Usage: wheels browser <command>", "yellow");
        out("");
        out("Commands:", "bold");
        out("  install  Download Playwright JARs and browser binaries");
        out("  test     Run browser test suite");
        out("");
        out("Examples:", "bold");
        out("  wheels browser install");
        out("  wheels browser install --force");
        out("  wheels browser test");
        out("  wheels browser test --verbose");
        return "";
    }

    var subcommand = lCase(args[1]);

    switch (subcommand) {
        case "install":
            return browserInstall(args);
        case "test":
            return browserTest(args);
        default:
            out("Unknown browser command: #subcommand#", "red");
            out("Valid commands: install, test");
            return "";
    }
}
```

- [ ] **Step 2: Add `browserInstall()` private method**

```cfm
/**
 * Download Playwright JARs and install browser binaries.
 */
private string function browserInstall(array args = []) {
    var force = false;
    var browserName = "chromium";
    for (var arg in arguments.args) {
        if (arg == "--force") force = true;
        if (left(arg, 10) == "--browser=") browserName = mid(arg, 11, len(arg));
    }

    var manifestPath = variables.projectRoot & "/vendor/wheels/browser-manifest.json";
    if (!fileExists(manifestPath)) {
        out("browser-manifest.json not found at: #manifestPath#", "red");
        return "";
    }
    var manifest = deserializeJSON(fileRead(manifestPath));

    var installDir = $resolveBrowserInstallDir();
    out("Install directory: #installDir#");
    out("Playwright version: #manifest.playwrightJavaVersion ?: 'unknown'#");
    out("");

    var libDir = installDir & "/lib";
    if (!directoryExists(libDir)) directoryCreate(libDir, true);

    var downloaded = 0;
    var skipped = 0;
    for (var entry in manifest.classpath) {
        var jarPath = libDir & "/" & entry.filename;
        var needsDownload = force;

        if (!fileExists(jarPath)) {
            needsDownload = true;
        } else if (!force && $sha256(jarPath) != lCase(entry.sha256)) {
            out("  SHA mismatch: #entry.filename# - re-downloading", "yellow");
            needsDownload = true;
        }

        if (needsDownload) {
            out("  Downloading #entry.filename#...", "");
            try {
                cfhttp(url=entry.url, method="GET", getAsBinary="yes", timeout=300, result="local.dl");
                if (!findNoCase("200", local.dl.statusCode)) {
                    out(" FAILED (HTTP #local.dl.statusCode#)", "red");
                    return "";
                }
                fileWrite(jarPath, local.dl.fileContent);
                if ($sha256(jarPath) != lCase(entry.sha256)) {
                    out(" FAILED (SHA mismatch after download)", "red");
                    return "";
                }
                out("  #entry.filename# OK", "green");
                downloaded++;
            } catch (any e) {
                out(" FAILED: #e.message#", "red");
                return "";
            }
        } else {
            out("  #chr(10003)# #entry.filename#");
            skipped++;
        }
    }

    out("");
    out("JARs: #downloaded# downloaded, #skipped# up-to-date");

    // Install browser
    out("");
    out("Installing #browserName# browser binaries...");
    var cp = "";
    for (var entry in manifest.classpath) {
        if (len(cp)) cp &= ":";
        cp &= libDir & "/" & entry.filename;
    }
    try {
        cfexecute(
            name="java",
            arguments="-cp #cp# com.microsoft.playwright.CLI install #browserName#",
            timeout=300,
            variable="local.stdout",
            errorVariable="local.stderr"
        );
        out("Browser install complete.", "green");
    } catch (any e) {
        out("Browser install failed: #local.stderr ?: e.message#", "red");
        return "";
    }

    out("");
    out("Browser testing ready. Run: wheels browser test", "green");
    return "";
}
```

- [ ] **Step 3: Add `browserTest()` private method**

```cfm
/**
 * Run browser test suite.
 */
private string function browserTest(array args = []) {
    var format = "text";
    var verboseOutput = false;
    var directory = "wheels.tests.specs.wheelstest";
    for (var arg in arguments.args) {
        if (arg == "--verbose") verboseOutput = true;
        if (arg == "--json" || arg == "--format=json") format = "json";
        if (left(arg, 12) == "--directory=") directory = mid(arg, 13, len(arg));
    }

    // Pre-flight: check JARs
    var manifestPath = variables.projectRoot & "/vendor/wheels/browser-manifest.json";
    if (!fileExists(manifestPath)) {
        out("browser-manifest.json not found.", "red");
        return "";
    }
    var manifest = deserializeJSON(fileRead(manifestPath));
    var installDir = $resolveBrowserInstallDir();
    for (var entry in manifest.classpath) {
        if (!fileExists(installDir & "/lib/" & entry.filename)) {
            out("Playwright not installed. Missing: #entry.filename#", "red");
            out("Run: wheels browser install");
            return "";
        }
    }

    // Resolve server URL
    var port = $getServerPort();
    var testUrl = "http://localhost:#port#/wheels/core/tests?db=sqlite&format=json&directory=#directory#";

    out("Running browser tests...");
    out("URL: #testUrl#");
    out("");

    try {
        cfhttp(url=testUrl, method="GET", timeout=300, result="local.response");
    } catch (any e) {
        out("Failed to reach test runner. Is the server running?", "red");
        return "";
    }

    if (format == "json") {
        out(local.response.fileContent);
        return "";
    }

    try {
        var data = deserializeJSON(local.response.fileContent);
        out("Pass: #data.totalPass#  Fail: #data.totalFail#  Error: #data.totalError#");
        out("");

        for (var bundle in (data.bundleStats ?: [])) {
            for (var suite in (bundle.suiteStats ?: [])) {
                for (var spec in (suite.specStats ?: [])) {
                    if (listFindNoCase("Failed,Error", spec.status ?: "")) {
                        out("  #spec.status ?: ''#: #spec.name ?: 'unknown'#", "red");
                        if (verboseOutput && len(spec.failMessage ?: "")) {
                            out("    #left(spec.failMessage, 200)#");
                        }
                    }
                }
            }
        }

        if (data.totalFail == 0 && data.totalError == 0) {
            out("All browser tests passed.", "green");
        }
    } catch (any e) {
        out("Failed to parse results: #e.message#", "red");
    }
    return "";
}
```

- [ ] **Step 4: Add helper methods**

Add these private helpers to `Module.cfc` (near other private helpers):

```cfm
private string function $resolveBrowserInstallDir() {
    var envHome = "";
    try {
        envHome = createObject("java", "java.lang.System")
            .getenv("WHEELS_BROWSER_HOME") ?: "";
    } catch (any e) {}
    if (len(trim(envHome))) return envHome;
    var home = createObject("java", "java.lang.System").getProperty("user.home");
    return home & "/.wheels/browser";
}

private string function $sha256(required string filePath) {
    var md = createObject("java", "java.security.MessageDigest")
        .getInstance("SHA-256");
    var digest = md.digest(fileReadBinary(arguments.filePath));
    return lCase(
        createObject("java", "java.util.HexFormat").of().formatHex(digest)
    );
}

private string function $getServerPort() {
    // Check for running LuCLI server port
    try {
        if (
            structKeyExists(server, "lucli")
            && structKeyExists(server.lucli, "port")
        ) {
            return server.lucli.port;
        }
    } catch (any e) {}
    return "8080";
}
```

- [ ] **Step 5: Test manually**

```bash
wheels browser install
wheels browser test
wheels browser test --verbose
wheels browser test --json
```

- [ ] **Step 6: Commit**

```bash
git add cli/lucli/Module.cfc
git commit -m "feat(cli): add LuCLI browser subcommand dispatch

wheels browser install — download JARs + browser binaries
wheels browser test — run browser test suite with pre-flight check"
```

---

## Task 13: Deprecation Notice + Docs Update

**Files:**
- Modify: `tools/install-playwright.sh`
- Modify: `.ai/wheels/testing/browser-testing.md`

- [ ] **Step 1: Add deprecation notice to install script**

Add after the shebang line in `tools/install-playwright.sh`:

```bash
echo ""
echo "⚠  DEPRECATED: This script is replaced by 'wheels browser:install'."
echo "   This script still works but will be removed in a future release."
echo ""
```

- [ ] **Step 2: Update browser-testing.md**

Update the Installation section to show `wheels browser:install` as primary:

```markdown
## Installation

```bash
wheels browser:install              # recommended (LuCLI or CommandBox)
bash tools/install-playwright.sh    # legacy fallback (deprecated)
```
```

Add new sections documenting:

**Cookies:**
```markdown
### Cookies

```cfm
this.browser
    .setCookie(name="session", value="abc123", url="http://localhost:8080")
    .deleteCookie("session");

var c = this.browser.cookie("session");  // returns struct {name, value, domain, ...}
```

Cookies require a real HTTP origin — `data:` URLs are opaque origins.
```

**Configurable Timeouts:**
```markdown
### Configurable Timeouts

```cfm
this.browser
    .waitFor("##late-element", 5)      // 5-second timeout (default: 30)
    .waitForText("Loaded", 10)
    .waitForUrl("**/dashboard", 5);
```
```

**Screenshot Options:**
```markdown
### Screenshot Options

```cfm
this.browser.screenshot("/tmp/page.png");                           // basic
this.browser.screenshot(path="/tmp/full.png", fullPage=true);       // full page
this.browser.screenshot(path="/tmp/q.png", quality=80);             // JPEG quality
```
```

**Viewport Config:**
```markdown
### Viewport Config (BrowserTest Level)

```cfm
component extends="wheels.wheelstest.BrowserTest" {
    this.browserViewport = "mobile";           // preset: mobile/tablet/desktop
    // or: this.browserViewport = {width: 1024, height: 768};
```
```

**Auto-Screenshot on Failure:**
```markdown
### Auto-Screenshot on Failure

When a browser test fails, a screenshot and HTML dump are automatically saved to `tests/_output/browser/`. Disable per-spec:

```cfm
this.browserScreenshotOnFailure = false;
```

Configure artifact directory:
```cfm
this.browserArtifactPath = expandPath("/custom/path");
```
```

**CLI Commands:**
```markdown
## CLI Commands

```bash
wheels browser:install              # download JARs + browser binaries
wheels browser:install --force      # re-download even if SHAs match
wheels browser:install --browser=firefox

wheels browser:test                 # run browser test suite
wheels browser:test --verbose       # show full spec names
wheels browser:test --format=json   # JSON output for CI
```
```

Update the "Deferred functionality" table — move implemented items out and mark them as shipped.

- [ ] **Step 3: Commit**

```bash
git add tools/install-playwright.sh .ai/wheels/testing/browser-testing.md
git commit -m "docs(test): update browser testing docs and deprecate install script

Document new DSL methods (cookies, timeouts, waitForUrl, screenshot
options, viewport config), CLI commands, and auto-screenshot. Mark
tools/install-playwright.sh as deprecated."
```

---

## Final Verification

- [ ] **Run full test suite**

```bash
bash tools/test-local.sh
```

Expected: all tests pass (browser tests included if Playwright installed, skipped otherwise).

- [ ] **Run browser-specific tests**

```bash
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.wheelstest" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
for b in d.get('bundleStats',[]):
  for s in b.get('suiteStats',[]):
    for sp in s.get('specStats',[]):
      if sp.get('status') in ('Failed','Error'):
        print(f'  {sp[\"status\"]}: {sp[\"name\"]}: {sp.get(\"failMessage\",\"\")[:120]}')
"
```

Expected: 0 fail, 0 error. New tests bring the browser spec count from ~62 to ~80+.

- [ ] **Test CLI commands**

```bash
wheels browser install
wheels browser test
```

- [ ] **Verify no regressions in non-browser tests**

```bash
bash tools/test-local.sh model
bash tools/test-local.sh controller
```
