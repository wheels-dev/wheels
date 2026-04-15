# Browser Testing — Foundation (PR 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the foundation layer for native browser testing in Wheels — `BrowserClient.cfc` (fluent DSL over Playwright Java), `BrowserLauncher.cfc` (Playwright singleton + JAR loading), `BrowserTest.cfc` (TestBox base class with per-`it` context lifecycle), test-only login route, and integration tests. CLI, dogfood specs, and CI wiring are deferred to PRs 2-4.

**Architecture:** `BrowserClient` wraps one Playwright `BrowserContext` + `Page` with a fluent DSL that mirrors `TestClient.cfc`'s shape (chainable methods return `this`, terminals return values). `BrowserLauncher` is a process-level singleton that holds one `Playwright` instance per test run, discovered via JAR path lookup. `BrowserTest` extends `wheels.WheelsTest` and manages the per-`it` context/page lifecycle via TestBox hooks. A test-only `POST /_browser/login-as` route lets specs authenticate without going through the UI.

**Tech Stack:** CFML (Lucee 7 primary), Playwright Java 1.45.0, TestBox BDD, Wheels Testing (`wheels.WheelsTest`).

**Spec:** `docs/superpowers/specs/2026-04-15-browser-testing-design.md`

**Follow-up plans (not in this one):**
- Plan 2: `wheels browser:install` + `wheels browser:test` CLI + MCP tools
- Plan 3: `packages/hotwire/` dogfood browser specs
- Plan 4: CI workflow + reference docs

---

## File Map

**Create:**
- `vendor/wheels/browser-manifest.json` — pinned versions + SHA256s
- `vendor/wheels/wheelstest/BrowserLauncher.cfc` — Playwright singleton + JAR loader
- `vendor/wheels/wheelstest/BrowserClient.cfc` — fluent DSL (~35 methods)
- `vendor/wheels/wheelstest/BrowserTest.cfc` — TestBox base class
- `vendor/wheels/wheelstest/BrowserTestLoginController.cfc` — test-only auth endpoint
- `vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc` — path discovery unit tests
- `vendor/wheels/tests/specs/wheelstest/BrowserTestLoginControllerSpec.cfc` — route guard tests
- `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc` — real Chromium end-to-end
- `vendor/wheels/tests/fixtures/browserapp/` — minimal Wheels app for integration testing
- `tools/install-playwright.sh` — bootstrap script (temporary; replaced by `wheels browser:install` in PR 2)

**Modify:**
- `vendor/wheels/routes.cfm` — register test-only login route (env-guarded)

**Responsibility split:**
- `BrowserLauncher.cfc`: JVM-side concerns only — JAR path resolution, `Playwright.create()` caching, `Browser` acquisition per engine. No DSL knowledge.
- `BrowserClient.cfc`: DSL only — every method maps to a Playwright call. No TestBox, no lifecycle.
- `BrowserTest.cfc`: TestBox lifecycle glue — wires BrowserLauncher → BrowserClient, injects into spec, dumps artifacts on failure.
- `BrowserTestLoginController.cfc`: one action, one responsibility — delegate to app's `$signInAsForBrowserTest` hook.

---

## Task 1: Pin Playwright Java version in `browser-manifest.json`

**Files:**
- Create: `vendor/wheels/browser-manifest.json`

- [ ] **Step 1: Fetch the current Playwright Java release info**

Run:
```bash
curl -s "https://search.maven.org/solrsearch/select?q=g:com.microsoft.playwright+AND+a:playwright&rows=1&wt=json" | python3 -m json.tool
```
Expected: JSON with `response.docs[0].latestVersion` field. Record this version (the plan uses `1.45.0` as a placeholder; substitute the actual latest).

- [ ] **Step 2: Compute the JAR's SHA256**

Run:
```bash
VERSION="1.45.0"  # substitute with value from step 1
curl -sSL -o /tmp/playwright-${VERSION}.jar \
  "https://repo1.maven.org/maven2/com/microsoft/playwright/playwright/${VERSION}/playwright-${VERSION}.jar"
shasum -a 256 /tmp/playwright-${VERSION}.jar
```
Expected: 64-char hex SHA256. Record it.

- [ ] **Step 3: Write `vendor/wheels/browser-manifest.json`**

Playwright Java needs Maven's full transitive runtime graph on the classpath to boot (the standalone client JAR isn't sufficient). Since this script doesn't use Maven, the manifest pins **every** runtime JAR under a `classpath` array. Walk `com.microsoft.playwright:playwright`'s POM plus its parent to enumerate:

- `com.microsoft.playwright:playwright` — client API + CLI
- `com.microsoft.playwright:driver` — `impl.driver.Driver` class
- `com.microsoft.playwright:driver-bundle` — bundled Node + JS driver (~190MB)
- `com.google.code.gson:gson` — JSON
- `org.java-websocket:Java-WebSocket` — WS transport
- `org.slf4j:slf4j-api` + `org.slf4j:slf4j-simple` — logging

For each JAR, `curl -sSL <url> -o /tmp/x && shasum -a 256 /tmp/x` to compute SHA256.

```json
{
    "schemaVersion": 2,
    "playwrightJavaVersion": "1.52.0",
    "classpath": [
        {
            "filename": "playwright-1.52.0.jar",
            "url": "https://repo1.maven.org/maven2/com/microsoft/playwright/playwright/1.52.0/playwright-1.52.0.jar",
            "sha256": "REPLACE_ME",
            "size": 619097
        },
        {
            "filename": "driver-1.52.0.jar",
            "url": "https://repo1.maven.org/maven2/com/microsoft/playwright/driver/1.52.0/driver-1.52.0.jar",
            "sha256": "REPLACE_ME",
            "size": 6863
        }
        // ... driver-bundle, gson, Java-WebSocket, slf4j-api, slf4j-simple
    ],
    "browsers": {
        "chromium": "136.0.7103.25",
        "firefox": "137.0",
        "webkit": "18.4"
    },
    "minJavaVersion": 21,
    "installDir": "~/.wheels/browser"
}
```

Substitute each `REPLACE_ME` with the SHA256 from step 2.

- [ ] **Step 4: Commit**

```bash
git add vendor/wheels/browser-manifest.json
git commit -m "feat(test): pin Playwright Java version for browser testing"
```

---

## Task 2: `BrowserLauncher.cfc` — JAR path discovery

**Files:**
- Create: `vendor/wheels/wheelstest/BrowserLauncher.cfc`
- Create: `vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc`

- [ ] **Step 1: Write failing tests for path discovery**

Create `vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

    function beforeAll() {
        variables.launcher = CreateObject("component", "wheels.wheelstest.BrowserLauncher");
    }

    function run() {
        describe("BrowserLauncher path discovery", () => {

            it("resolveInstallDir() returns WHEELS_BROWSER_HOME env var when set", () => {
                var stubbed = variables.launcher.$resolveInstallDir(
                    envVar="/tmp/custom-browser-home",
                    homeDir="/Users/someone"
                );
                expect(stubbed).toBe("/tmp/custom-browser-home");
            });

            it("resolveInstallDir() falls back to ~/.wheels/browser when env var empty", () => {
                var resolved = variables.launcher.$resolveInstallDir(
                    envVar="",
                    homeDir="/Users/someone"
                );
                expect(resolved).toBe("/Users/someone/.wheels/browser");
            });

            it("resolveInstallDir() handles home dir with trailing slash", () => {
                var resolved = variables.launcher.$resolveInstallDir(
                    envVar="",
                    homeDir="/Users/someone/"
                );
                expect(resolved).toBe("/Users/someone/.wheels/browser");
            });

            it("jarPath() returns installDir + /lib/playwright-VERSION.jar", () => {
                var p = variables.launcher.$jarPath(
                    installDir="/tmp/browser",
                    version="1.45.0"
                );
                expect(p).toBe("/tmp/browser/lib/playwright-1.45.0.jar");
            });

            it("verifyInstall() throws when JAR missing", () => {
                expect(() => {
                    variables.launcher.$verifyInstall(jarPath="/does/not/exist.jar");
                }).toThrow(type="Wheels.BrowserNotInstalled");
            });

            it("verifyInstall() returns true when JAR exists", () => {
                var tmpJar = getTempDirectory() & "dummy-" & createUUID() & ".jar";
                fileWrite(tmpJar, "");
                try {
                    expect(variables.launcher.$verifyInstall(jarPath=tmpJar)).toBeTrue();
                } finally {
                    fileDelete(tmpJar);
                }
            });
        });
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
bash tools/test-local.sh --filter=wheelstest.BrowserLauncher
```
Expected: FAIL with "component not found" or similar — `BrowserLauncher.cfc` doesn't exist yet.

- [ ] **Step 3: Implement path discovery in `BrowserLauncher.cfc`**

Create `vendor/wheels/wheelstest/BrowserLauncher.cfc`:

```cfm
/**
 * Process-level singleton that owns the Playwright instance + Browser
 * for browser-driven tests. Not instantiated per-spec; the BrowserTest
 * base class uses the application-scoped instance.
 *
 * Responsibilities (split by stage):
 *   1. JAR path resolution (this task)
 *   2. Playwright lazy init + Browser acquisition (next task)
 *   3. Release/shutdown
 *
 * Not responsible for: DSL, lifecycle hooks, artifact dumping.
 */
component {

    variables.$manifest = "";
    variables.$playwright = "";        // Java Playwright instance (lazy)
    variables.$browsers = {};           // cache: engine => Java Browser instance
    variables.$state = "uninitialized"; // uninitialized | ready | shut-down

    public BrowserLauncher function init() {
        variables.$manifest = $loadManifest();
        return this;
    }

    /**
     * Reads vendor/wheels/browser-manifest.json.
     */
    public struct function $loadManifest() {
        var manifestPath = expandPath("/wheels/browser-manifest.json");
        if (!fileExists(manifestPath)) {
            throw(
                type="Wheels.BrowserManifestMissing",
                message="Expected vendor/wheels/browser-manifest.json to exist."
            );
        }
        return deserializeJSON(fileRead(manifestPath));
    }

    /**
     * Resolves the install directory based on env var or home dir fallback.
     * Pure function — passed-in args make it unit-testable.
     */
    public string function $resolveInstallDir(
        required string envVar,
        required string homeDir
    ) {
        if (len(trim(arguments.envVar)) > 0) {
            return arguments.envVar;
        }
        var home = arguments.homeDir;
        if (right(home, 1) == "/") {
            home = left(home, len(home) - 1);
        }
        return home & "/.wheels/browser";
    }

    /**
     * Default entry point — reads env var + home dir from the runtime.
     */
    public string function resolveInstallDir() {
        var envVar = server.system.environment["WHEELS_BROWSER_HOME"] ?: "";
        return $resolveInstallDir(envVar=envVar, homeDir=getUserHome());
    }

    public string function $jarPath(
        required string installDir,
        required string version
    ) {
        return arguments.installDir & "/lib/playwright-" & arguments.version & ".jar";
    }

    public boolean function $verifyInstall(required string jarPath) {
        if (!fileExists(arguments.jarPath)) {
            throw(
                type="Wheels.BrowserNotInstalled",
                message="Playwright JAR not found at " & arguments.jarPath
                    & ". Run `wheels browser:install` to set up browser testing."
            );
        }
        return true;
    }

    /**
     * Returns the path to the user's home directory. Override-friendly for tests.
     */
    public string function getUserHome() {
        return createObject("java", "java.lang.System").getProperty("user.home");
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
bash tools/test-local.sh --filter=wheelstest.BrowserLauncher
```
Expected: PASS — all 6 specs pass.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserLauncher.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc
git commit -m "feat(test): add BrowserLauncher JAR path discovery"
```

---

## Task 3: Write `tools/install-playwright.sh` bootstrap script

Integration tests in subsequent tasks require Playwright installed locally. This is a temporary bootstrap script; PR 2 will replace it with `wheels browser:install`.

**Important — full classpath install:** Playwright Java needs all seven runtime JARs on the classpath to boot (client, driver, driver-bundle, plus transitive `gson`, `Java-WebSocket`, `slf4j-api`, `slf4j-simple`). The manifest's `classpath` array pins every one; the script iterates the array, downloads each, SHA-verifies, then invokes `playwright install chromium` with all seven on the classpath.

**Files:**
- Create: `tools/install-playwright.sh`

- [ ] **Step 1: Write the script**

Create `tools/install-playwright.sh`:

```bash
#!/usr/bin/env bash
# Temporary bootstrap for browser testing. Replaced by `wheels browser:install`
# once PR 2 lands. Reads vendor/wheels/browser-manifest.json for pinned versions.
#
# Playwright Java needs the full classpath — client, driver, driver-bundle, plus
# transitive runtime deps (gson, Java-WebSocket, slf4j) — to boot. Maven normally
# resolves these; since we bootstrap without Maven, the manifest pins every JAR
# with SHA256, and this script downloads + verifies each before invoking the CLI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/vendor/wheels/browser-manifest.json"
INSTALL_DIR="${WHEELS_BROWSER_HOME:-$HOME/.wheels/browser}"
LIB_DIR="$INSTALL_DIR/lib"

