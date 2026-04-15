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
        variables.page.locator(arguments.selector).click();
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
        variables.page.locator(arguments.selector).fill(arguments.value);
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
        var emptyStringArr = javaCast("String[]", []);
        var path = createObject("java", "java.nio.file.Paths").get(arguments.filePath, emptyStringArr);
        variables.page.locator(arguments.selector).setInputFiles(path);
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

}
