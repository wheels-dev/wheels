/**
 * Run all tests with TestBox CLI
 * 
 * This command runs all tests using the Wheels test runner.
 * 
 * Examples:
 * wheels test:all
 * wheels test:all --format=junit
 * wheels test:all --coverage --coverageReporter=html
 */
component aliases='wheels test:all' extends="../base" {
    
    /**
     * @type.hint Type of tests to run: (app, core, plugin)
     * @format.hint Output format (txt, json, junit, html)
     * @format.options txt,json,junit,html
     * @coverage.hint Generate coverage report
     * @coverageReporter.hint Coverage reporter format (html, json, xml)
     * @coverageReporter.options html,json,xml
     * @coverageOutputDir.hint Directory for coverage output
     * @verbose.hint Verbose output
     * @failFast.hint Stop on first test failure
     * @directory.hint Test directory to run (default: tests)
     * @recurse.hint Recurse into subdirectories
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test labels to exclude
     * @filter.hint Test filter pattern
     * @servername.hint Name of server to use
     */
    function run(
        string type = "app",
        string format = "txt",
        boolean coverage = false,
        string coverageReporter = "html",
        string coverageOutputDir = "tests/results/coverage",
        boolean verbose = true,
        boolean failFast = false,
        string directory = "",
        boolean recurse = true,
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        string servername = ""
    ) {
        requireWheelsApp(getCWD());
        error("DEPRECATED: CommandBox `wheels test:all` is frozen and does not fail-closed. Use the LuCLI `wheels` binary (`wheels test`). Removal scheduled for Wheels 5.0. See cli/src/README.md.");
        return;
    }
}