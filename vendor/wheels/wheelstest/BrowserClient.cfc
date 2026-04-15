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

    public BrowserClient function init(
        any page = "",
        any context = "",
        string baseUrl = ""
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
        } catch (any e) {}
        if (!envOff) {
            writeOutput("⚠ BrowserClient.pause() called for " & arguments.milliseconds
                & "ms. Remove before committing or set BROWSER_TEST_PAUSE_WARNING=off." & chr(10));
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
                baseUrl=variables.baseUrl
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

    // ─── Terminals ───────────────────────────────────────────────────

    public string function currentUrl() {
        return variables.page.url();
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

}
