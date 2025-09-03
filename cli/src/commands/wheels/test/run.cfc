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
        boolean recurse = true,
        string reporter = "json",
        boolean verbose = true,
        string type = "app",
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
            servername = arguments.servername
        );
        
        // Build TestBox command parameters
        var params = {
            runner = testUrl
        };
        params.recurse = arguments.recurse;
        params.reporter = arguments.reporter;
        params.verbose = arguments.verbose;
        
        // Display test type
        print.greenBoldLine("================ #ucase(arguments.type)# Tests =======================").toConsole();
        
        // Advise we are running
        print.boldCyanLine("Executing tests, please wait...")
            .blinkingRed("Please wait...")
            .printLine()
            .toConsole();
        
        try {
            // Execute TestBox runner with parameters
            command("testbox run")
                .params(argumentCollection = params)
                .run();
                
        } catch (any e) {
            return error('Error executing tests: #CR# #e.message##CR##e.detail#');
        }
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
        
        // Build base URL based on type
        if (arguments.type == "app") {
            local.url = local.baseUrl & "?controller=wheels.public&action=testbox&view=runner&format=json&cli=true";
        } else if (arguments.type == "core") {
            local.url = local.baseUrl & "?controller=wheels.public&action=tests_testbox&view=runner&format=json&cli=true";
        } else {
            error("Invalid test type: #arguments.type# (expected app or core)");
        }
        
        return local.url;
    }
}