if [[ ! -f "$MANIFEST" ]]; then
    echo "ERROR: $MANIFEST not found" >&2
    exit 1
fi

mkdir -p "$LIB_DIR"

# Read classpath entries as tab-separated rows: filename\turl\tsha256.
# Avoids bash-4 `mapfile` so the script works with macOS's default bash 3.2.
ENTRIES_FILE=$(mktemp)
trap 'rm -f "$ENTRIES_FILE"' EXIT
python3 -c "
import json
m = json.load(open('$MANIFEST'))
for e in m['classpath']:
    print(e['filename'] + '\t' + e['url'] + '\t' + e['sha256'])
" > "$ENTRIES_FILE"

ENTRY_COUNT=$(wc -l < "$ENTRIES_FILE" | tr -d ' ')
if [[ "$ENTRY_COUNT" -eq 0 ]]; then
    echo "ERROR: manifest has no classpath entries" >&2
    exit 1
fi

CLASSPATH=""
while IFS=$'\t' read -r filename url sha; do
    target="$LIB_DIR/$filename"

    if [[ -f "$target" ]]; then
        actual=$(shasum -a 256 "$target" | awk '{print $1}')
        if [[ "$actual" == "$sha" ]]; then
            echo "✓ $filename already present (SHA verified)"
            CLASSPATH+="$target:"
            continue
        fi
        echo "! $filename exists but SHA mismatch; re-downloading"
        rm -f "$target"
    fi

    echo "Downloading $filename from Maven Central..."
    curl -sSL -o "$target" "$url"

    actual=$(shasum -a 256 "$target" | awk '{print $1}')
    if [[ "$actual" != "$sha" ]]; then
        echo "ERROR: SHA mismatch for $filename" >&2
        echo "  expected: $sha" >&2
        echo "  actual:   $actual" >&2
        rm -f "$target"
        exit 1
    fi
    echo "✓ $filename downloaded and SHA-verified"
    CLASSPATH+="$target:"
done < "$ENTRIES_FILE"

# Strip trailing colon
CLASSPATH="${CLASSPATH%:}"

echo ""
echo "Installing Chromium via Playwright CLI (full classpath: $ENTRY_COUNT JARs)..."
java -cp "$CLASSPATH" com.microsoft.playwright.CLI install chromium

echo ""
echo "Done."
echo "  JARs:        $LIB_DIR/  ($ENTRY_COUNT files)"
echo "  Browsers:    ~/.cache/ms-playwright/ (Playwright default cache dir)"
echo "  Install dir: $INSTALL_DIR"
```

- [ ] **Step 2: Make executable and test it runs**

```bash
chmod +x tools/install-playwright.sh
bash tools/install-playwright.sh
```
Expected: downloads all 7 JARs (reusing any already present with matching SHA), installs Chromium. `~/.wheels/browser/lib/*.jar` (7 files) and `~/Library/Caches/ms-playwright/chromium-*/` exist afterward. Re-running should be a no-op (all JARs SHA-verified present).

- [ ] **Step 3: Commit**

```bash
git add tools/install-playwright.sh
git commit -m "feat(test): add temporary Playwright install bootstrap"
```

---

## Task 4: `BrowserLauncher` — Playwright instance + Browser acquisition

**⚠ Amended from original plan.** Task 3 discovered Playwright's full runtime set is seven JARs and restructured the manifest to a `classpath` array. Task 4's implementation diverges from the original plan as follows:

- **Added: `$classpathJarPaths(installDir) → array`** — reads `variables.$manifest.classpath` and returns `[installDir & "/lib/" & entry.filename, …]` for every entry.
- **Added: `getManifest()`, `getClassLoader()`, `getState()`** — accessors for the private `variables.$*` scope, needed by tests (CFML `variables` scope isn't externally accessible).
- **Added: `$findZeroArgMethod()`** — Lucee's Java-varargs bridge can't reliably express an empty `Class<?>[]` to `Class.getMethod(String, Class<?>...)`, so locate zero-arg methods by iterating `getMethods()`.
- **Dropped: `$driverBundlePath()`** — no longer a meaningful notion once the manifest drives everything through `classpath[]`.
- **`$loadJars(jarPaths)`** — unchanged from original design. Just pass it all seven paths from `$classpathJarPaths()`.

**⚠ Known blocker — browser launch path hangs.** `acquireBrowser()` is implemented but the full `Playwright.create() → chromium() → launch()` path hangs when invoked through the URLClassLoader on Lucee 7 + OpenJDK 21. The Node driver process spawns (`~/.lucli/servers/wheels/temp/playwright-java-*/node cli.js run-driver`) but the Java side blocks on IPC read indefinitely. Tests in this PR verify the foundation layer (classpath walker + URLClassLoader loading + state machine + class-resolution through the loader); full browser integration is deferred to a follow-up debug pass. Hypothesis: Lucee's method-call interception on URLClassLoader-loaded classes interferes with the node process's stdin/stdout inheritance.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserLauncher.cfc`
- Modify: `vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc` (add integration tests)

- [ ] **Step 1: Write failing integration test for browser acquisition**

Append to `vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc`, inside `run()` after the existing `describe`:

```cfm
describe("BrowserLauncher integration (requires Playwright install)", () => {

    it("acquireBrowser('chromium') returns a Java Browser instance", () => {
        // skip if JARs missing — will be loud in unit-test CI but silent locally
        // when developer hasn't run install-playwright.sh yet
        var installDir = variables.launcher.resolveInstallDir();
        var version = variables.launcher.$manifest.playwrightJavaVersion;
        var clientJar = variables.launcher.$jarPath(installDir=installDir, version=version);
        var driverJar = variables.launcher.$driverBundlePath(installDir=installDir, version=version);
        if (!fileExists(clientJar) || !fileExists(driverJar)) {
            debug("Skipping: Playwright JARs not installed. Run tools/install-playwright.sh");
            return;
        }

        variables.launcher.$loadJars(jarPaths=[clientJar, driverJar]);
        var browser = variables.launcher.acquireBrowser(engine="chromium");

        expect(browser).notToBeNull();
        expect(isObject(browser)).toBeTrue();

        // Must be callable — ensures we got a real Browser, not a stub
        var contexts = browser.contexts();
        expect(contexts).notToBeNull();

        variables.launcher.release();
    });

    it("acquireBrowser() returns the same Browser across calls (singleton per engine)", () => {
        var installDir = variables.launcher.resolveInstallDir();
        var version = variables.launcher.$manifest.playwrightJavaVersion;
        var clientJar = variables.launcher.$jarPath(installDir=installDir, version=version);
        var driverJar = variables.launcher.$driverBundlePath(installDir=installDir, version=version);
        if (!fileExists(clientJar) || !fileExists(driverJar)) {
            return;
        }

        variables.launcher.$loadJars(jarPaths=[clientJar, driverJar]);
        var b1 = variables.launcher.acquireBrowser(engine="chromium");
        var b2 = variables.launcher.acquireBrowser(engine="chromium");

        expect(b1).toBe(b2);
        variables.launcher.release();
    });
});
```

**Note on new methods:** Task 4 adds two methods beyond what Task 2 shipped:
- `$driverBundlePath(installDir, version)` — parallel to `$jarPath`, returns path to driver-bundle JAR
- `$loadJars(jarPaths)` — loads an array of JAR paths onto the classloader (supersedes the single-path `$loadJar` originally planned)

- [ ] **Step 2: Run test — expect fail on missing `acquireBrowser` method**

Run:
```bash
bash tools/install-playwright.sh    # ensures JAR exists
bash tools/test-local.sh --filter=wheelstest.BrowserLauncher
```
Expected: FAIL — `acquireBrowser` doesn't exist on BrowserLauncher yet.

- [ ] **Step 3: Implement Playwright loading + browser acquisition**

Append to `vendor/wheels/wheelstest/BrowserLauncher.cfc` (before the closing `}`):

```cfm
/**
 * Returns the filesystem path to the driver-bundle JAR.
 * Parallel to $jarPath (which returns the client JAR path).
 */
public string function $driverBundlePath(
    required string installDir,
    required string version
) {
    return arguments.installDir & "/lib/driver-bundle-" & arguments.version & ".jar";
}

/**
 * Dynamically loads the Playwright JARs into a URLClassLoader so
 * CreateObject("java", ...) can find Playwright classes.
 *
 * Takes an array so callers can load the client JAR + driver-bundle JAR
 * (both are required for Playwright to boot). Lucee-specific;
 * Adobe CF support deferred.
 *
 * Must be called before any acquireBrowser() call.
 */
public void function $loadJars(required array jarPaths) {
    if (variables.$state != "uninitialized") {
        return;  // idempotent
    }

    var urls = [];
    for (var jarPath in arguments.jarPaths) {
        var jarFile = createObject("java", "java.io.File").init(jarPath);
        arrayAppend(urls, jarFile.toURI().toURL());
    }

    var parentLoader = createObject("java", "java.lang.Thread")
        .currentThread()
        .getContextClassLoader();
    var classLoader = createObject("java", "java.net.URLClassLoader")
        .init(urls, parentLoader);

    variables.$classLoader = classLoader;
    variables.$state = "ready";
}

/**
 * Returns the Browser for the given engine, creating and caching it on first call.
 *
 * @engine One of: chromium, firefox, webkit
 */
public any function acquireBrowser(string engine = "chromium") {
    if (variables.$state != "ready") {
        throw(
            type="Wheels.BrowserLauncherNotReady",
            message="Call $loadJars() first. State: " & variables.$state
        );
    }

    if (structKeyExists(variables.$browsers, arguments.engine)) {
        return variables.$browsers[arguments.engine];
    }

    if (!isObject(variables.$playwright)) {
        var playwrightClass = variables.$classLoader.loadClass("com.microsoft.playwright.Playwright");
        variables.$playwright = playwrightClass.getMethod("create", javaCast("null", "")).invoke(javaCast("null", ""), javaCast("null", ""));
    }

    var browserType = $getBrowserType(engine=arguments.engine);
    var launchOptions = variables.$classLoader
        .loadClass("com.microsoft.playwright.BrowserType$LaunchOptions")
        .getDeclaredConstructor().newInstance();
    launchOptions.setHeadless(javaCast("boolean", true));

    var browser = browserType.launch(launchOptions);
    variables.$browsers[arguments.engine] = browser;
    return browser;
}

private any function $getBrowserType(required string engine) {
    switch (arguments.engine) {
        case "chromium":
            return variables.$playwright.chromium();
        case "firefox":
            return variables.$playwright.firefox();
        case "webkit":
            return variables.$playwright.webkit();
        default:
            throw(
                type="Wheels.BrowserEngineInvalid",
                message="Unknown engine: " & arguments.engine
                    & ". Valid: chromium, firefox, webkit."
            );
    }
}

/**
 * Closes all acquired browsers and the Playwright instance. Call once per
 * test run (not per spec CFC).
 */
public void function release() {
    for (var engine in variables.$browsers) {
        try {
            variables.$browsers[engine].close();
        } catch (any e) {
            // best-effort cleanup
        }
    }
    variables.$browsers = {};

    if (isObject(variables.$playwright)) {
        try {
            variables.$playwright.close();
        } catch (any e) {
        }
        variables.$playwright = "";
    }

    variables.$state = "shut-down";
}
```

