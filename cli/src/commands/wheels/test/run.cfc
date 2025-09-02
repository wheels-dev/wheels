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
     * @bundles.hint Comma-separated list of test bundles to run
     * @directory.hint Directory of tests to run
     * @recurse.hint Recurse into subdirectories
     * @reporter.hint Test reporter format (simple, text, json, junit, tap, antjunit, console, doc, dot, min, raw)
     * @reportpath.hint Path to save test reports
     * @labels.hint Comma-separated list of test labels to include
     * @excludes.hint Comma-separated list of patterns to exclude
     * @coverage.hint Generate coverage report
     * @coverageSonarQubeXMLOutputPath.hint Path for SonarQube coverage XML
     * @coveragePathToCapture.hint Path to capture for coverage
     * @coverageWhitelist.hint Whitelist for coverage
     * @coverageBlacklist.hint Blacklist for coverage
     * @verbose.hint Verbose output
     * @type.hint Type of tests to run: app, core, or plugin
     * @type.options app,core,plugin
     * @servername.hint Name of server to use
     */
    function run(
        string type = "app",
        string format = "json",
        string bundles = "",
        string directory = "",
        boolean recurse = true,
        string reporter = "simple",
        string reportpath = "",
        string labels = "",
        string excludes = "",
        boolean coverage = false,
        string coverageSonarQubeXMLOutputPath = "",
        string coveragePathToCapture = "",
        string coverageWhitelist = "",
        string coverageBlacklist = "",
        boolean verbose = false,
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
        
        // Add optional TestBox parameters only if they have values
        if (len(arguments.bundles)) {
            params.bundles = arguments.bundles;
        }
        
        if (len(arguments.directory)) {
            params.directory = arguments.directory;
        }
        
        if (structKeyExists(arguments, "recurse")) {
            params.recurse = arguments.recurse;
        }
        
        if (len(arguments.reporter)) {
            params.reporter = arguments.reporter;
        }
        
        if (len(arguments.reportpath)) {
            params.reportpath = arguments.reportpath;
        }
        
        if (len(arguments.labels)) {
            params.labels = arguments.labels;
        }
        
        if (len(arguments.excludes)) {
            params.excludes = arguments.excludes;
        }
        
        if (arguments.coverage) {
            params.coverage = true;
            
            if (len(arguments.coverageSonarQubeXMLOutputPath)) {
                params.coverageSonarQubeXMLOutputPath = arguments.coverageSonarQubeXMLOutputPath;
            }
            
            if (len(arguments.coveragePathToCapture)) {
                params.coveragePathToCapture = arguments.coveragePathToCapture;
            }
            
            if (len(arguments.coverageWhitelist)) {
                params.coverageWhitelist = arguments.coverageWhitelist;
            }
            
            if (len(arguments.coverageBlacklist)) {
                params.coverageBlacklist = arguments.coverageBlacklist;
            }
        }
        
        if (arguments.verbose) {
            params.verbose = true;
        }
        
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
        string servername = "",
        string format = "json"
    ) {
        // Get actual server configuration
        local.serverConfig = getServerConfig(arguments.servername);
        local.baseUrl = "http://#local.serverConfig.host#:#local.serverConfig.port#/";
        
        // Build base URL based on type
        if (arguments.type == "app") {
            local.url = local.baseUrl & "?controller=wheels.public&action=testbox&view=runner&cli=true&format=#arguments.format#";
        } else if (arguments.type == "core") {
            local.url = local.baseUrl & "?controller=wheels.public&action=tests_testbox&view=runner&cli=true&format=#arguments.format#";
        } else {
            local.url = local.baseUrl & "?controller=tests&action=runner&view=runner&type=#arguments.type#&cli=true&format=#arguments.format#";
        }
        
        return local.url;
    }
}