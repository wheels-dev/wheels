/**
 * Fluent DSL wrapping a Playwright BrowserContext + Page for browser tests.
 * Mirrors TestClient.cfc's shape: chainable methods return `this`,
 * terminals return values.
 *
 * Instantiation: typically done by BrowserTest.cfc's beforeEach hook.
 * For manual use, pass Playwright Java objects directly (BrowserContext,
 * Page) and the base URL of the Wheels app under test.
 */
component {

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

    // ─── Navigation ──────────────────────────────────────────────────

    public BrowserClient function visit(required string path) {
        $requireLeadingSlash(arguments.path);
        variables.page.navigate(variables.baseUrl & arguments.path);
        return this;
    }

    public BrowserClient function visitUrl(required string url) {
        // Escape hatch for absolute URLs (e.g. data:, file://, or another host).
        variables.page.navigate(arguments.url);
        return this;
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

    // ─── Interaction ─────────────────────────────────────────────────

    public BrowserClient function click(required string selector) {
        $locator(arguments.selector).click();
        return this;
    }

    /**
     * Clicks the first element matching the given visible text. Simpler than
     * getByRole because it avoids building Playwright option objects through
     * the URLClassLoader. If you need role-specific matching (e.g. button
     * only, ignoring headings), use click("button:has-text('...')") instead.
     */
    public BrowserClient function press(required string buttonText) {
        variables.page.getByText(arguments.buttonText).first().click();
        return this;
    }

    public BrowserClient function fill(
        required string selector,
        required string value
    ) {
        $locator(arguments.selector).fill(arguments.value);
        return this;
    }

    /**
     * Types character-by-character (like a human). Slower than fill() but
     * triggers per-keystroke event handlers (autosuggest, live validation).
     */
    public BrowserClient function type(
        required string selector,
        required string value
    ) {
        $locator(arguments.selector).pressSequentially(arguments.value);
        return this;
    }

    public BrowserClient function clear(required string selector) {
        $locator(arguments.selector).clear();
        return this;
    }

    public BrowserClient function select(
        required string selector,
        required string value
    ) {
        $locator(arguments.selector).selectOption(arguments.value);
        return this;
    }

    public BrowserClient function check(required string selector) {
        $locator(arguments.selector).check();
        return this;
    }

    public BrowserClient function uncheck(required string selector) {
        $locator(arguments.selector).uncheck();
        return this;
    }

    public BrowserClient function attach(
        required string selector,
        required string filePath
    ) {
        var emptyStringArr = javaCast("String[]", []);
        var path = createObject("java", "java.nio.file.Paths").get(arguments.filePath, emptyStringArr);
        $locator(arguments.selector).setInputFiles(path);
        return this;
    }

    public BrowserClient function dragAndDrop(
        required string fromSelector,
        required string toSelector
    ) {
        $locator(arguments.fromSelector)
            .dragTo($locator(arguments.toSelector));
        return this;
    }

    // ─── Keyboard ────────────────────────────────────────────────────

    /**
     * Press a keyboard key against the element matching `selector`.
     * Key syntax follows Playwright: "Enter", "Tab", "Escape",
     * "Control+A", "Shift+Home", etc.
     */
    public BrowserClient function keys(
        required string selector,
        required string key
    ) {
        $locator(arguments.selector).press(arguments.key);
        return this;
    }

    /**
     * Press Enter. If selector is given, presses inside that element
     * (useful for "submit the form by pressing Enter in the last input").
     * Otherwise sends Enter to whatever has focus.
     */
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
            $locator(arguments.selector).press(arguments.key);
        } else {
            variables.page.keyboard().press(arguments.key);
        }
        return this;
    }

    // ─── Waiting ─────────────────────────────────────────────────────

    /**
     * Waits for a selector to become visible. Uses Playwright's default
     * timeout (30s). seconds param is accepted for API compatibility with
     * the plan, but not currently honored — configurable timeout requires
     * building Locator$WaitForOptions through the URLClassLoader, which is
     * fragile (see Task 7 press() commentary). Uses .first() so selectors
     * that match multiple elements resolve to the first one.
     */
    public BrowserClient function waitFor(
        required string selector,
        numeric seconds = 30
    ) {
        $locator(arguments.selector).first().waitFor();
        return this;
    }

    /**
     * Waits for visible text to appear anywhere on the page. Same timeout
     * caveat as waitFor().
     */
    public BrowserClient function waitForText(
        required string text,
        numeric seconds = 30
    ) {
        variables.page.getByText(arguments.text).first().waitFor();
        return this;
    }

    // ─── Viewport ────────────────────────────────────────────────────

    /**
     * Resize the page's viewport. Takes effect immediately; CSS media
     * queries re-evaluate.
     */
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

    /** iPhone SE-like viewport (common mobile test size). */
    public BrowserClient function resizeToMobile() {
        return resize(375, 667);
    }

    /** iPad portrait-like viewport. */
    public BrowserClient function resizeToTablet() {
        return resize(768, 1024);
    }

    /** Typical laptop viewport. */
    public BrowserClient function resizeToDesktop() {
        return resize(1440, 900);
    }

    // ─── Script + Pause ──────────────────────────────────────────────

    /**
     * Evaluate a JavaScript expression in the page context and return the
     * result. Useful for assertions on computed state or reaching into
     * page.document.activeElement etc.
     *
     *     client.script("() => document.title")
     *     client.script("() => 2 + 2")  // returns 4
     */
    public any function script(required string js) {
        return variables.page.evaluate(arguments.js);
    }

    /**
     * Pauses execution for `milliseconds` ms. For debugging real failures
     * (when you want to hand-inspect browser state) — NOT for synchronizing
     * with the page. Use waitFor/waitForText instead for synchronization;
     * sleeps are flaky and slow.
     *
     * Prints a warning on use so a stray pause doesn't sneak past review.
     * Silenceable via BROWSER_TEST_PAUSE_WARNING=off.
     */
    public BrowserClient function pause(required numeric milliseconds) {
        var envOff = false;
        try {
            envOff = (createObject("java", "java.lang.System")
                .getenv("BROWSER_TEST_PAUSE_WARNING") ?: "on") == "off";
        } catch (any e) {
            // Best-effort: SecurityManager could deny env access. If the read
            // fails we err on the side of warning the user (envOff stays false).
        }
        if (!envOff) {
            // Use System.err rather than writeOutput because TestBox's JSON
            // reporter (the primary CI/LuCLI runner format) discards
            // writeOutput. System.err shows up in the server console
            // regardless of reporter — visibility is the whole point of the
            // warning, so prefer the channel that won't be silenced.
            try {
                createObject("java", "java.lang.System").err.println(
                    "[WARN] BrowserClient.pause() called for " & arguments.milliseconds
                    & "ms. Remove before committing or set BROWSER_TEST_PAUSE_WARNING=off."
                );
            } catch (any e) {
                // Best-effort: if even System.err is unreachable, silently
                // proceed to the sleep. Nothing else useful to do.
            }
        }
        sleep(arguments.milliseconds);
        return this;
    }

    // ─── Scoping ─────────────────────────────────────────────────────

    /**
     * Runs `callback(scopedClient)` with selectors resolved relative to the
     * first element matching `selector`. Useful for "fill the email field
     * inside the signin form, even if there's another email field elsewhere
     * on the page".
     *
     *     client.within("form##signin", (scoped) => {
     *         scoped.fill("##email", "alice@example.com");
     *     });
     */
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

    /**
     * Used by within() to restrict $locator() to a subtree. Public so the
     * parent BrowserClient can set scope on the clone it creates.
     */
    public void function $setScope(required any rootLocator) {
        variables.$scope = arguments.rootLocator;
    }

    // ─── Assertions: text + visibility + presence ────────────────────

    public BrowserClient function assertSee(required string text) {
        if (!findNoCase(arguments.text, variables.page.content())) {
            $assertFail("Expected page to contain '" & arguments.text & "'");
        }
        return this;
    }

    public BrowserClient function assertDontSee(required string text) {
        if (findNoCase(arguments.text, variables.page.content())) {
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
        if (!$locator(arguments.selector).first().isVisible()) {
            $assertFail("Expected '" & arguments.selector & "' to be visible");
        }
        return this;
    }

    public BrowserClient function assertMissing(required string selector) {
        var count = $locator(arguments.selector).count();
        if (count > 0) {
            $assertFail("Expected '" & arguments.selector & "' to be missing, found "
                & count & " element(s)");
        }
        return this;
    }

    public BrowserClient function assertPresent(required string selector) {
        if ($locator(arguments.selector).count() == 0) {
            $assertFail("Expected '" & arguments.selector & "' to be present in DOM");
        }
        return this;
    }

    public BrowserClient function assertNotPresent(required string selector) {
        if ($locator(arguments.selector).count() > 0) {
            $assertFail("Expected '" & arguments.selector & "' to be absent from DOM");
        }
        return this;
    }

    // ─── Assertions: URL + title ─────────────────────────────────────

    /**
     * Exact URL match. For data: / about: / file: URLs, compares full URL.
     * For http(s) URLs, compares the path portion only (protocol + host stripped).
     */
    public BrowserClient function assertUrlIs(required string expected) {
        var current = variables.page.url();
        // If caller passed a path (starts with /), compare path-only; else full URL
        if (left(arguments.expected, 1) == "/") {
            var currentPath = $pathFromUrl(current);
            if (currentPath != arguments.expected) {
                $assertFail("Expected path '" & arguments.expected
                    & "', got '" & currentPath & "' (full URL: '" & current & "')");
            }
        } else if (current != arguments.expected) {
            $assertFail("Expected URL '" & arguments.expected & "', got '" & current & "'");
        }
        return this;
    }

    /** Substring match — more forgiving than assertUrlIs for dynamic URLs. */
    public BrowserClient function assertUrlContains(required string substring) {
        var current = variables.page.url();
        if (!find(arguments.substring, current)) {
            $assertFail("Expected URL to contain '" & arguments.substring
                & "', got '" & current & "'");
        }
        return this;
    }

    public BrowserClient function assertTitleContains(required string text) {
        var pageTitle = variables.page.title();
        if (!findNoCase(arguments.text, pageTitle)) {
            $assertFail("Expected title to contain '" & arguments.text
                & "', got '" & pageTitle & "'");
        }
        return this;
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
            $assertFail("Expected query string NOT to contain '" & arguments.key & "'");
        }
        return this;
    }

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

    public string function currentUrl() {
        return variables.page.url();
    }

    public string function title() {
        return variables.page.title();
    }

    /** Full HTML of the rendered page. */
    public string function pageSource() {
        return variables.page.content();
    }

    /** textContent of the first element matching `selector`. */
    public string function text(required string selector) {
        return $locator(arguments.selector).textContent();
    }

    /** Current value of an input/textarea/select element. */
    public string function value(required string selector) {
        return $locator(arguments.selector).inputValue();
    }

    /**
     * Screenshot to `path`. Uses the no-arg screenshot() → byte[] overload
     * rather than Page$ScreenshotOptions, since building the options class
     * through the URLClassLoader hits Lucee's OSGi-bundle resolver (same
     * trap documented on press() / waitFor() earlier in this file).
     */
    public BrowserClient function screenshot(required string path) {
        var bytes = variables.page.screenshot();
        fileWrite(arguments.path, bytes);
        return this;
    }

    // ─── Accessors (primarily for tests & lifecycle managers) ────────

    public any function getPage() {
        return variables.page;
    }

    public any function getContext() {
        return variables.context;
    }

    public string function getBaseUrl() {
        return variables.baseUrl;
    }

    public any function getLauncher() {
        return variables.$launcher;
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

    /**
     * Returns a locator for `selector`, scoped to our within() subtree when
     * one is set. All interaction methods route through here so within()
     * works uniformly for click/fill/type/check/select/etc.
     */
    private any function $locator(required string selector) {
        if (structKeyExists(variables, "$scope")) {
            return variables.$scope.locator(arguments.selector);
        }
        return variables.page.locator(arguments.selector);
    }

    /**
     * Throws Wheels.BrowserAssertionFailed with the given message. Callers
     * in the DSL use this to surface failures in a way tests can catch
     * distinctly from other errors.
     */
    private void function $assertFail(required string message) {
        throw(
            type="Wheels.BrowserAssertionFailed",
            message=arguments.message
        );
    }

    /**
     * Extract the path portion of a URL, stripping scheme+host and query.
     * Returns "/" when the URL has no explicit path. For data:/file: URLs,
     * returns the full URL (they have no conventional "path").
     */
    private string function $pathFromUrl(required string url) {
        if (!reFindNoCase("^https?://", arguments.url)) {
            return arguments.url;  // not an http(s) URL — can't strip host
        }
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

    /**
     * Parse the query string of a URL into a struct. Keys with no `=`
     * map to empty string. Values are URL-decoded.
     */
    private struct function $queryParamsFromUrl(required string url) {
        var result = {};
        var qIdx = find("?", arguments.url);
        if (qIdx == 0) return result;
        var queryString = mid(arguments.url, qIdx + 1, len(arguments.url));
        // Strip fragment if present
        var hashIdx = find("##", queryString);
        if (hashIdx > 0) queryString = left(queryString, hashIdx - 1);
        var pairs = listToArray(queryString, "&");
        for (var p in pairs) {
            var eqIdx = find("=", p);
            if (eqIdx == 0) {
                result[p] = "";
            } else {
                result[left(p, eqIdx - 1)] = urlDecode(mid(p, eqIdx + 1, len(p)));
            }
        }
        return result;
    }

}