- [ ] **Step 4: Run test — expect pass**

Run:
```bash
bash tools/test-local.sh --filter=wheelstest.BrowserLauncher
```
Expected: PASS on all specs including the two integration ones.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserLauncher.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserLauncherSpec.cfc
git commit -m "feat(test): BrowserLauncher Playwright instance and browser acquisition"
```

---

## Task 5: Minimal fixture app for integration tests

Subsequent tasks need a real Wheels app running to point the browser at. Build a skeletal app under `vendor/wheels/tests/fixtures/browserapp/`.

**Files:**
- Create: `vendor/wheels/tests/fixtures/browserapp/config/routes.cfm`
- Create: `vendor/wheels/tests/fixtures/browserapp/config/settings.cfm`
- Create: `vendor/wheels/tests/fixtures/browserapp/app/controllers/Home.cfc`
- Create: `vendor/wheels/tests/fixtures/browserapp/app/controllers/Sessions.cfc`
- Create: `vendor/wheels/tests/fixtures/browserapp/app/views/home/index.cfm`
- Create: `vendor/wheels/tests/fixtures/browserapp/app/views/sessions/new.cfm`
- Create: `vendor/wheels/tests/fixtures/browserapp/app/views/home/dashboard.cfm`

- [ ] **Step 1: Create routes**

Create `vendor/wheels/tests/fixtures/browserapp/config/routes.cfm`:

```cfm
<cfscript>
mapper()
    .root(to="home##index", method="get")
    .get(name="login", pattern="/login", to="sessions##new")
    .post(name="authenticate", pattern="/login", to="sessions##create")
    .get(name="dashboard", pattern="/dashboard", to="home##dashboard")
    .post(name="logout", pattern="/logout", to="sessions##destroy")
    .wildcard()
.end();
</cfscript>
```

- [ ] **Step 2: Create settings**

Create `vendor/wheels/tests/fixtures/browserapp/config/settings.cfm`:

```cfm
<cfscript>
set(environment="testing");
set(dataSourceName="wheelstestdb");
</cfscript>
```

- [ ] **Step 3: Create Home controller**

Create `vendor/wheels/tests/fixtures/browserapp/app/controllers/Home.cfc`:

```cfm
component extends="Controller" {

    function init() {
        filters(through="$requireLogin", except="index");
    }

    function index() {
    }

    function dashboard() {
        user = { email: session.userEmail ?: "" };
    }

    private function $requireLogin() {
        if (!structKeyExists(session, "userId")) {
            redirectTo(route="login");
        }
    }
}
```

- [ ] **Step 4: Create Sessions controller**

Create `vendor/wheels/tests/fixtures/browserapp/app/controllers/Sessions.cfc`:

```cfm
component extends="Controller" {

    function new() {
        flashError = flash("error") ?: "";
    }

    function create() {
        if (params.email == "alice@example.com" && params.password == "secret") {
            session.userId = 1;
            session.userEmail = params.email;
            redirectTo(route="dashboard");
        } else {
            flashInsert(error="Invalid credentials");
            redirectTo(route="login");
        }
    }

    function destroy() {
        structClear(session);
        redirectTo(route="login");
    }
}
```

- [ ] **Step 5: Create views**

Create `vendor/wheels/tests/fixtures/browserapp/app/views/home/index.cfm`:

```cfm
<cfoutput>
<h1>Home</h1>
<p>Welcome to the browser test fixture app.</p>
<a href="#urlFor(route='login')#">Log in</a>
</cfoutput>
```

Create `vendor/wheels/tests/fixtures/browserapp/app/views/sessions/new.cfm`:

```cfm
<cfparam name="flashError" default="">
<cfoutput>
<h1>Log in</h1>
<cfif len(flashError)>
    <div class="error">#flashError#</div>
</cfif>
<form method="post" action="#urlFor(route='authenticate')#">
    <input type="email" name="email" id="email">
    <input type="password" name="password" id="password">
    <button type="submit">Sign in</button>
</form>
</cfoutput>
```

Create `vendor/wheels/tests/fixtures/browserapp/app/views/home/dashboard.cfm`:

```cfm
<cfparam name="user" default="#{}#">
<cfoutput>
<h1>Dashboard</h1>
<p>Welcome, #encodeForHTML(user.email)#</p>
<form method="post" action="#urlFor(route='logout')#">
    <button type="submit">Log out</button>
</form>
</cfoutput>
```

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/tests/fixtures/browserapp/
git commit -m "feat(test): minimal fixture app for browser integration tests"
```

---

## Task 6: `BrowserClient` — init + navigation methods

**Files:**
- Create: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Create: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Write failing integration test**

Create `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

    function beforeAll() {
        variables.launcher = CreateObject("component", "wheels.wheelstest.BrowserLauncher");
        var installDir = variables.launcher.resolveInstallDir();
        var version = variables.launcher.$manifest.playwrightJavaVersion;
        var clientJar = variables.launcher.$jarPath(installDir=installDir, version=version);
        var driverJar = variables.launcher.$driverBundlePath(installDir=installDir, version=version);
        if (!fileExists(clientJar) || !fileExists(driverJar)) {
            variables.skipBrowserTests = true;
            return;
        }
        variables.skipBrowserTests = false;
        variables.launcher.$loadJars(jarPaths=[clientJar, driverJar]);
        variables.browser = variables.launcher.acquireBrowser(engine="chromium");
        variables.baseUrl = "http://localhost:8080";
    }

    function afterAll() {
        if (!(variables.skipBrowserTests ?: false)) {
            variables.launcher.release();
        }
    }

    function run() {
        describe("BrowserClient navigation", () => {

            beforeEach(() => {
                if (variables.skipBrowserTests) { return; }
                variables.context = variables.browser.newContext();
                variables.page = variables.context.newPage();
                variables.client = CreateObject("component", "wheels.wheelstest.BrowserClient")
                    .init(page=variables.page, context=variables.context, baseUrl=variables.baseUrl);
            });

            afterEach(() => {
                if (variables.skipBrowserTests) { return; }
                variables.context.close();
            });

            it("visit(path) navigates to baseUrl + path and returns this for chaining", () => {
                if (variables.skipBrowserTests) { return; }
                var result = variables.client.visit("/");
                expect(result).toBe(variables.client);
                expect(variables.client.currentUrl()).toInclude("/");
            });

            it("visit() rejects non-leading-slash paths with clear error", () => {
                if (variables.skipBrowserTests) { return; }
                expect(() => {
                    variables.client.visit("no-leading-slash");
                }).toThrow(type="Wheels.BrowserInvalidPath");
            });

            it("currentUrl() returns page.url() from Playwright", () => {
                if (variables.skipBrowserTests) { return; }
                variables.client.visit("/");
                expect(variables.client.currentUrl()).toInclude(variables.baseUrl);
            });
        });
    }
}
```

Note: tests assume a LuCLI server is running on :8080 with the fixture app mounted. Subsequent tasks will wire that up properly; for now, run `wheels server start` manually before running these specs.

- [ ] **Step 2: Run test — expect fail**

Start a server pointed at the fixture app and run tests:
```bash
cd /Users/peter/GitHub/wheels-dev/wheels && lucli server run --port=8080 &
sleep 5
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: FAIL — `BrowserClient.cfc` doesn't exist.

- [ ] **Step 3: Implement `BrowserClient.cfc` init + navigation**

Create `vendor/wheels/wheelstest/BrowserClient.cfc`:

```cfm
/**
 * Fluent DSL wrapping a Playwright BrowserContext + Page for browser tests.
 * Mirrors TestClient.cfc's shape: chainable methods return `this`,
 * terminals return values.
 *
 * Instantiation: typically done by BrowserTest.cfc's beforeEach hook.
 * For manual use, pass Playwright objects directly.
 */
component {

    variables.page = "";
    variables.context = "";
    variables.baseUrl = "";

    public BrowserClient function init(
        required any page,
        required any context,
        required string baseUrl
    ) {
        variables.page = arguments.page;
        variables.context = arguments.context;
        variables.baseUrl = arguments.baseUrl;
        return this;
    }

    // ─── Navigation ──────────────────────────────────────────────────

    public BrowserClient function visit(required string path) {
        $requireLeadingSlash(arguments.path);
        variables.page.navigate(variables.baseUrl & arguments.path);
        return this;
    }

    public BrowserClient function visitRoute(
        required string name,
        struct params = {}
    ) {
        // Delegates to Wheels urlFor() which is available because the app
        // is running. When used outside a controller context, callers must
        // wire baseUrl + expected path; visitRoute here requires app context.
        var url = urlFor(argumentCollection=arguments);
        return visit(url);
    }

    public BrowserClient function back() {
        variables.page.goBack();
        return this;
    }

    public BrowserClient function forward() {
        variables.page.goForward();
        return this;
    }

    public BrowserClient function refresh() {
        variables.page.reload();
        return this;
    }

    // ─── Terminals ───────────────────────────────────────────────────

    public string function currentUrl() {
        return variables.page.url();
    }

    // ─── Internal helpers ────────────────────────────────────────────

    private void function $requireLeadingSlash(required string path) {
        if (left(arguments.path, 1) != "/") {
            throw(
                type="Wheels.BrowserInvalidPath",
                message="BrowserClient paths must start with '/': " & arguments.path
            );
        }
    }
}
```

- [ ] **Step 4: Run test — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): BrowserClient navigation methods"
```

---

## Task 7: `BrowserClient` — interaction methods

Adds: `click`, `press`, `fill`, `type`, `clear`, `select`, `check`, `uncheck`, `attach`, `dragAndDrop`.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Modify: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Add failing tests for interaction methods**

Inside the `run()` block in `BrowserIntegrationSpec.cfc`, add a new `describe`:

```cfm
describe("BrowserClient interaction", () => {

    beforeEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context = variables.browser.newContext();
        variables.page = variables.context.newPage();
        variables.client = CreateObject("component", "wheels.wheelstest.BrowserClient")
            .init(page=variables.page, context=variables.context, baseUrl=variables.baseUrl);
    });

    afterEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context.close();
    });

    it("fill() sets input value instantly", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login").fill("##email", "alice@example.com");
        var val = variables.page.locator("##email").inputValue();
        expect(val).toBe("alice@example.com");
    });

    it("type() sends keystrokes character-by-character", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login").type("##email", "bob@example.com");
        var val = variables.page.locator("##email").inputValue();
        expect(val).toBe("bob@example.com");
    });

    it("clear() empties an input", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client
            .visit("/login")
            .fill("##email", "alice@example.com")
            .clear("##email");
        var val = variables.page.locator("##email").inputValue();
        expect(val).toBe("");
    });

    it("click() triggers button click and waits for navigation", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client
            .visit("/login")
            .fill("##email", "alice@example.com")
            .fill("##password", "secret")
            .click("button[type=submit]");
        expect(variables.client.currentUrl()).toInclude("/dashboard");
    });

    it("press() finds button by visible text and clicks", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client
            .visit("/login")
            .fill("##email", "alice@example.com")
            .fill("##password", "secret")
            .press("Sign in");
        expect(variables.client.currentUrl()).toInclude("/dashboard");
    });
});
```

- [ ] **Step 2: Run tests — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: FAIL — `fill`, `type`, `clear`, `click`, `press` don't exist.

- [ ] **Step 3: Implement interaction methods**

Append to `vendor/wheels/wheelstest/BrowserClient.cfc` before the `// ─── Terminals ───` block:

