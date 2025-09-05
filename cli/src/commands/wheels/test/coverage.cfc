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
        // Header without icons for Windows compatibility
        print.line("========================================");
        print.boldLine("Running Tests with Code Coverage");
        print.line("========================================");
        print.line();
        
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
            params.bundles = arguments.bundles;
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
        
        print.line("========================================");
        print.boldGreenLine("Executing Tests with Coverage...");
        print.line("========================================");
        print.line();
        
        var testsPassed = true;
        var coverageEnabled = false;
        
        try {
            // Execute TestBox command
            command('testbox run').params(argumentCollection=params).run();
            
            print.line();
            print.greenLine("[SUCCESS] Tests completed successfully!");
            
        } catch (any e) {
            // Check if it's just test failures (not an actual error)
            if (findNoCase("failing exit code", e.message) || findNoCase("expectation failed", e.message)) {
                print.line();
                print.yellowLine("[WARNING] Tests completed with failures");
                print.yellowLine("Coverage data was still collected for executed tests");
                testsPassed = false;
            } else {
                print.line();
                print.redLine("[ERROR] Test execution failed: #e.message#");
                testsPassed = false;
            }
        }
        
        
        print.line();
        print.line("========================================");
        print.boldLine("Test Execution Complete");
        print.line("========================================");
        
        // Check for generated files
        print.line();
        print.boldLine("Output Files:");
        
        var filesGenerated = false;
        var jsonFile = getCWD() & params.outputFile & ".json";
        var junitFile = getCWD() & params.outputFile & "-junit.xml";

        // Check for JSON output
        if (fileExists(jsonFile)) {
            print.greenLine("  [OK] JSON Report: #jsonFile#");
            filesGenerated = true;
        } else {
            print.yellowLine("  [--] JSON Report not generated at: #jsonFile#");
        }
        
        if (fileExists(junitFile)) {
            print.greenLine("  [OK] JUnit Report: #junitFile#");
            filesGenerated = true;
        } else {
            print.yellowLine("  [--] JUnit Report not generated at: #junitFile#");
        }
        
        print.line();
        print.line("========================================");
        
        // Set exit code based on test results
        if (!testsPassed) {
            setExitCode(1);
        }
    }
    
}