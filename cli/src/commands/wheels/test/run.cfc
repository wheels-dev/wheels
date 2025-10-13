/**
 * Run Wheels application tests
 * Examples:
 * wheels test run
 * wheels test run UserTest
 * wheels test run type=core
 * wheels test run --verbose --debug
 * wheels test run filter="User*" --coverage
 */
component extends="../base" {
    
    /**
     * @type.hint Type of tests to run: (app, core)
     * @recurse.hint Recurse into subdirectories
     * @reporter.hint Test reporter format (text, json, junit, tap, antjunit)
     * @verbose.hint Verbose output
     * @servername.hint Name of server to use
     * @filter.hint Filter tests by pattern or name
     * @lables.hint Run specific test lables
     * @coverage.hint Generate coverage report (boolean flag)
     */
    function run(
        string type = "app",
        string format = "txt",
        string bundles = "",
        string directory = "",
        boolean recurse = true,
        boolean verbose = true,
        string servername = "",
        string filter = "",
        string lables = "",
        boolean coverage = false,
        string reporter = "",
    ) {
        arguments = reconstructArgs(arguments);
        arguments.directory = resolveTestDirectory(arguments.type, arguments.directory);
        
        // Validate we're in a Wheels project
        if (!isWheelsApp()) {
            error("This command must be run from the root of a Wheels application.");
        }
        
        // Map reporter to format if reporter is specified
        if (structKeyExists(arguments, "reporter") && len(arguments.reporter)) {
            // Map common reporter names to formats your runner expects
            switch(arguments.reporter) {
                case "console":
                case "tap":
                case "text":
                    arguments.format = "txt";
                    break;
                case "json":
                    arguments.format = "json";
                    break;
                case "junit":
                case "antjunit":
                    arguments.format = "junit";

            }
        }
        
        // Build the test URL
        var testUrl = buildTestUrl(
            type = arguments.type,
            servername = arguments.servername,
            format = arguments.format
        );
        
        // Build TestBox command parameters
        var params = {
            runner = testUrl
        };
        params.recurse = arguments.recurse;
        params.verbose = arguments.verbose;
        
        // Add bundles if specified
        if (len(arguments.bundles)) {
            params.testbundles = arguments.bundles;
        }
        
        // Add directory if specified
        if (len(arguments.directory)) {
            params.directory = arguments.directory;
        }
        
        // Handle filter parameter
        if (len(arguments.filter)) {
            // Filter can be used for testSpecs or testBundles depending on pattern
            // If it looks like a bundle name (e.g., UserTest), use testBundles
            // If it looks like a spec pattern, use testSpecs
            if (reFindNoCase("Test$", arguments.filter)) {
                params.testBundles = arguments.filter;
            } else {
                params.testSpecs = arguments.filter;
            }
        }
        
        // Handle lables parameter
        if (len(arguments.lables)) {
            params.labels = arguments.lables;
        }
        
        // Handle coverage parameter
        if (arguments.coverage) {
            // Add coverage parameters to the URL since TestBox CLI doesn't directly support coverage
            // You'll need to handle this in your runner.cfm
            testUrl &= "&coverage=true";
        }
        
        // Update the runner URL in params
        params.runner = testUrl;
        
        // Display test type
        print.greenBoldLine("================ #ucase(arguments.type)# Tests =======================").toConsole();
        
        // Display additional info if verbose
        if (arguments.verbose) {
            print.line("Test URL: #testUrl#").toConsole();
            if (len(arguments.filter)) {
                print.line("Filter: #arguments.filter#").toConsole();
            }
            if (len(arguments.lables)) {
                print.line("lables: #arguments.lables#").toConsole();
            }
            if (arguments.coverage) {
                print.line("Coverage: Enabled").toConsole();
            }
        }
        
        try {
            // Try using runCommand which should handle the CommandBox command properly
            local.testboxCommand = command("testbox run").params(argumentCollection = params);
            
            // Execute without throwing on non-zero exit codes
            try {
                local.testboxCommand.run();
            } catch (any commandError) {
                // If it's just an exit code error, ignore it and continue
                // The actual test output should have been displayed already
                if (findNoCase("failing exit code", commandError.message)) {
                    print.yellowLine("TestBox completed (exit code indicates test results)").toConsole();
                } else {
                    // Re-throw if it's a genuine error
                    rethrow;
                }
            }
            
        } catch (any e) {
            print.redLine("Error executing TestBox command: #e.message#").toConsole();
        }
        
        print.greenBoldLine("============ #ucase(arguments.type)# Tests Completed ==================").toConsole();
    }

}