```cfm
// ─── Interaction ─────────────────────────────────────────────────

public BrowserClient function click(required string selector) {
    variables.page.locator(arguments.selector).click();
    return this;
}

public BrowserClient function press(required string buttonText) {
    // Matches button by visible text; Playwright has native support
    variables.page.getByRole("button", $jNameOpts(name=arguments.buttonText)).click();
    return this;
}

public BrowserClient function fill(
    required string selector,
    required string value
) {
    variables.page.locator(arguments.selector).fill(arguments.value);
    return this;
}

public BrowserClient function type(
    required string selector,
    required string value
) {
    // Playwright Java uses pressSequentially for keystroke simulation
    variables.page.locator(arguments.selector).pressSequentially(arguments.value);
    return this;
}

public BrowserClient function clear(required string selector) {
    variables.page.locator(arguments.selector).clear();
    return this;
}

public BrowserClient function select(
    required string selector,
    required string value
) {
    variables.page.locator(arguments.selector).selectOption(arguments.value);
    return this;
}

public BrowserClient function check(required string selector) {
    variables.page.locator(arguments.selector).check();
    return this;
}

public BrowserClient function uncheck(required string selector) {
    variables.page.locator(arguments.selector).uncheck();
    return this;
}

public BrowserClient function attach(
    required string selector,
    required string filePath
) {
    variables.page.locator(arguments.selector).setInputFiles(
        createObject("java", "java.nio.file.Paths").get(arguments.filePath, [])
    );
    return this;
}

public BrowserClient function dragAndDrop(
    required string fromSelector,
    required string toSelector
) {
    variables.page.locator(arguments.fromSelector)
        .dragTo(variables.page.locator(arguments.toSelector));
    return this;
}
```

Also add this helper at the bottom of the file (before the final `}`):

```cfm
// ─── Java option-object helpers ──────────────────────────────────

/**
 * Builds a Playwright Page$GetByRoleOptions with a name filter.
 * Java API: page.getByRole("button", new Page.GetByRoleOptions().setName("Save"))
 */
private any function $jNameOpts(required string name) {
    var opts = createObject("java", "com.microsoft.playwright.Page$GetByRoleOptions").init();
    opts.setName(arguments.name);
    return opts;
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: PASS on all interaction specs.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): BrowserClient interaction methods"
```

---

## Task 8: `BrowserClient` — keyboard + dialogs + waiting + scoping

Adds: `keys`, `pressEnter`, `pressTab`, `pressEscape`, `acceptDialog`, `dismissDialog`, `typeInDialog`, `waitFor`, `waitForText`, `waitForUrl`, `within`.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Modify: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Add tests**

Append a new `describe` block inside `run()`:

```cfm
describe("BrowserClient keyboard, dialogs, waiting, scoping", () => {

    beforeEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context = variables.browser.newContext();
        variables.page = variables.context.newPage();
        variables.client = CreateObject("component", "wheels.wheelstest.BrowserClient")
            .init(page=variables.page, context=variables.context, baseUrl=variables.baseUrl);
    });

    afterEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context.close();
    });

    it("pressEnter() submits form via enter key", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client
            .visit("/login")
            .fill("##email", "alice@example.com")
            .fill("##password", "secret")
            .pressEnter("##password");
        expect(variables.client.currentUrl()).toInclude("/dashboard");
    });

    it("waitFor(selector) waits for element to appear", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login");
        var result = variables.client.waitFor("##email", 5);
        expect(result).toBe(variables.client);
    });

    it("waitForText() waits for text to appear on page", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login");
        var result = variables.client.waitForText("Log in", 5);
        expect(result).toBe(variables.client);
    });

    it("waitForUrl() waits until page URL matches", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client
            .visit("/login")
            .fill("##email", "alice@example.com")
            .fill("##password", "secret")
            .click("button[type=submit]")
            .waitForUrl("/dashboard", 5);
        expect(variables.client.currentUrl()).toInclude("/dashboard");
    });

    it("within(selector, callback) scopes subsequent selectors to subtree", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client
            .visit("/login")
            .within("form", function(scoped) {
                scoped.fill("##email", "alice@example.com");
            });
        var val = variables.page.locator("##email").inputValue();
        expect(val).toBe("alice@example.com");
    });
});
```

- [ ] **Step 2: Run tests — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: FAIL — none of these methods exist yet.

- [ ] **Step 3: Implement keyboard + dialogs + waiting + scoping**

Append to `BrowserClient.cfc` after the interaction methods:

```cfm
// ─── Keyboard ────────────────────────────────────────────────────

public BrowserClient function keys(
    required string selector,
    required string key
) {
    variables.page.locator(arguments.selector).press(arguments.key);
    return this;
}

public BrowserClient function pressEnter(string selector = "") {
    return $pressSpecial(selector=arguments.selector, key="Enter");
}

public BrowserClient function pressTab(string selector = "") {
    return $pressSpecial(selector=arguments.selector, key="Tab");
}

public BrowserClient function pressEscape(string selector = "") {
    return $pressSpecial(selector=arguments.selector, key="Escape");
}

private BrowserClient function $pressSpecial(
    required string selector,
    required string key
) {
    if (len(arguments.selector) > 0) {
        variables.page.locator(arguments.selector).press(arguments.key);
    } else {
        variables.page.keyboard().press(arguments.key);
    }
    return this;
}

// ─── Dialogs ─────────────────────────────────────────────────────

public BrowserClient function acceptDialog() {
    // Playwright Java: page.onDialog(Consumer<Dialog>). Use createDynamicProxy
    // to bridge a CFC implementing the Consumer interface (accept method).
    // We track a one-shot flag via state on the handler CFC itself.
    var handler = createObject("component", "wheels.wheelstest.dialogs.AcceptHandler");
    variables.page.onDialog(createDynamicProxy(handler, ["java.util.function.Consumer"]));
    return this;
}

public BrowserClient function dismissDialog() {
    var handler = createObject("component", "wheels.wheelstest.dialogs.DismissHandler");
    variables.page.onDialog(createDynamicProxy(handler, ["java.util.function.Consumer"]));
    return this;
}

public BrowserClient function typeInDialog(required string text) {
    var handler = createObject("component", "wheels.wheelstest.dialogs.PromptHandler")
        .init(text=arguments.text);
    variables.page.onDialog(createDynamicProxy(handler, ["java.util.function.Consumer"]));
    return this;
}

// ─── Waiting ─────────────────────────────────────────────────────

public BrowserClient function waitFor(
    required string selector,
    numeric seconds = 5
) {
    var opts = createObject("java", "com.microsoft.playwright.Locator$WaitForOptions").init();
    opts.setTimeout(javaCast("double", arguments.seconds * 1000));
    variables.page.locator(arguments.selector).waitFor(opts);
    return this;
}

public BrowserClient function waitForText(
    required string text,
    numeric seconds = 5
) {
    var opts = createObject("java", "com.microsoft.playwright.Locator$WaitForOptions").init();
    opts.setTimeout(javaCast("double", arguments.seconds * 1000));
    variables.page.getByText(arguments.text).waitFor(opts);
    return this;
}

public BrowserClient function waitForUrl(
    required string path,
    numeric seconds = 5
) {
    var opts = createObject("java", "com.microsoft.playwright.Page$WaitForURLOptions").init();
    opts.setTimeout(javaCast("double", arguments.seconds * 1000));
    variables.page.waitForURL(variables.baseUrl & arguments.path, opts);
    return this;
}

// ─── Scoping ─────────────────────────────────────────────────────

public BrowserClient function within(
    required string selector,
    required any callback
) {
    var scoped = CreateObject("component", "wheels.wheelstest.BrowserClient")
        .init(
            page=variables.page,
            context=variables.context,
            baseUrl=variables.baseUrl
        );
    scoped.$setScope(variables.page.locator(arguments.selector));
    arguments.callback(scoped);
    return this;
}

/**
 * Used by within() to restrict subsequent selectors to a subtree.
 * Implementation detail: scoped client overrides the locator resolver.
 */
public void function $setScope(required any rootLocator) {
    variables.$scope = arguments.rootLocator;
}
```

Now also add scope-aware locator resolution. Update the private locator helpers — replace direct `variables.page.locator(selector)` calls inside interaction methods with a helper. Add this helper near `$jNameOpts`:

```cfm
private any function $locator(required string selector) {
    if (structKeyExists(variables, "$scope")) {
        return variables.$scope.locator(arguments.selector);
    }
    return variables.page.locator(arguments.selector);
}
```

Then replace all occurrences of `variables.page.locator(arguments.selector)` with `$locator(arguments.selector)` inside the methods added in Task 7 (click, fill, type, clear, select, check, uncheck, attach, dragAndDrop, keys).

- [ ] **Step 4: Create dialog handler CFCs**

These CFCs implement `java.util.function.Consumer<Dialog>` — single
method `accept(Object)`. CFML's `createDynamicProxy` bridges the CFC's
`accept` method to the Java interface.

Create `vendor/wheels/wheelstest/dialogs/AcceptHandler.cfc`:

```cfm
component {
    public void function accept(required any dialog) {
        arguments.dialog.accept();
    }
}
```

Create `vendor/wheels/wheelstest/dialogs/DismissHandler.cfc`:

```cfm
component {
    public void function accept(required any dialog) {
        arguments.dialog.dismiss();
    }
}
```

Create `vendor/wheels/wheelstest/dialogs/PromptHandler.cfc`:

```cfm
component {
    variables.text = "";

    public PromptHandler function init(required string text) {
        variables.text = arguments.text;
        return this;
    }

    public void function accept(required any dialog) {
        arguments.dialog.accept(variables.text);
    }
}
```

- [ ] **Step 5: Run tests — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: PASS on keyboard, waiting, and scoping specs. (Dialog specs come in Task 9 integration test — dialog handlers require a page that actually triggers dialogs.)

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc \
        vendor/wheels/wheelstest/dialogs/ \
        vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): BrowserClient keyboard, dialogs, waiting, scoping"
```

---

## Task 9: `BrowserClient` — viewport, cookies, script, pause

Adds: `resize`, `resizeToMobile`, `resizeToTablet`, `resizeToDesktop`, `setCookie`, `deleteCookie`, `cookie`, `script`, `pause`.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Modify: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Add tests**

Append a new `describe` block inside `run()`:

```cfm
describe("BrowserClient viewport + cookies + script", () => {

    beforeEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context = variables.browser.newContext();
        variables.page = variables.context.newPage();
        variables.client = CreateObject("component", "wheels.wheelstest.BrowserClient")
            .init(page=variables.page, context=variables.context, baseUrl=variables.baseUrl);
    });

    afterEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context.close();
    });

    it("resize(w, h) sets viewport size", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/").resize(800, 600);
        var size = variables.page.viewportSize();
        expect(size.width).toBe(800);
        expect(size.height).toBe(600);
    });

    it("resizeToMobile() sets 375x667", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/").resizeToMobile();
        var size = variables.page.viewportSize();
        expect(size.width).toBe(375);
        expect(size.height).toBe(667);
    });

    it("setCookie() and cookie() round-trip", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/").setCookie("foo", "bar");
        expect(variables.client.cookie("foo")).toBe("bar");
    });

    it("deleteCookie() removes named cookie", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/").setCookie("tmp", "xyz").deleteCookie("tmp");
        expect(variables.client.cookie("tmp")).toBe("");
    });

    it("script(js) executes JS and returns result", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/");
        var result = variables.client.script("() => 2 + 2");
        expect(result).toBe(4);
    });
});
```

- [ ] **Step 2: Run — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: FAIL.

- [ ] **Step 3: Implement**

Append to `BrowserClient.cfc`:

```cfm
// ─── Viewport ────────────────────────────────────────────────────

public BrowserClient function resize(
    required numeric width,
    required numeric height
) {
    variables.page.setViewportSize(
        javaCast("int", arguments.width),
        javaCast("int", arguments.height)
    );
    return this;
}

public BrowserClient function resizeToMobile() {
    return resize(375, 667);
}

public BrowserClient function resizeToTablet() {
    return resize(768, 1024);
}

public BrowserClient function resizeToDesktop() {
    return resize(1440, 900);
}

// ─── Cookies ─────────────────────────────────────────────────────

