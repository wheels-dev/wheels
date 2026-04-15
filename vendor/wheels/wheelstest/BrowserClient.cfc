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
