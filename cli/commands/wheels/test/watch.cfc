/**
 * Watch for file changes and automatically rerun tests
 * 
 * This is a wrapper for TestBox CLI watch mode.
 * Install TestBox CLI first: box install commandbox-testbox-cli
 * 
 * Examples:
 * wheels test:watch
 * wheels test:watch --directory=tests/unit
 * wheels test:watch --reporter=spec --delay=500
 */
component aliases='wheels test:watch' extends="../base" {
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @directory.hint Test directory to watch (default: tests)
     * @reporter.hint Test reporter format (simple, spec, junit, json, tap, min, doc)
     * @reporter.options simple,spec,junit,json,tap,min,doc
     * @verbose.hint Verbose output
     * @delay.hint Delay in milliseconds before rerunning tests (default: 1000)
     * @watchPaths.hint Additional paths to watch (comma-separated)
     * @excludePaths.hint Paths to exclude from watching (comma-separated) 
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test bundles to exclude
     * @filter.hint Test filter pattern
     */
    function run(
        string directory = "tests",
        string reporter = "simple",
        boolean verbose = false,
        numeric delay = 1000,
        string watchPaths = "",
        string excludePaths = "",
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = ""
    ) {
        detailOutput.header("👀", "Starting test watcher");
        
        // Check if TestBox CLI is installed
        if (!isTestBoxCLIInstalled()) {
            error("TestBox CLI is not installed. Please run: box install commandbox-testbox-cli");
            return;
        }
        
        print.yellowLine("Watching for file changes...");
        print.line("Press Ctrl+C to stop watching");
        print.line();
        
        // Build TestBox watch command
        var testboxCommand = "testbox watch";
        
        // Add directory
        testboxCommand &= " directory=#arguments.directory#";
        
        // Add reporter
        testboxCommand &= " reporter=#arguments.reporter#";
        
        // Add delay
        testboxCommand &= " delay=#arguments.delay#";
        
        // Add optional parameters
        if (arguments.verbose) {
            testboxCommand &= " verbose=true";
        }
        
        if (len(arguments.watchPaths)) {
            // Add additional paths to watch
            testboxCommand &= " paths=#arguments.watchPaths#";
        }
        
        if (len(arguments.excludePaths)) {
            testboxCommand &= " excludePaths=#arguments.excludePaths#";
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
        
        // Show watching details
        print.line("Test directory: #arguments.directory#");
        print.line("Reporter: #arguments.reporter#");
        print.line("Delay: #arguments.delay#ms");
        
        if (len(arguments.watchPaths)) {
            print.line("Additional watch paths: #arguments.watchPaths#");
        }
        
        if (len(arguments.excludePaths)) {
            print.line("Excluded paths: #arguments.excludePaths#");
        }
        
        print.line();
        print.line("Executing: #testboxCommand#");
        print.line();
        
        // Execute TestBox watch command
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