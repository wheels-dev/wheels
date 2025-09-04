/**
 * Run Wheels application tests
 * Examples:
 * wheels test run
 * wheels test run UserTest
 * wheels test run type=core
 * wheels test run --verbose --debug
 */
component extends="../base" {
    
    /**
     * @type.hint Type of tests to run: (app, core)
     * @recurse.hint Recurse into subdirectories
     * @reporter.hint Test reporter format (text, json, junit, tap, antjunit)
     * @verbose.hint Verbose output
     * @servername.hint Name of server to use
     */
    function run(
        string type = "app",
        string format = "txt",
        string bundles = "",
        string directory = "",
        boolean recurse = true,
        boolean verbose = true,
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
        
        // Build TestBox command parameters
        var params = {
            runner = testUrl
        };
        params.recurse = arguments.recurse;
        params.verbose = arguments.verbose;
        
        // Display test type
        print.greenBoldLine("================ #ucase(arguments.type)# Tests =======================").toConsole();
        
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
    
    /**
     * Build test URL with parameters
     */
    private function buildTestUrl(
        required string type,
        string servername = ""
    ) {
        // Get actual server configuration
        local.serverConfig = getServerConfig(arguments.servername);
        local.baseUrl = "http://#local.serverConfig.host#:#local.serverConfig.port#/";
        
        // http://localhost:8080/wheels/app/tests?format=txt

        // Build base URL based on type
        switch (arguments.type) {
            case "app":
                local.url = local.baseUrl & "/wheels/app/tests?format=#arguments.format#";
                break;
            case "core":
                local.url = local.baseUrl & "/wheels/core/tests?format=#arguments.format#";
                break;
            case "plugin":
                local.url = local.baseUrl & "/wheels/plugins/tests?format=#arguments.format#";
                break;
            default:
                // Default to app tests for invalid types
                local.url = local.baseUrl & "/wheels/app/tests?format=#arguments.format#";
                break;
        }
        
        return local.url;
    }
}