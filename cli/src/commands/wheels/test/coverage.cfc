/**
 * Generate code coverage reports for tests
 * 
 * This is a wrapper for TestBox CLI with coverage enabled.
 * Install TestBox CLI first: box install commandbox-testbox-cli
 * 
 * Examples:
 * wheels test:coverage
 * wheels test:coverage --reporter=html
 * wheels test:coverage --directory=tests/unit --threshold=80
 */
component aliases='wheels test:coverage' extends="../base" {
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @directory.hint Test directory to run (default: tests)
     * @reporter.hint Coverage reporter format (html, json, xml, simple)
     * @reporter.options html,json,xml,simple
     * @outputDir.hint Directory to output the coverage report (default: tests/results/coverage)
     * @threshold.hint Coverage percentage threshold (0-100)
     * @pathsToCapture.hint Paths to capture for coverage (comma-separated)
     * @whitelist.hint Whitelist paths for coverage (comma-separated)
     * @blacklist.hint Blacklist paths from coverage (comma-separated)
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test bundles to exclude
     * @filter.hint Test filter pattern
     * @verbose.hint Verbose output
     */
    function run(
        string directory = "tests",
        string reporter = "html",
        string outputDir = "tests/results/coverage",
        numeric threshold = 0,
        string pathsToCapture = "",
        string whitelist = "",
        string blacklist = "",
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        boolean verbose = false
    ) {
        detailOutput.header("📊", "Running tests with code coverage");
        
        // Check if TestBox CLI is installed
        if (!isTestBoxCLIInstalled()) {
            error("TestBox CLI is not installed. Please run: box install commandbox-testbox-cli");
            return;
        }
        
        // Ensure output directory exists
        var outputPath = fileSystemUtil.resolvePath(arguments.outputDir);
        if (!directoryExists(outputPath)) {
            directoryCreate(outputPath, true);
        }
        
        // Build TestBox command parameters
        var params = {
            directory = arguments.directory,
            coverage = true,
            coverageReporter = arguments.reporter,
            coverageOutputDir = arguments.outputDir
        };
        
        // Add optional coverage parameters
        if (arguments.threshold > 0) {
            params.coverageThreshold = arguments.threshold;
        }
        
        if (len(arguments.pathsToCapture)) {
            params.coveragePathToCapture = arguments.pathsToCapture;
        }
        
        if (len(arguments.whitelist)) {
            params.coverageWhitelist = arguments.whitelist;
        }
        
        if (len(arguments.blacklist)) {
            params.coverageBlacklist = arguments.blacklist;
        }
        
        // Add test filtering parameters
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
            params.filter = arguments.filter;
        }
        
        if (arguments.verbose) {
            params.verbose = true;
        }
        
        // Show coverage details
        print.line("Coverage reporter: #arguments.reporter#");
        print.line("Output directory: #arguments.outputDir#");
        
        if (arguments.threshold > 0) {
            print.line("Coverage threshold: #arguments.threshold#%");
        }
        
        print.line();
        print.line("Executing: testbox run with coverage enabled");
        print.line();
        
        // Execute TestBox command
        command('testbox run').params(argumentCollection=params).run();
        
        // Show where to find the coverage report
        print.line();
        print.greenLine("Coverage report generated!");
        
        if (arguments.reporter == "html") {
            var reportPath = outputPath & "/index.html";
            print.line("View the HTML report at: #reportPath#");
            
            // Try to open in browser
            if (fileExists(reportPath)) {
                print.line();
                print.yellowLine("Opening coverage report in browser...");
                command("open #reportPath#").run();
            }
        } else {
            print.line("Coverage report saved to: #outputPath#");
        }
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