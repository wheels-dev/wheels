/**
 * Run all tests with TestBox CLI
 * 
 * This is a wrapper for the TestBox CLI 'testbox run' command.
 * Install TestBox CLI first: box install commandbox-testbox-cli
 * 
 * Examples:
 * wheels test:all
 * wheels test:all --reporter=junit
 * wheels test:all --coverage --coverageReporter=html
 */
component aliases='wheels test:all' extends="../base" {
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @reporter.hint Test reporter format (simple, spec, junit, json, tap, min, doc)
     * @reporter.options simple,spec,junit,json,tap,min,doc
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
     * @excludes.hint Comma-delimited list of test bundles to exclude
     * @filter.hint Test filter pattern
     */
    function run(
        string reporter = "simple",
        boolean coverage = false,
        string coverageReporter = "html", 
        string coverageOutputDir = "tests/results/coverage",
        boolean verbose = false,
        boolean failFast = false,
        string directory = "tests",
        boolean recurse = true,
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = ""
    ) {
        detailOutput.header("🧪", "Running all tests with TestBox");
        
        // Check if TestBox CLI is installed
        if (!isTestBoxCLIInstalled()) {
            error("TestBox CLI is not installed. Please run: box install commandbox-testbox-cli");
            return;
        }
        
        // Build TestBox command
        var testboxCommand = "testbox run";
        
        // Add directory
        testboxCommand &= " directory=#arguments.directory#";
        
        // Add reporter
        testboxCommand &= " reporter=#arguments.reporter#";
        
        // Add optional parameters
        if (arguments.recurse) {
            testboxCommand &= " recurse=true";
        }
        
        if (len(arguments.bundles)) {
            testboxCommand &= " bundles=#arguments.bundles#";
        }
        
        if (len(arguments.labels)) {
            testboxCommand &= " labels=#arguments.labels#";
        }
        
        if (len(arguments.excludes)) {
            testboxCommand &= " excludes=#arguments.excludes#";
        }
        
        if (len(arguments.filter)) {
            testboxCommand &= " filter=#arguments.filter#";
        }
        
        if (arguments.verbose) {
            testboxCommand &= " verbose=true";
        }
        
        if (arguments.failFast) {
            testboxCommand &= " failfast=true";
        }
        
        // Add coverage options
        if (arguments.coverage) {
            testboxCommand &= " coverage=true";
            testboxCommand &= " coverageReporter=#arguments.coverageReporter#";
            testboxCommand &= " coverageOutputDir=#arguments.coverageOutputDir#";
        }
        
        // Execute TestBox command
        print.line("Executing: #testboxCommand#");
        print.line();
        
        command(testboxCommand).run();
    }
    
    /**
     * Check if TestBox CLI is installed
     */
    private boolean function isTestBoxCLIInstalled() {
        try {
            // Try to run testbox help command
            var result = command("testbox help").run(returnOutput=true);
            return true;
        } catch (any e) {
            return false;
        }
    }
}