public BrowserClient function setCookie(
    required string name,
    required string value
) {
    var cookieOpts = createObject("java", "com.microsoft.playwright.options.Cookie")
        .init(arguments.name, arguments.value);

    // Extract host from current URL so cookie has a domain
    var url = variables.page.url();
    var host = $extractHost(url);
    cookieOpts.setDomain(host);
    cookieOpts.setPath("/");

    var cookies = [cookieOpts];
    variables.context.addCookies(cookies);
    return this;
}

public BrowserClient function deleteCookie(required string name) {
    // Playwright has no single-cookie delete; clear all and re-add everything
    // except the target. For test use, this is acceptable.
    var allCookies = variables.context.cookies();
    variables.context.clearCookies();
    for (var c in allCookies) {
        if (c.name() != arguments.name) {
            var opts = createObject("java", "com.microsoft.playwright.options.Cookie")
                .init(c.name(), c.value());
            opts.setDomain(c.domain());
            opts.setPath(c.path());
            variables.context.addCookies([opts]);
        }
    }
    return this;
}

public string function cookie(required string name) {
    var cookies = variables.context.cookies();
    for (var c in cookies) {
        if (c.name() == arguments.name) {
            return c.value();
        }
    }
    return "";
}

// ─── Script + Pause ──────────────────────────────────────────────

public any function script(required string js) {
    return variables.page.evaluate(arguments.js);
}

public BrowserClient function pause(required numeric milliseconds) {
    var pauseWarningOff = (server.system.environment.BROWSER_TEST_PAUSE_WARNING ?: "on") == "off";
    if (!pauseWarningOff) {
        writeOutput("⚠ BrowserClient.pause() called for " & arguments.milliseconds
            & "ms. Remove before committing or set BROWSER_TEST_PAUSE_WARNING=off.\n");
    }
    sleep(arguments.milliseconds);
    return this;
}

private string function $extractHost(required string url) {
    // Simple parse; good enough for test contexts
    var noScheme = reReplace(arguments.url, "^https?://", "");
    var firstSlash = find("/", noScheme);
    if (firstSlash == 0) {
        return noScheme;
    }
    var hostPort = left(noScheme, firstSlash - 1);
    var colonIdx = find(":", hostPort);
    if (colonIdx > 0) {
        return left(hostPort, colonIdx - 1);
    }
    return hostPort;
}
```

- [ ] **Step 4: Run — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): BrowserClient viewport, cookies, script, pause"
```

---

## Task 10: Test-only login route + controller

This provides the infrastructure for `loginAs()` in Task 11.

**Files:**
- Create: `vendor/wheels/wheelstest/BrowserTestLoginController.cfc`
- Modify: `vendor/wheels/routes.cfm`
- Create: `vendor/wheels/tests/specs/wheelstest/BrowserTestLoginControllerSpec.cfc`

- [ ] **Step 1: Write failing test for the route guard**

Create `vendor/wheels/tests/specs/wheelstest/BrowserTestLoginControllerSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

    function run() {
        describe("BrowserTestLogin route registration", () => {

            it("registers POST /_browser/login-as only when environment is 'testing'", () => {
                var routes = $collectRoutes("testing");
                var hasRoute = false;
                for (var r in routes) {
                    if ((r.pattern ?: "") == "/_browser/login-as" && r.methods contains "post") {
                        hasRoute = true;
                    }
                }
                expect(hasRoute).toBeTrue();
            });

            it("does NOT register the route when environment is 'production'", () => {
                var routes = $collectRoutes("production");
                for (var r in routes) {
                    if ((r.pattern ?: "") == "/_browser/login-as") {
                        fail("Route should not exist in production");
                    }
                }
                expect(true).toBeTrue();
            });
        });

        describe("BrowserTestLoginController", () => {

            it("loginAs() returns 501 when app has not defined $signInAsForBrowserTest", () => {
                var controller = CreateObject("component", "wheels.wheelstest.BrowserTestLoginController");
                var mockParams = { identifier: "42" };
                var response = controller.$invokeLoginAs(params=mockParams, hookDefined=false);
                expect(response.status).toBe(501);
                expect(response.body).toInclude("signInAsForBrowserTest");
            });

            it("loginAs() delegates to $signInAsForBrowserTest(identifier) when defined", () => {
                var controller = CreateObject("component", "wheels.wheelstest.BrowserTestLoginController");
                var capturedId = "";
                var mockParams = { identifier: "alice@example.com" };
                var response = controller.$invokeLoginAs(
                    params=mockParams,
                    hookDefined=true,
                    hookFn=function(identifier) {
                        capturedId = arguments.identifier;
                    }
                );
                expect(capturedId).toBe("alice@example.com");
                expect(response.status).toBe(204);
            });
        });
    }

    private array function $collectRoutes(required string environment) {
        // Build a mapper() under the given environment and collect registered routes
        var origEnv = get("environment") ?: "";
        application.wheels.environment = arguments.environment;
        try {
            // Re-source routes.cfm under the target environment
            savecontent variable="out" {
                include template="/wheels/routes.cfm";
            }
            return application.wheels.mapper.getRoutes() ?: [];
        } finally {
            application.wheels.environment = origEnv;
        }
    }
}
```

- [ ] **Step 2: Run — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserTestLoginController
```
Expected: FAIL — controller doesn't exist; route isn't registered.

- [ ] **Step 3: Create the controller**

Create `vendor/wheels/wheelstest/BrowserTestLoginController.cfc`:

```cfm
/**
 * Test-only controller for browser authentication. Only instantiated when
 * the app's routes.cfm registers `/_browser/login-as` — which itself is
 * environment-gated to testing.
 *
 * Flow:
 *   1. Request arrives with `identifier` in body
 *   2. Controller checks the app has defined $signInAsForBrowserTest
 *   3. Calls the hook with the identifier
 *   4. Returns 204 (No Content) on success, 501 if hook undefined
 */
component extends="Controller" {

    function loginAs() {
        var result = $invokeLoginAs(
            params=params,
            hookDefined=$hookDefined(),
            hookFn=$hookDefined() ? variables.$hookRef : function() {}
        );
        renderText(text=result.body, status=result.status);
    }

    /**
     * Separated for unit testing — no framework coupling.
     */
    public struct function $invokeLoginAs(
        required struct params,
        required boolean hookDefined,
        function hookFn
    ) {
        if (!structKeyExists(arguments.params, "identifier")) {
            return {
                status: 400,
                body: "Missing 'identifier' in request body"
            };
        }

        if (!arguments.hookDefined) {
            return {
                status: 501,
                body: "Not implemented: app must define $signInAsForBrowserTest("
                    & "identifier) in app/events/browsertest.cfm or equivalent."
            };
        }

        arguments.hookFn(arguments.params.identifier);
        return {
            status: 204,
            body: ""
        };
    }

    private boolean function $hookDefined() {
        // The app defines this function in its event scope; look it up there
        if (structKeyExists(application, "$signInAsForBrowserTest")) {
            variables.$hookRef = application.$signInAsForBrowserTest;
            return true;
        }
        return false;
    }
}
```

- [ ] **Step 4: Register the route**

In `vendor/wheels/routes.cfm`, add inside the mapper() chain, BEFORE `.wildcard()`:

```cfm
// Test-only browser login route. Registered only when environment is "testing".
// Delegates to app-defined $signInAsForBrowserTest(identifier) hook.
if ((get("environment") ?: "") == "testing") {
    mapper.post(
        name="wheelsBrowserTestLogin",
        pattern="/_browser/login-as",
        to="wheels.wheelstest.BrowserTestLoginController##loginAs"
    );
}
```

Note: adjust the insertion point based on the actual structure of `routes.cfm` — this block needs to be inside the mapper chain or as a sibling call that references the same mapper instance. Read the existing file before editing.

- [ ] **Step 5: Run — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserTestLoginController
```
Expected: PASS on all specs.

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserTestLoginController.cfc \
        vendor/wheels/routes.cfm \
        vendor/wheels/tests/specs/wheelstest/BrowserTestLoginControllerSpec.cfc
git commit -m "feat(test): test-only browser login route with environment guard"
```

---

## Task 11: `BrowserClient` — auth methods (`loginAs`, `logout`)

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Modify: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`
- Modify: `vendor/wheels/tests/fixtures/browserapp/app/events/onapplicationstart.cfm` (create if missing)

- [ ] **Step 1: Register the `$signInAsForBrowserTest` hook in fixture app**

Create `vendor/wheels/tests/fixtures/browserapp/app/events/onapplicationstart.cfm`:

```cfm
<cfscript>
application.$signInAsForBrowserTest = function(required any identifier) {
    session.userId = arguments.identifier;
    session.userEmail = arguments.identifier & "@example.com";
};
</cfscript>
```

- [ ] **Step 2: Add failing test**

Append to `BrowserIntegrationSpec.cfc`:

```cfm
describe("BrowserClient auth", () => {

    beforeEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context = variables.browser.newContext();
        variables.page = variables.context.newPage();
        variables.client = CreateObject("component", "wheels.wheelstest.BrowserClient")
            .init(page=variables.page, context=variables.context, baseUrl=variables.baseUrl);
    });

    afterEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context.close();
    });

    it("loginAs(identifier) sets session cookie via test-only route", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.loginAs("42").visit("/dashboard");
        // If loginAs worked, /dashboard doesn't redirect to /login
        expect(variables.client.currentUrl()).toInclude("/dashboard");
    });

    it("logout() clears session cookies", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client
            .loginAs("42")
            .visit("/dashboard");
        expect(variables.client.currentUrl()).toInclude("/dashboard");

        variables.client.logout().visit("/dashboard");
        expect(variables.client.currentUrl()).toInclude("/login");
    });
});
```

- [ ] **Step 3: Run — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: FAIL — `loginAs`, `logout` don't exist.

- [ ] **Step 4: Implement auth methods**

Append to `BrowserClient.cfc`:

```cfm
// ─── Auth ────────────────────────────────────────────────────────

public BrowserClient function loginAs(required any identifier) {
    // POST to test-only login route via the browser context's request API,
    // so cookies flow through the same jar the page uses.
    var reqCtx = variables.context.request();
    var body = {};
    body["identifier"] = toString(arguments.identifier);

    var postOpts = createObject("java", "com.microsoft.playwright.APIRequestContext$RequestOptions")
        .init();
    postOpts.setData(serializeJSON(body));
    postOpts.setHeader("Content-Type", "application/json");

    var response = reqCtx.post(variables.baseUrl & "/_browser/login-as", postOpts);

    if (response.status() == 501) {
        throw(
            type="Wheels.BrowserTestLoginHookMissing",
            message="App has not defined $signInAsForBrowserTest(identifier). "
                & "Define it in app/events/onapplicationstart.cfm or app/events/browsertest.cfm."
        );
    }

    if (response.status() != 204) {
        throw(
            type="Wheels.BrowserTestLoginFailed",
            message="Test-only login endpoint returned " & response.status()
                & ": " & response.text()
        );
    }

    return this;
}

public BrowserClient function logout() {
    variables.context.clearCookies();
    return this;
}
```

- [ ] **Step 5: Run — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc \
        vendor/wheels/tests/fixtures/browserapp/app/events/onapplicationstart.cfm
git commit -m "feat(test): BrowserClient loginAs and logout"
```

---

## Task 12: `BrowserClient` — text + visibility + presence assertions

Adds: `assertSee`, `assertDontSee`, `assertSeeIn`, `assertVisible`, `assertMissing`, `assertPresent`, `assertNotPresent`.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Modify: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Add tests**

Append to `BrowserIntegrationSpec.cfc`:

```cfm
describe("BrowserClient text/visibility assertions", () => {

    beforeEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context = variables.browser.newContext();
        variables.page = variables.context.newPage();
        variables.client = CreateObject("component", "wheels.wheelstest.BrowserClient")
            .init(page=variables.page, context=variables.context, baseUrl=variables.baseUrl);
    });

    afterEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context.close();
    });

    it("assertSee(text) passes when text is on page", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login").assertSee("Log in");
    });

    it("assertSee(text) throws when text is absent", () => {
        if (variables.skipBrowserTests) { return; }
        expect(() => {
            variables.client.visit("/login").assertSee("Nonexistent content");
        }).toThrow(type="Wheels.BrowserAssertionFailed");
    });

    it("assertDontSee(text) passes when text is absent", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login").assertDontSee("Nonexistent content");
    });

    it("assertSeeIn(selector, text) scopes to element", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login").assertSeeIn("h1", "Log in");
    });

    it("assertVisible(selector) passes when element is rendered", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login").assertVisible("##email");
    });

    it("assertMissing(selector) passes when element not in DOM", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login").assertMissing("##nonexistent-element");
    });
});
```

- [ ] **Step 2: Run — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```

