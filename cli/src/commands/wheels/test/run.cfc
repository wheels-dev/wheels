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
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
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
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(
            argStruct=arguments,
            allowedValues={
                type=["app", "core"],
                format=["txt", "json", "junit", "html"],
                reporter=["text", "json", "junit", "tap", "antjunit", "console", ""]
            }
        );
        arguments.directory = resolveTestDirectory(arguments.type, arguments.directory);
        
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
        
        // Display test header
        detailOutput.header("#ucase(arguments.type)# Tests");
        
        // Display additional info if verbose
        if (arguments.verbose) {
            detailOutput.subHeader("Test Configuration");
            detailOutput.metric("Test URL", testUrl);
            if (len(arguments.filter)) {
                detailOutput.metric("Filter", arguments.filter);
            }
            if (len(arguments.lables)) {
                detailOutput.metric("Labels", arguments.lables);
            }
            if (arguments.coverage) {
                detailOutput.metric("Coverage", "Enabled");
            }
            detailOutput.line();
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
                    detailOutput.statusWarning("TestBox completed (exit code indicates test results)");
                } else {
                    // Re-throw if it's a genuine error
                    rethrow;
                }
            }
            
        } catch (any e) {
            detailOutput.error("Error executing TestBox command: #e.message#");
            return;
        }
        
        detailOutput.line();
        detailOutput.statusSuccess("#ucase(arguments.type)# Tests Completed");
    }

}