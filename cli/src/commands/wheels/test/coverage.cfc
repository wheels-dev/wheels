/**
 * Generate code coverage reports for tests
 * 
 * This command runs tests with code coverage enabled using FusionReactor.
 * FusionReactor must be installed with code coverage enabled.
 * 
 * Examples:
 * wheels test:coverage
 * wheels test:coverage filter="User*" --verbose
 */
component aliases='wheels test:coverage' extends="../base" {
    
    /**
     * @type.hint Type of tests to run: (app, core, plugin)
     * @directory.hint Test directory to run (default: tests/specs)
     * @outputDir.hint Directory to output the report (relative to project root)
     * @threshold.hint Coverage percentage threshold (0-100)
     * @pathsToCapture.hint Paths to capture for coverage (default: /app)
     * @whitelist.hint Whitelist paths for coverage (default: *.cfc)
     * @blacklist.hint Blacklist paths from coverage (default: *Test.cfc,*Spec.cfc)
     * @bundles.hint Comma-delimited list of test bundles to run
     * @labels.hint Comma-delimited list of test labels to run
     * @excludes.hint Comma-delimited list of test labels to exclude
     * @filter.hint Test filter pattern
     * @verbose.hint Verbose output
     * @servername.hint Name of server to use
     * @outputFile.hint Base name for output files (default: test-results-coverage)
     */
    function run(
        string type = "app",
        string format = "txt",
        string directory = "tests/specs",
        string outputDir = "tests/results/coverage",
        numeric threshold = 0,
        string pathsToCapture = "/app",
        string whitelist = "*.cfc",
        string blacklist = "*Test.cfc,*Spec.cfc",
        string bundles = "",
        string labels = "",
        string excludes = "",
        string filter = "",
        boolean verbose = true,
        string servername = "",
        string outputFile = "test-results-coverage"
    ) {
		arguments = reconstructArgs(arguments);
        // Use relative path for outputDir to avoid issues with TestBox
        var outputPath = arguments.outputDir;
        
        // Create output directory if it doesn't exist (using relative path)
        var fullOutputPath = getCWD() & outputPath;
        if (!directoryExists(fullOutputPath)) {
            try {
                directoryCreate(fullOutputPath, true, true);
                print.line("Created output directory: #fullOutputPath#");
            } catch (any e) {
                print.redLine("Failed to create output directory: #e.message#");
                outputPath = "";  // Use current directory
            }
        }
        
        // Build the test URL with coverage parameters
        var testUrl = buildTestUrl(
            type = arguments.type,
            servername = arguments.servername,
            format = arguments.format
        );
        
        // Add coverage parameters to URL
        testUrl &= "&coverage=true";
        testUrl &= "&coveragePathToCapture=#encodeForURL(arguments.pathsToCapture)#";
        testUrl &= "&coverageWhitelist=#encodeForURL(arguments.whitelist)#";
        testUrl &= "&coverageBlacklist=#encodeForURL(arguments.blacklist)#";
        testUrl &= "&coverageBrowserOutputDir=#encodeForURL(outputPath)#";
        
        if (arguments.threshold > 0) {
            testUrl &= "&coverageThreshold=#arguments.threshold#";
        }
        
        // Build TestBox command parameters
        var params = {
            runner = testUrl,
            recurse = true,
            verbose = arguments.verbose
        };
        
        // Add test filtering parameters
        if (len(arguments.bundles)) {
            params.testbundles = arguments.bundles;
        }
        
        if (len(arguments.directory) && arguments.directory != "tests/specs") {
            params.directory = arguments.directory;
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
        
        // Use relative path for outputFile
        if (len(outputPath)) {
            params.outputFile = outputPath & "/" & arguments.outputFile;
        } else {
            params.outputFile = arguments.outputFile;
        }
        
        // Add JSON output format to get structured results
        params.outputFormats = "json,junit";
        
        
        var testsPassed = true;
        
        try {
            // Execute TestBox command
            command('testbox run').params(argumentCollection=params).run();
            
            print.line();
            print.greenLine("[SUCCESS] Tests completed successfully!");
            
        } catch (any e) {
			print.redLine("[ERROR] Test execution failed: #e.message#");
			testsPassed = false;
        }
        
    }
    
}