- [ ] **Step 3: Implement assertions**

Append to `BrowserClient.cfc`:

```cfm
// ─── Assertions: text + visibility ───────────────────────────────

public BrowserClient function assertSee(required string text) {
    var content = variables.page.content();
    if (!findNoCase(arguments.text, content)) {
        $assertFail("Expected page to contain '" & arguments.text & "'");
    }
    return this;
}

public BrowserClient function assertDontSee(required string text) {
    var content = variables.page.content();
    if (findNoCase(arguments.text, content)) {
        $assertFail("Expected page NOT to contain '" & arguments.text & "'");
    }
    return this;
}

public BrowserClient function assertSeeIn(
    required string selector,
    required string text
) {
    var elementText = $locator(arguments.selector).textContent();
    if (!findNoCase(arguments.text, elementText)) {
        $assertFail("Expected '" & arguments.selector & "' to contain '"
            & arguments.text & "', got '" & elementText & "'");
    }
    return this;
}

public BrowserClient function assertVisible(required string selector) {
    if (!$locator(arguments.selector).isVisible()) {
        $assertFail("Expected '" & arguments.selector & "' to be visible");
    }
    return this;
}

public BrowserClient function assertMissing(required string selector) {
    var count = $locator(arguments.selector).count();
    if (count > 0) {
        $assertFail("Expected '" & arguments.selector & "' to be missing, found "
            & count & " elements");
    }
    return this;
}

public BrowserClient function assertPresent(required string selector) {
    var count = $locator(arguments.selector).count();
    if (count == 0) {
        $assertFail("Expected '" & arguments.selector & "' to be present in DOM");
    }
    return this;
}

public BrowserClient function assertNotPresent(required string selector) {
    var count = $locator(arguments.selector).count();
    if (count > 0) {
        $assertFail("Expected '" & arguments.selector & "' to be absent from DOM");
    }
    return this;
}

// ─── Assertion internals ─────────────────────────────────────────

private void function $assertFail(required string message) {
    throw(
        type="Wheels.BrowserAssertionFailed",
        message=arguments.message
    );
}
```

- [ ] **Step 4: Run — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): BrowserClient text and visibility assertions"
```

---

## Task 13: `BrowserClient` — URL, query, title assertions

Adds: `assertUrlIs`, `assertRouteIs`, `assertQueryStringHas`, `assertQueryStringMissing`, `assertTitleContains`.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Modify: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Add tests**

Append:

```cfm
describe("BrowserClient URL/title assertions", () => {

    beforeEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context = variables.browser.newContext();
        variables.page = variables.context.newPage();
        variables.client = CreateObject("component", "wheels.wheelstest.BrowserClient")
            .init(page=variables.page, context=variables.context, baseUrl=variables.baseUrl);
    });

    afterEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context.close();
    });

    it("assertUrlIs('/login') passes on matching path", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login").assertUrlIs("/login");
    });

    it("assertUrlIs throws on mismatch", () => {
        if (variables.skipBrowserTests) { return; }
        expect(() => {
            variables.client.visit("/login").assertUrlIs("/wrong");
        }).toThrow(type="Wheels.BrowserAssertionFailed");
    });

    it("assertQueryStringHas(key, value) passes when param present", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/?foo=bar").assertQueryStringHas("foo", "bar");
    });

    it("assertQueryStringHas(key) with no value asserts presence only", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/?foo=bar").assertQueryStringHas("foo");
    });

    it("assertQueryStringMissing(key) passes when param absent", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/").assertQueryStringMissing("baz");
    });
});
```

- [ ] **Step 2: Run — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```

- [ ] **Step 3: Implement**

Append to `BrowserClient.cfc`:

```cfm
// ─── Assertions: URL + query + title ─────────────────────────────

public BrowserClient function assertUrlIs(required string path) {
    var current = $pathFromUrl(variables.page.url());
    if (current != arguments.path) {
        $assertFail("Expected URL path '" & arguments.path & "', got '" & current & "'");
    }
    return this;
}

public BrowserClient function assertRouteIs(
    required string name,
    struct params = {}
) {
    var expectedUrl = urlFor(argumentCollection=arguments);
    return assertUrlIs(expectedUrl);
}

public BrowserClient function assertQueryStringHas(
    required string key,
    string value = ""
) {
    var query = $queryParamsFromUrl(variables.page.url());
    if (!structKeyExists(query, arguments.key)) {
        $assertFail("Expected query string to contain '" & arguments.key
            & "', current params: " & serializeJSON(query));
    }
    if (len(arguments.value) > 0 && query[arguments.key] != arguments.value) {
        $assertFail("Expected '" & arguments.key & "' = '" & arguments.value
            & "', got '" & query[arguments.key] & "'");
    }
    return this;
}

public BrowserClient function assertQueryStringMissing(required string key) {
    var query = $queryParamsFromUrl(variables.page.url());
    if (structKeyExists(query, arguments.key)) {
        $assertFail("Expected query string to NOT contain '" & arguments.key & "'");
    }
    return this;
}

public BrowserClient function assertTitleContains(required string text) {
    var title = variables.page.title();
    if (!findNoCase(arguments.text, title)) {
        $assertFail("Expected title to contain '" & arguments.text
            & "', got '" & title & "'");
    }
    return this;
}

// ─── URL parsing helpers ─────────────────────────────────────────

private string function $pathFromUrl(required string url) {
    var noScheme = reReplace(arguments.url, "^https?://", "");
    var firstSlash = find("/", noScheme);
    if (firstSlash == 0) {
        return "/";
    }
    var pathPlusQuery = mid(noScheme, firstSlash, len(noScheme));
    var qIdx = find("?", pathPlusQuery);
    if (qIdx > 0) {
        return left(pathPlusQuery, qIdx - 1);
    }
    return pathPlusQuery;
}

private struct function $queryParamsFromUrl(required string url) {
    var result = {};
    var qIdx = find("?", arguments.url);
    if (qIdx == 0) {
        return result;
    }
    var queryString = mid(arguments.url, qIdx + 1, len(arguments.url));
    var pairs = listToArray(queryString, "&");
    for (var p in pairs) {
        var parts = listToArray(p, "=", false, true);
        if (arrayLen(parts) == 2) {
            result[parts[1]] = urlDecode(parts[2]);
        } else if (arrayLen(parts) == 1) {
            result[parts[1]] = "";
        }
    }
    return result;
}
```

- [ ] **Step 4: Run — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): BrowserClient URL and query assertions"
```

---

## Task 14: `BrowserClient` — form/attr assertions + terminals

Adds: `assertInputValue`, `assertChecked`, `assertHasClass`, `title`, `pageSource`, `text`, `value`, `screenshot`.

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserClient.cfc`
- Modify: `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc`

- [ ] **Step 1: Add tests**

Append:

```cfm
describe("BrowserClient form assertions + terminals", () => {

    beforeEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context = variables.browser.newContext();
        variables.page = variables.context.newPage();
        variables.client = CreateObject("component", "wheels.wheelstest.BrowserClient")
            .init(page=variables.page, context=variables.context, baseUrl=variables.baseUrl);
    });

    afterEach(() => {
        if (variables.skipBrowserTests) { return; }
        variables.context.close();
    });

    it("assertInputValue(selector, value) passes on matching value", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client
            .visit("/login")
            .fill("##email", "foo@example.com")
            .assertInputValue("##email", "foo@example.com");
    });

    it("value(selector) returns current input value", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login").fill("##email", "x@y.com");
        expect(variables.client.value("##email")).toBe("x@y.com");
    });

    it("text(selector) returns element text content", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login");
        expect(variables.client.text("h1")).toBe("Log in");
    });

    it("title() returns page title", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login");
        expect(len(variables.client.title())).toBeGT(0);
    });

    it("pageSource() returns full HTML", () => {
        if (variables.skipBrowserTests) { return; }
        variables.client.visit("/login");
        expect(variables.client.pageSource()).toInclude("<form");
    });

    it("screenshot(path) writes PNG file", () => {
        if (variables.skipBrowserTests) { return; }
        var path = getTempDirectory() & "wheels-test-" & createUUID() & ".png";
        variables.client.visit("/login").screenshot(path);
        try {
            expect(fileExists(path)).toBeTrue();
            expect(getFileInfo(path).size).toBeGT(0);
        } finally {
            if (fileExists(path)) {
                fileDelete(path);
            }
        }
    });
});
```

- [ ] **Step 2: Run — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```

- [ ] **Step 3: Implement**

Append to `BrowserClient.cfc`:

```cfm
// ─── Assertions: form + attributes ───────────────────────────────

public BrowserClient function assertInputValue(
    required string selector,
    required string value
) {
    var actual = $locator(arguments.selector).inputValue();
    if (actual != arguments.value) {
        $assertFail("Expected input '" & arguments.selector & "' value '"
            & arguments.value & "', got '" & actual & "'");
    }
    return this;
}

public BrowserClient function assertChecked(required string selector) {
    if (!$locator(arguments.selector).isChecked()) {
        $assertFail("Expected '" & arguments.selector & "' to be checked");
    }
    return this;
}

public BrowserClient function assertHasClass(
    required string selector,
    required string class
) {
    var classAttr = $locator(arguments.selector).getAttribute("class") ?: "";
    var classes = listToArray(classAttr, " ");
    if (!arrayContainsNoCase(classes, arguments.class)) {
        $assertFail("Expected '" & arguments.selector & "' to have class '"
            & arguments.class & "', got '" & classAttr & "'");
    }
    return this;
}

// ─── Terminals ───────────────────────────────────────────────────

public string function title() {
    return variables.page.title();
}

public string function pageSource() {
    return variables.page.content();
}

public string function text(required string selector) {
    return $locator(arguments.selector).textContent();
}

public string function value(required string selector) {
    return $locator(arguments.selector).inputValue();
}

public BrowserClient function screenshot(required string path) {
    var opts = createObject("java", "com.microsoft.playwright.Page$ScreenshotOptions").init();
    opts.setPath(createObject("java", "java.nio.file.Paths").get(arguments.path, []));
    variables.page.screenshot(opts);
    return this;
}
```

- [ ] **Step 4: Run — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserIntegration
```

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserClient.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc
git commit -m "feat(test): BrowserClient form assertions and terminals"
```

---

## Task 15: `BrowserTest` base class — properties + beforeAll/afterAll

**Files:**
- Create: `vendor/wheels/wheelstest/BrowserTest.cfc`
- Create: `vendor/wheels/tests/specs/wheelstest/BrowserTestLifecycleSpec.cfc`

- [ ] **Step 1: Write failing test**

Create `vendor/wheels/tests/specs/wheelstest/BrowserTestLifecycleSpec.cfc`:

```cfm
/**
 * Self-test: exercises BrowserTest base class by creating a minimal
 * spec that extends it and verifying the lifecycle hooks fire in order.
 */
component extends="wheels.BrowserTest" {

    this.browserEngine = "chromium";
    this.keepSignedInAs = "";          // start with no auto-login
    this.browserViewport = "desktop";
    this.screenshotOnFailure = false;  // keep the spec clean

    function run() {
        describe("BrowserTest lifecycle", () => {

            it("this.browser is populated before each it block", () => {
                if (!isObject(this.browser)) {
                    fail("Expected this.browser to be populated");
                }
                expect(isObject(this.browser)).toBeTrue();
            });

            it("this.browser has visit() method", () => {
                expect(structKeyExists(this.browser, "visit")).toBeTrue();
            });

            it("successive it blocks get fresh contexts (cookies reset)", () => {
                // Set a cookie in this test; next test should not see it
                this.browser.visit("/").setCookie("leaky", "yes");
                expect(this.browser.cookie("leaky")).toBe("yes");
                variables.$leakCheck = "set";
            });

            it("cookies from previous it block are gone", () => {
                this.browser.visit("/");
                expect(this.browser.cookie("leaky")).toBe("");
            });
        });
    }
}
```

- [ ] **Step 2: Run — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserTestLifecycle
```
Expected: FAIL — `wheels.BrowserTest` doesn't exist.

