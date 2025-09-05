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
        string directory = "tests/specs",
        boolean recurse = true,
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        string servername = ""
    ) {
        arguments = reconstructArgs(arguments);
        
        // Validate we're in a Wheels project
        if (!isWheelsApp()) {
            error("This command must be run from the root of a Wheels application.");
        }
        
        // Build the test URL
        var testUrl = buildTestUrl(
            type = arguments.type,
            servername = arguments.servername,
            format = arguments.format
        );
        
        // Add coverage parameters if enabled
        if (arguments.coverage) {
            testUrl &= "&coverage=true";
            testUrl &= "&coverageBrowserOutputDir=#encodeForURL(arguments.coverageOutputDir)#";
            // Add coverage reporter format to URL
            testUrl &= "&coverageReporter=#encodeForURL(arguments.coverageReporter)#";
        }
        
        // Add fail-fast parameter if specified
        if (arguments.failFast) {
            testUrl &= "&bail=true";
        }
        
        // Build TestBox command parameters
        var params = {
            runner = testUrl,
            recurse = arguments.recurse,
            verbose = arguments.verbose
        };
        
        // Add directory parameter if specified
        if (len(arguments.directory)) {
            params.directory = arguments.directory;
        }
        
        // Add optional filtering parameters
        if (len(arguments.bundles)) {
            params.bundles = arguments.bundles;
        }
        
        if (len(arguments.labels)) {
            params.labels = arguments.labels;
        }
        
        if (len(arguments.excludes)) {
            params.excludes = arguments.excludes;
        }
        
        if (len(arguments.filter)) {
            // Handle filter parameter
            if (reFindNoCase("Test$", arguments.filter)) {
                params.testBundles = arguments.filter;
            } else {
                params.testSpecs = arguments.filter;
            }
        }
        
        try {
            // Execute TestBox command
            command('testbox run').params(argumentCollection=params).run();
        } catch (any e) {
            // Let TestBox handle its own output and errors
            if (!findNoCase("failing exit code", e.message)) {
                rethrow;
            }
        }
    }
}