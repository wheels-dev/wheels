/**
 * Generate code coverage reports for tests
 * 
 * {code:bash}
 * wheels test:coverage
 * wheels test:coverage app
 * wheels test:coverage core
 * wheels test:coverage plugin
 * {code}
 */
component extends="../base" {

    /**
     * @type Type of tests to run (app, core, or plugin)
     * @servername Name of server to reload (defaults to current)
     * @reload Force a reload of wheels
     * @debug Show debug info
     * @outputDir Directory to output the coverage report (defaults to tests/coverageReport/)
     */
    function run(
        string type="app", 
        string servername="", 
        boolean reload=false, 
        boolean debug=false,
        string outputDir="tests/coverageReport"
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Test Coverage");
        print.line();
        
        // Set target directory for report
        local.outputPath = fileSystemUtil.resolvePath(arguments.outputDir);
        
        // Ensure output directory exists
        if (!directoryExists(local.outputPath)) {
            directoryCreate(local.outputPath);
        }
        
        // Create URL parameters
        local.urlParams = "&type=#arguments.type#&coverage=true&coverageOutputDir=#urlEncodedFormat(local.outputPath)#";
        
        if (arguments.debug) {
            local.urlParams &= "&debug=true";
        }
        
        if (arguments.reload) {
            local.urlParams &= "&reload=true";
        }
        
        // Send command to TestBox
        print.line("Running #arguments.type# tests with coverage reporting...");
        print.line();
        
        // Call the test command with coverage parameters
        local.result = $sendToCliCommand(urlstring="&command=test#local.urlParams#");
        
        // Output results
        if (structKeyExists(local.result, "coverage")) {
            print.boldGreenLine("Coverage Results:");
            print.yellowLine("Total Coverage: #local.result.coverage.totalCoverage#%");
            print.yellowLine("Files Analyzed: #local.result.coverage.totalFiles#");
            print.yellowLine("Coverage Report: #local.outputPath#");
        } else {
            print.boldRedLine("Coverage results not available. Make sure TestBox is properly configured for coverage reporting.");
        }
        
        print.line();
    }
}