- [ ] **Step 3: Create `BrowserTest.cfc`**

Create `vendor/wheels/wheelstest/BrowserTest.cfc`:

```cfm
/**
 * TestBox base class for browser-driven specs.
 *
 * Usage:
 *   component extends="wheels.BrowserTest" {
 *       this.keepSignedInAs = "alice@example.com";  // optional
 *       this.browserEngine = "chromium";            // optional
 *       this.browserViewport = "desktop";           // optional
 *
 *       function run() {
 *           describe("...", () => {
 *               it("...", () => {
 *                   this.browser.visit("/...")...
 *               });
 *           });
 *       }
 *   }
 *
 * Lifecycle:
 *   beforeAll  — acquire Browser singleton; if keepSignedInAs set, capture storageState
 *   beforeEach — create fresh context + page; wire into new BrowserClient; inject as this.browser
 *   afterEach  — dump artifacts on failure; close context
 *   afterAll   — release browser handle (Playwright stays alive for next spec)
 */
component extends="wheels.WheelsTest" {

    this.keepSignedInAs = "";
    this.browserViewport = "desktop";
    this.browserEngine = "chromium";
    this.screenshotOnFailure = true;
    this.traceOnFailure = false;
    this.browser = "";

    // Internal
    variables.$launcher = "";
    variables.$browser = "";
    variables.$context = "";
    variables.$page = "";
    variables.$savedState = "";
    variables.$baseUrl = "";

    function beforeAll() {
        variables.$launcher = $ensureLauncher();
        variables.$browser = variables.$launcher.acquireBrowser(engine=this.browserEngine);
        variables.$baseUrl = $resolveBaseUrl();

        if (len(this.keepSignedInAs) > 0) {
            variables.$savedState = $captureStorageState(
                identifier=this.keepSignedInAs,
                browser=variables.$browser,
                baseUrl=variables.$baseUrl
            );
        }
    }

    function afterAll() {
        // The launcher + browser are process-scoped; don't close them here.
        // Only null our refs.
        variables.$browser = "";
    }

    /**
     * Locates or creates the shared BrowserLauncher. Stored in application
     * scope so one Playwright instance serves all specs in a run.
     */
    private any function $ensureLauncher() {
        if (!structKeyExists(application, "$wheelsBrowserLauncher")) {
            var l = CreateObject("component", "wheels.wheelstest.BrowserLauncher").init();
            var installDir = l.resolveInstallDir();
            var version = l.$manifest.playwrightJavaVersion;
            var clientJar = l.$jarPath(installDir=installDir, version=version);
            var driverJar = l.$driverBundlePath(installDir=installDir, version=version);
            l.$verifyInstall(jarPath=clientJar);
            l.$verifyInstall(jarPath=driverJar);
            l.$loadJars(jarPaths=[clientJar, driverJar]);
            application.$wheelsBrowserLauncher = l;
        }
        return application.$wheelsBrowserLauncher;
    }

    private string function $resolveBaseUrl() {
        return server.system.environment.WHEELS_BROWSER_TEST_BASE_URL
            ?: "http://localhost:8080";
    }

    /**
     * Logs in as the given identifier via the test-only route, captures
     * the context's storage state (cookies + localStorage), returns a JSON
     * string that can be replayed via newContext(storageState=...).
     */
    private string function $captureStorageState(
        required any identifier,
        required any browser,
        required string baseUrl
    ) {
        var tmpContext = arguments.browser.newContext();
        var tmpPage = tmpContext.newPage();
        var tmpClient = CreateObject("component", "wheels.wheelstest.BrowserClient")
            .init(page=tmpPage, context=tmpContext, baseUrl=arguments.baseUrl);
        tmpClient.loginAs(arguments.identifier);

        var state = tmpContext.storageState();
        tmpContext.close();
        return state;
    }
}
```

- [ ] **Step 4: Add beforeEach + afterEach (covered in next task — for now stub them)**

Append to `BrowserTest.cfc` above the final `}`:

```cfm
    /**
     * Creates a fresh context + page per it block. Replays storageState
     * if keepSignedInAs is set.
     */
    function beforeEach() {
        var newContextOpts = createObject("java", "com.microsoft.playwright.Browser$NewContextOptions").init();

        if (len(variables.$savedState) > 0) {
            newContextOpts.setStorageState(variables.$savedState);
        }

        $applyViewport(contextOpts=newContextOpts);

        variables.$context = variables.$browser.newContext(newContextOpts);
        variables.$page = variables.$context.newPage();

        this.browser = CreateObject("component", "wheels.wheelstest.BrowserClient")
            .init(
                page=variables.$page,
                context=variables.$context,
                baseUrl=variables.$baseUrl
            );
    }

    function afterEach() {
        if (isObject(variables.$context)) {
            try {
                variables.$context.close();
            } catch (any e) {
                // best-effort
            }
            variables.$context = "";
            variables.$page = "";
            this.browser = "";
        }
    }

    private void function $applyViewport(required any contextOpts) {
        var vp = this.browserViewport;
        var w = 1440;
        var h = 900;
        if (isStruct(vp)) {
            w = vp.w ?: 1440;
            h = vp.h ?: 900;
        } else {
            switch (vp) {
                case "mobile":  w = 375;  h = 667;  break;
                case "tablet":  w = 768;  h = 1024; break;
                case "desktop": w = 1440; h = 900;  break;
            }
        }
        var vpSize = createObject("java", "com.microsoft.playwright.options.ViewportSize")
            .init(javaCast("int", w), javaCast("int", h));
        arguments.contextOpts.setViewportSize(vpSize);
    }
```

- [ ] **Step 5: Run — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserTestLifecycle
```
Expected: PASS on all 4 lifecycle specs.

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserTest.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserTestLifecycleSpec.cfc
git commit -m "feat(test): BrowserTest base class with per-it context lifecycle"
```

---

## Task 16: `BrowserTest` — artifact dumping on failure

**Files:**
- Modify: `vendor/wheels/wheelstest/BrowserTest.cfc`
- Create: `vendor/wheels/tests/specs/wheelstest/BrowserArtifactsSpec.cfc`

- [ ] **Step 1: Write failing test**

Create `vendor/wheels/tests/specs/wheelstest/BrowserArtifactsSpec.cfc`:

```cfm
component extends="wheels.BrowserTest" {

    this.screenshotOnFailure = true;
    this.traceOnFailure = false;
    this.$artifactRoot = expandPath("/tests/_artifacts/");

    function beforeAll() {
        super.beforeAll();
        if (directoryExists(this.$artifactRoot)) {
            directoryDelete(this.$artifactRoot, true);
        }
    }

    function run() {
        describe("Artifact dumping", () => {

            it("dumps screenshot + HTML on intentionally-failing assertion", () => {
                // Intentionally fail, but catch it so the spec itself passes
                var failed = false;
                try {
                    this.browser.visit("/login").assertSee("Nonexistent text");
                } catch (Wheels.BrowserAssertionFailed e) {
                    failed = true;
                }

                expect(failed).toBeTrue();

                // Now manually trigger artifact dump — normally this would be in afterEach
                // For this test, we simulate the failure hook
                $dumpArtifactsForSpec(
                    specName="BrowserArtifactsSpec",
                    itName="dumps-screenshot-html"
                );

                var screenshotGlob = directoryList(
                    this.$artifactRoot,
                    true,
                    "path",
                    "*.png"
                );
                expect(arrayLen(screenshotGlob)).toBeGT(0);

                var htmlGlob = directoryList(
                    this.$artifactRoot,
                    true,
                    "path",
                    "*.html"
                );
                expect(arrayLen(htmlGlob)).toBeGT(0);
            });
        });
    }
}
```

- [ ] **Step 2: Run — expect fail**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserArtifacts
```
Expected: FAIL — `$dumpArtifactsForSpec` doesn't exist.

- [ ] **Step 3: Add artifact dumping to `BrowserTest.cfc`**

In `vendor/wheels/wheelstest/BrowserTest.cfc`, update `afterEach` to detect failures and dump artifacts. Replace the existing `afterEach()`:

```cfm
    function afterEach() {
        // TestBox exposes the current spec result via variables.currentSpec
        // after the it() callback completes. Dump artifacts if failed.
        var specFailed = $currentSpecFailed();

        if (specFailed && this.screenshotOnFailure && isObject(variables.$page)) {
            $dumpArtifactsForSpec(
                specName=$specComponentName(),
                itName=$currentSpecItName()
            );
        }

        if (isObject(variables.$context)) {
            try {
                variables.$context.close();
            } catch (any e) {
            }
            variables.$context = "";
            variables.$page = "";
            this.browser = "";
        }
    }

    /**
     * Dumps PNG + HTML + optional trace to tests/_artifacts/<run>/<spec>/<it>.*
     * The run dir is created once per test session.
     */
    public void function $dumpArtifactsForSpec(
        required string specName,
        required string itName
    ) {
        if (!structKeyExists(application, "$wheelsBrowserRunDir")) {
            var ts = dateTimeFormat(now(), "yyyy-MM-dd-HHmmss");
            var runDir = (this.$artifactRoot ?: expandPath("/tests/_artifacts/")) & ts & "/";
            directoryCreate(runDir, true, true);
            application.$wheelsBrowserRunDir = runDir;
        }
        var base = application.$wheelsBrowserRunDir & arguments.specName & "/";
        if (!directoryExists(base)) {
            directoryCreate(base);
        }

        var safeIt = reReplace(arguments.itName, "[^a-zA-Z0-9-]", "-", "all");

        // Screenshot
        try {
            var shot = createObject("java", "com.microsoft.playwright.Page$ScreenshotOptions").init();
            shot.setPath(
                createObject("java", "java.nio.file.Paths").get(base & safeIt & ".png", [])
            );
            variables.$page.screenshot(shot);
        } catch (any e) {
        }

        // HTML source
        try {
            var html = variables.$page.content();
            fileWrite(base & safeIt & ".html", html);
        } catch (any e) {
        }

        // Trace (if enabled)
        if (this.traceOnFailure) {
            try {
                var traceOpts = createObject("java", "com.microsoft.playwright.Tracing$StopOptions").init();
                traceOpts.setPath(
                    createObject("java", "java.nio.file.Paths").get(base & safeIt & ".trace.zip", [])
                );
                variables.$context.tracing().stop(traceOpts);
            } catch (any e) {
            }
        }
    }

    private boolean function $currentSpecFailed() {
        // TestBox stores current spec results on the testResult struct.
        // Fall back to false if not accessible (keeps spec resilient).
        try {
            var tr = variables.testResults ?: "";
            if (isStruct(tr) && structKeyExists(tr, "currentSpec")) {
                return (tr.currentSpec.status ?: "") == "failed";
            }
        } catch (any e) {
        }
        return false;
    }

    private string function $specComponentName() {
        var meta = getMetadata(this);
        var parts = listToArray(meta.name, ".");
        return parts[arrayLen(parts)];
    }

    private string function $currentSpecItName() {
        try {
            return variables.testResults.currentSpec.name ?: "unknown";
        } catch (any e) {
            return "unknown";
        }
    }
```

- [ ] **Step 4: Run — expect pass**

```bash
bash tools/test-local.sh --filter=wheelstest.BrowserArtifacts
```
Expected: PASS. Artifact dir `tests/_artifacts/<timestamp>/BrowserArtifactsSpec/` exists with `.png` and `.html`.

- [ ] **Step 5: Add `tests/_artifacts/` to `.gitignore`**

Edit `.gitignore` and append:

```
# Browser test artifacts (screenshots, HTML dumps, traces)
tests/_artifacts/
```

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/wheelstest/BrowserTest.cfc \
        vendor/wheels/tests/specs/wheelstest/BrowserArtifactsSpec.cfc \
        .gitignore
git commit -m "feat(test): BrowserTest artifact dumping on failure"
```

---

## Task 17: End-to-end spec using `BrowserTest` against the fixture app

Final integration test that exercises the whole foundation end-to-end.

**Files:**
- Create: `vendor/wheels/tests/specs/wheelstest/BrowserEndToEndSpec.cfc`

- [ ] **Step 1: Write end-to-end spec**

Create `vendor/wheels/tests/specs/wheelstest/BrowserEndToEndSpec.cfc`:

```cfm
component extends="wheels.BrowserTest" {

    this.browserEngine = "chromium";
    this.keepSignedInAs = "";
    this.browserViewport = "desktop";
    this.screenshotOnFailure = true;

    function run() {
        describe("End-to-end login flow", () => {

            it("signs in successfully with valid credentials", () => {
                this.browser
                    .visit("/login")
                    .assertSee("Log in")
                    .fill("##email", "alice@example.com")
                    .fill("##password", "secret")
                    .click("button[type=submit]")
                    .assertUrlIs("/dashboard")
                    .assertSee("Welcome, alice@example.com");
            });

            it("rejects invalid credentials with flash error", () => {
                this.browser
                    .visit("/login")
                    .fill("##email", "alice@example.com")
                    .fill("##password", "wrong")
                    .click("button[type=submit]")
                    .assertUrlIs("/login")
                    .assertSee("Invalid credentials");
            });

            it("logout clears session and redirects to login", () => {
                this.browser
                    .visit("/login")
                    .fill("##email", "alice@example.com")
                    .fill("##password", "secret")
                    .click("button[type=submit]")
                    .assertUrlIs("/dashboard")
                    .click("button:has-text('Log out')")
                    .assertUrlIs("/login");
            });

            it("loginAs() bypasses form, sets session directly", () => {
                this.browser
                    .loginAs("99")
                    .visit("/dashboard")
                    .assertUrlIs("/dashboard");
            });
        });
    }
}
```

- [ ] **Step 2: Run — expect pass**

Make sure fixture app server is running:
```bash
cd /Users/peter/GitHub/wheels-dev/wheels && lucli server run --port=8080 &
sleep 5
bash tools/test-local.sh --filter=wheelstest.BrowserEndToEnd
```
Expected: PASS on all 4 end-to-end specs.

- [ ] **Step 3: Commit**

```bash
git add vendor/wheels/tests/specs/wheelstest/BrowserEndToEndSpec.cfc
git commit -m "test(test): end-to-end browser spec against fixture app"
```

---

## Task 18: Document the foundation in CLAUDE.md + create `.ai` reference

**Files:**
- Modify: `CLAUDE.md`
- Create: `.ai/wheels/testing/browser-testing.md`

- [ ] **Step 1: Add a brief "Browser Testing" section to CLAUDE.md**

In `CLAUDE.md`, after the "Testing Quick Reference" section (around line 450 based on typical layout), add:

```markdown
## Browser Testing Quick Reference

Foundation landed in v4.0 (PR 1 of 4). Specs extend `wheels.BrowserTest`
and use `this.browser` — a fluent DSL that wraps Playwright Java.

```cfm
// tests/specs/browser/LoginBrowserSpec.cfc
component extends="wheels.BrowserTest" {
    this.keepSignedInAs = "";      // or "alice@example.com" for auto-login
    this.browserEngine = "chromium";

    function run() {
        describe("Login flow", () => {
            it("signs in", () => {
                this.browser
                    .visit("/login")
                    .fill("##email", "alice@example.com")
                    .fill("##password", "secret")
                    .click("button[type=submit]")
                    .assertUrlIs("/dashboard")
                    .assertSee("Welcome");
            });
        });
    }
}
```

Install Playwright locally before first run:
```bash
bash tools/install-playwright.sh    # PR 1; replaced by `wheels browser:install` in PR 2
```

Then run browser specs:
```bash
bash tools/test-local.sh --filter=wheelstest.BrowserEndToEnd
```

Failure artifacts (screenshots, HTML) dumped to `tests/_artifacts/<timestamp>/`.

Full reference: `.ai/wheels/testing/browser-testing.md`.
```

- [ ] **Step 2: Create the `.ai` reference doc**

Create `.ai/wheels/testing/browser-testing.md`:

```markdown
# Browser Testing (`wheels.BrowserTest`)

Native browser testing added in Wheels v4.0 via Playwright Java. Specs
extend `wheels.BrowserTest` and drive a real Chromium/Firefox/WebKit
browser through a fluent DSL.

## Installation

Before first use, install Playwright:

    bash tools/install-playwright.sh

This downloads the Playwright Java JAR and Chromium into
`~/.wheels/browser/`. Runs idempotent; re-run to update.

For CI, cache `~/.wheels/browser/` by the SHA of
`vendor/wheels/browser-manifest.json`.

## Spec structure

    component extends="wheels.BrowserTest" {

        // Optional — all with sensible defaults
        this.browserEngine = "chromium";        // chromium | firefox | webkit
        this.keepSignedInAs = "";               // identifier for storageState replay
        this.browserViewport = "desktop";       // desktop | tablet | mobile | struct{w,h}
        this.screenshotOnFailure = true;
        this.traceOnFailure = false;

        function run() {
            describe("My feature", () => {
                it("does the thing", () => {
                    this.browser.visit("/").assertSee("Hello");
                });
            });
        }
    }

## Method catalog

Navigation: visit, visitRoute, back, forward, refresh
Interaction: click, press, fill, type, clear, select, check, uncheck,
             attach, dragAndDrop
Keyboard: keys, pressEnter, pressTab, pressEscape
Dialogs: acceptDialog, dismissDialog, typeInDialog
Waiting: waitFor, waitForText, waitForUrl
Scoping: within(selector, callback)
Viewport: resize, resizeToMobile, resizeToTablet, resizeToDesktop
Auth: loginAs, logout
Cookies: setCookie, deleteCookie, cookie
Script: script, pause
Assertions (text): assertSee, assertDontSee, assertSeeIn
Assertions (visibility): assertVisible, assertMissing, assertPresent, assertNotPresent
Assertions (URL): assertUrlIs, assertRouteIs, assertQueryStringHas,
                  assertQueryStringMissing, assertTitleContains
Assertions (form): assertInputValue, assertChecked, assertHasClass
Terminals: currentUrl, title, pageSource, text, value, screenshot

## `loginAs` contract

For `this.browser.loginAs(identifier)` and `this.keepSignedInAs` to work,
the app must define:

    // app/events/onapplicationstart.cfm
    application.$signInAsForBrowserTest = function(required any identifier) {
        session.userId = arguments.identifier;
    };

The hook receives whatever the test passed (number, email, UUID). App
decides how to resolve it.

Without the hook defined, `loginAs()` throws `Wheels.BrowserTestLoginHookMissing`.

## Failure artifacts

On any assertion failure, `afterEach` dumps to:

    tests/_artifacts/<timestamp>/<SpecName>/<it-name>.png
    tests/_artifacts/<timestamp>/<SpecName>/<it-name>.html
    tests/_artifacts/<timestamp>/<SpecName>/<it-name>.trace.zip  (if traceOnFailure)

Paths are clickable in modern terminals (iTerm2, VS Code).

Set `this.screenshotOnFailure = false` to opt out.

## Common pitfalls

- **`Wheels.BrowserNotInstalled`**: Run `bash tools/install-playwright.sh`
  (v4.0) or `wheels browser:install` (v4.1+).
- **Tests hang**: server not running. Browser tests need a live app at
  `WHEELS_BROWSER_TEST_BASE_URL` (default `http://localhost:8080`).
  Start with `lucli server run --port=8080`.
- **`##` in selectors**: CFML requires `##` to emit a literal `#`. In
  selectors: `"##email"` becomes `"#email"` at runtime.
- **Cookies persisting across tests**: shouldn't happen — each `it` gets
  a fresh context. If you see this, check the spec didn't set cookies in
  `beforeAll` instead of `beforeEach`.

## Deferred to later PRs

- CLI (`wheels browser:install`, `wheels browser:test`) — PR 2
- Hotwire dogfood specs — PR 3
- CI workflow integration — PR 4
- Adobe CF / BoxLang support — v4.1+
- Parallel browser test execution — v4.1+
- Multi-engine per spec CFC — v4.1+
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md .ai/wheels/testing/browser-testing.md
git commit -m "docs(test): add browser testing quick reference and full guide"
```

---

## Task 19: Verify full suite still passes

- [ ] **Step 1: Run all core tests to verify no regressions**

```bash
bash tools/test-local.sh
```
Expected: all existing specs still pass (no impact on non-browser tests). New browser specs pass when `~/.wheels/browser/` is populated; gracefully skip otherwise.

- [ ] **Step 2: Run browser suite in isolation to verify clean execution**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels && lucli server run --port=8080 &
sleep 5
bash tools/test-local.sh --filter=wheelstest
```
Expected: `BrowserLauncherSpec`, `BrowserTestLoginControllerSpec`, `BrowserIntegrationSpec`, `BrowserTestLifecycleSpec`, `BrowserArtifactsSpec`, `BrowserEndToEndSpec` all pass.

- [ ] **Step 3: Final branch cleanup and PR creation**

Ensure all commits are on `peter/browser-testing-foundation`:

```bash
git checkout -b peter/browser-testing-foundation  # if not already on it
git log --oneline develop..HEAD                   # verify commits
git push -u origin peter/browser-testing-foundation

gh pr create --title "feat(test): browser testing foundation (PR 1 of 4)" --body "$(cat <<'EOF'
## Summary

- Adds `BrowserClient.cfc` — fluent DSL for browser automation (~35 methods)
- Adds `BrowserLauncher.cfc` — Playwright Java JAR loading + singleton management
- Adds `BrowserTest.cfc` — TestBox base class with per-it context lifecycle, storageState replay, artifact dumping
- Adds test-only `POST /_browser/login-as` route (environment-guarded)
- Adds `BrowserTestLoginController.cfc` + app-defined `$signInAsForBrowserTest` hook contract
- Adds `tools/install-playwright.sh` (temporary bootstrap; replaced by `wheels browser:install` in PR 2)
- Adds fixture app + end-to-end integration spec proving the full flow

Closes item 4 of `docs/wheels-vs-frameworks.md` "Where Wheels Trails" (PR 1 of 4).

Spec: `docs/superpowers/specs/2026-04-15-browser-testing-design.md`
Plan: `docs/superpowers/plans/2026-04-15-browser-testing-foundation.md`

## Test plan

- [ ] `bash tools/install-playwright.sh` succeeds on macOS
- [ ] `bash tools/install-playwright.sh` succeeds on Linux
- [ ] `bash tools/test-local.sh --filter=wheelstest` passes end-to-end
- [ ] Full core test suite still passes (`bash tools/test-local.sh`)
- [ ] Test-only login route does NOT appear in `production` environment
- [ ] Failure artifacts dumped to `tests/_artifacts/` and viewable

## Deferred to follow-up PRs

- PR 2: `wheels browser:install` + `wheels browser:test` CLI + MCP tools
- PR 3: `packages/hotwire/` browser specs (dogfood)
- PR 4: CI workflow + final docs

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR created, returns URL.

---

## Summary

This plan delivers PR 1 of the 4-PR browser testing rollout. It's self-sufficient: the DSL can be used directly from any spec after `bash tools/install-playwright.sh`, without needing the CLI infrastructure from PR 2.

Key invariants:
- `BrowserClient` has no TestBox coupling (can be used standalone)
- `BrowserLauncher` owns one Playwright + Browser per process (not per spec)
- `BrowserTest` creates a fresh context per `it` (cookie/storage isolation)
- Test-only login route guarded by `environment == "testing"`
- All failures dump screenshots + HTML to `tests/_artifacts/<timestamp>/`
